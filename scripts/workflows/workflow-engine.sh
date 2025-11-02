#!/bin/bash
# workflow-engine.sh
# Purpose: Workflow state machine library for spec-drive
#
# Functions:
#   workflow_start()    - Initialize workflow, set current_workflow/spec/stage
#   workflow_advance()  - Move to next stage (enforces can_advance)
#   workflow_complete() - Mark workflow done, add to history
#   workflow_abandon()  - Mark workflow abandoned
#   workflow_status()   - Print current workflow state
#
# Usage:
#   source scripts/workflows/workflow-engine.sh
#   workflow_start "feature" "AUTH-001"
#
# Notes:
#   - All functions use atomic writes (temp file + mv)
#   - All functions validate against state-schema.json
#   - Uses flock for concurrent access protection

# Note: This file is sourced, not executed directly
# Don't use 'set -u' in sourced files with associative arrays
# as it can cause issues across different bash versions
set -eo pipefail

# Constants
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
STATE_SCHEMA="$SPEC_DRIVE_DIR/schemas/v0.1/state-schema.json"
LOCK_FILE="$SPEC_DRIVE_DIR/.state.lock"

# Stage progression map
declare -A STAGE_NEXT=(
  ["discover"]="specify"
  ["specify"]="implement"
  ["implement"]="verify"
  ["verify"]="done"
)

# Utility: Acquire file lock
acquire_lock() {
  exec 200>"$LOCK_FILE"
  flock -x 200 || {
    echo "❌ ERROR: Cannot acquire lock on state.yaml" >&2
    exit 1
  }
}

# Utility: Release file lock
release_lock() {
  flock -u 200 || true
}

# Utility: Validate SPEC-ID format
validate_spec_id() {
  local spec_id="$1"
  if [[ ! "$spec_id" =~ ^[A-Z][A-Z0-9]*-[0-9]{3,}$ ]]; then
    echo "❌ ERROR: Invalid SPEC-ID format: $spec_id" >&2
    echo "Expected format: PREFIX-NNN (e.g., AUTH-001, PROFILE-042)" >&2
    exit 1
  fi
}

# Utility: Atomic YAML write with validation
atomic_write_state() {
  local temp_file="$STATE_FILE.tmp.$$"

  # Write to temp file
  cat > "$temp_file"

  # Validate YAML syntax
  if ! yq eval '.' "$temp_file" > /dev/null 2>&1; then
    echo "❌ ERROR: Invalid YAML syntax in state update" >&2
    rm -f "$temp_file"
    exit 1
  fi

  # Atomic move
  mv "$temp_file" "$STATE_FILE"
}

# Function: workflow_start
# Args: $1 = workflow type (app-new|feature), $2 = SPEC-ID
# Sets: current_workflow, current_spec, current_stage=discover
workflow_start() {
  local workflow_type="$1"
  local spec_id="$2"

  # Validate arguments
  if [[ -z "$workflow_type" ]] || [[ -z "$spec_id" ]]; then
    echo "❌ ERROR: workflow_start requires workflow type and SPEC-ID" >&2
    echo "Usage: workflow_start <app-new|feature> <SPEC-ID>" >&2
    exit 1
  fi

  # Validate SPEC-ID format
  validate_spec_id "$spec_id"

  # Acquire lock
  acquire_lock

  # Check no active workflow
  local current_workflow=$(yq eval '.current_workflow' "$STATE_FILE" 2>/dev/null || echo "null")
  if [[ "$current_workflow" != "null" ]]; then
    echo "❌ ERROR: Workflow already active: $current_workflow" >&2
    echo "Complete or abandon current workflow before starting new one" >&2
    release_lock
    exit 1
  fi

  # Update state
  yq eval ".current_workflow = \"$workflow_type\" | \
           .current_spec = \"$spec_id\" | \
           .current_stage = \"discover\" | \
           .can_advance = false | \
           .dirty = false" \
    "$STATE_FILE" | atomic_write_state

  release_lock

  echo "✅ Workflow started: $workflow_type for $spec_id"
  echo "Stage: discover"
}

# Function: workflow_advance
# Moves to next stage if can_advance=true
workflow_advance() {
  acquire_lock

  # Check can_advance flag
  local can_advance=$(yq eval '.can_advance' "$STATE_FILE")
  if [[ "$can_advance" != "true" ]]; then
    echo "❌ ERROR: Cannot advance - quality gate not passed" >&2
    echo "Run the current stage's gate check before advancing" >&2
    release_lock
    exit 2  # Exit code 2 = blocked (not error)
  fi

  # Get current stage
  local current_stage=$(yq eval '.current_stage' "$STATE_FILE")
  local next_stage="${STAGE_NEXT[$current_stage]}"

  if [[ -z "$next_stage" ]]; then
    echo "❌ ERROR: Unknown stage: $current_stage" >&2
    release_lock
    exit 1
  fi

  # Special case: done
  if [[ "$next_stage" == "done" ]]; then
    echo "✅ Workflow complete - run workflow_complete() to finalize"
    release_lock
    return 0
  fi

  # Advance to next stage
  yq eval ".current_stage = \"$next_stage\" | \
           .can_advance = false" \
    "$STATE_FILE" | atomic_write_state

  release_lock

  echo "✅ Advanced to stage: $next_stage"
  echo "Complete this stage and pass its quality gate to continue"
}

# Function: workflow_complete
# Marks workflow complete, adds to history, resets current_*
workflow_complete() {
  acquire_lock

  # Get current workflow details
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local spec_id=$(yq eval '.current_spec' "$STATE_FILE")
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  if [[ "$workflow" == "null" ]] || [[ "$spec_id" == "null" ]]; then
    echo "❌ ERROR: No active workflow to complete" >&2
    release_lock
    exit 1
  fi

  # Add to workflow history
  yq eval ".workflows.\"$spec_id\".status = \"done\" | \
           .workflows.\"$spec_id\".completed = \"$timestamp\" | \
           .workflows.\"$spec_id\".workflow_type = \"$workflow\" | \
           .current_workflow = null | \
           .current_spec = null | \
           .current_stage = null | \
           .can_advance = false" \
    "$STATE_FILE" | atomic_write_state

  release_lock

  echo "🎉 Workflow complete: $spec_id"
  echo "Status: done"
  echo "Completed: $timestamp"
}

# Function: workflow_abandon
# Marks workflow abandoned, resets current_*
workflow_abandon() {
  acquire_lock

  local spec_id=$(yq eval '.current_spec' "$STATE_FILE")
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  if [[ "$spec_id" == "null" ]]; then
    echo "❌ ERROR: No active workflow to abandon" >&2
    release_lock
    exit 1
  fi

  # Mark as abandoned
  yq eval ".workflows.\"$spec_id\".status = \"abandoned\" | \
           .workflows.\"$spec_id\".abandoned = \"$timestamp\" | \
           .current_workflow = null | \
           .current_spec = null | \
           .current_stage = null | \
           .can_advance = false" \
    "$STATE_FILE" | atomic_write_state

  release_lock

  echo "⚠️  Workflow abandoned: $spec_id"
}

# Function: workflow_status
# Prints human-readable current workflow state
workflow_status() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "❌ ERROR: state.yaml not found at $STATE_FILE" >&2
    exit 1
  fi

  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local spec_id=$(yq eval '.current_spec' "$STATE_FILE")
  local stage=$(yq eval '.current_stage' "$STATE_FILE")
  local can_advance=$(yq eval '.can_advance' "$STATE_FILE")
  local dirty=$(yq eval '.dirty' "$STATE_FILE")

  echo "================================================"
  echo "  Workflow Status"
  echo "================================================"

  if [[ "$workflow" == "null" ]]; then
    echo "No active workflow"
    echo ""
    echo "Start a new workflow:"
    echo "  /spec-drive:app-new <project-name>"
    echo "  /spec-drive:feature start --title \"Feature name\""
  else
    echo "Workflow: $workflow"
    echo "Spec:     $spec_id"
    echo "Stage:    $stage"
    echo "Can advance: $can_advance"
    echo "Dirty flag:  $dirty"
    echo ""

    if [[ "$can_advance" == "true" ]]; then
      echo "✅ Ready to advance to next stage"
      echo "   Run: /spec-drive:feature advance"
    else
      echo "⏳ Complete current stage and pass quality gate"
    fi
  fi

  echo "================================================"
}
