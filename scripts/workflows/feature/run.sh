#!/bin/bash
# run.sh
# Purpose: Orchestrate feature development workflow (4-stage process)
# Usage: ./run.sh [start|advance|status] [args...]

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"

# Check dependencies
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ -x "$PLUGIN_ROOT/scripts/check-dependencies.sh" ]]; then
  "$PLUGIN_ROOT/scripts/check-dependencies.sh" || exit 1
fi

# Source workflow engine
source "$SCRIPT_DIR/../workflow-engine.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Usage
usage() {
  cat << EOF
Usage: $0 <command> [options]

Commands:
  start <title>    Start new feature workflow
  advance          Advance to next stage
  status           Show current workflow status

Examples:
  $0 start "User authentication"
  $0 advance
  $0 status
EOF
  exit 0
}

# Parse command
COMMAND="${1:-}"

if [[ -z "$COMMAND" ]] || [[ "$COMMAND" == "--help" ]]; then
  usage
fi

shift || true

# ==============================================================================
# Command: status
# ==============================================================================

if [[ "$COMMAND" == "status" ]]; then
  workflow_status
  exit 0
fi

# ==============================================================================
# Command: advance
# ==============================================================================

if [[ "$COMMAND" == "advance" ]]; then
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}  Advancing Workflow${NC}"
  echo -e "${BLUE}================================================${NC}"
  echo ""

  # Check active workflow
  acquire_lock
  current_workflow=$(yq eval '.current_workflow' "$STATE_FILE" 2>/dev/null || echo "null")
  current_stage=$(yq eval '.current_stage' "$STATE_FILE" 2>/dev/null || echo "null")
  can_advance=$(yq eval '.can_advance' "$STATE_FILE" 2>/dev/null || echo "false")
  release_lock

  if [[ "$current_workflow" == "null" ]]; then
    echo -e "${RED}❌ ERROR: No active workflow${NC}" >&2
    echo "Start a workflow with: /spec-drive:feature start <title>" >&2
    exit 1
  fi

  if [[ "$current_workflow" != "feature" ]]; then
    echo -e "${RED}❌ ERROR: Active workflow is not 'feature': $current_workflow${NC}" >&2
    echo "Complete or abandon current workflow first" >&2
    exit 1
  fi

  # Attempt to advance
  echo "Current stage: $current_stage"
  echo "Can advance: $can_advance"
  echo ""

  # Advance the workflow state
  if ! workflow_advance 2>&1; then
    exit $?
  fi

  # Get new stage
  acquire_lock
  new_stage=$(yq eval '.current_stage' "$STATE_FILE")
  release_lock

  echo ""
  echo -e "${GREEN}✓${NC} Advanced to: $new_stage"
  echo ""

  # Run the appropriate stage script
  case "$new_stage" in
    specify)
      "$SCRIPT_DIR/specify.sh"
      ;;
    implement)
      "$SCRIPT_DIR/implement.sh"
      ;;
    verify)
      "$SCRIPT_DIR/verify.sh"
      ;;
    done)
      echo -e "${GREEN}🎉 Workflow complete!${NC}"
      echo "All stages finished."
      ;;
    *)
      echo -e "${YELLOW}⚠${NC}  Unknown stage: $new_stage"
      ;;
  esac

  exit 0
fi

# ==============================================================================
# Command: start
# ==============================================================================

if [[ "$COMMAND" == "start" ]]; then
  # Parse title (positional) and optional flags
  FEATURE_TITLE="${1:-}"
  shift || true

  DESCRIPTION=""
  PRIORITY="medium"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --description)
        DESCRIPTION="$2"
        shift 2
        ;;
      --priority)
        PRIORITY="$2"
        shift 2
        ;;
      *)
        echo -e "${RED}❌ ERROR: Unknown argument for start: $1${NC}" >&2
        echo "Usage: $0 start <title> [--description <desc>] [--priority <low|medium|high|critical>]" >&2
        exit 1
        ;;
    esac
  done

  if [[ -z "$FEATURE_TITLE" ]]; then
    echo -e "${RED}❌ ERROR: Feature title is required${NC}" >&2
    echo "Usage: $0 start <title> [--description <desc>] [--priority <low|medium|high|critical>]" >&2
    exit 1
  fi

  # Validate priority
  if [[ ! "$PRIORITY" =~ ^(low|medium|high|critical)$ ]]; then
    echo -e "${YELLOW}⚠${NC}  Invalid priority '$PRIORITY', using 'medium'" >&2
    PRIORITY="medium"
  fi

  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}  Starting Feature Workflow${NC}"
  echo -e "${BLUE}================================================${NC}"
  echo ""

  # Check no active workflow
  acquire_lock
  current_workflow=$(yq eval '.current_workflow' "$STATE_FILE" 2>/dev/null || echo "null")
  if [[ "$current_workflow" != "null" ]]; then
    echo -e "${RED}❌ ERROR: Active workflow exists: $current_workflow${NC}" >&2
    echo "Complete or abandon current workflow before starting new one" >&2
    release_lock
    exit 1
  fi
  release_lock

  # Run discover stage to create spec
  echo -e "${BLUE}Stage 1/4: Discover${NC}"
  echo "Creating feature specification..."
  echo ""

  # Pass all data to discover.sh
  DISCOVER_ARGS=("$FEATURE_TITLE" "--priority" "$PRIORITY")
  if [[ -n "$DESCRIPTION" ]]; then
    DISCOVER_ARGS+=("--description" "$DESCRIPTION")
  fi

  if ! "$SCRIPT_DIR/discover.sh" "${DISCOVER_ARGS[@]}"; then
    echo -e "${RED}❌ ERROR: Discover stage failed${NC}" >&2
    exit 1
  fi

  echo ""
  echo -e "${GREEN}✓${NC} Discover stage complete"
  echo ""

  # Get generated SPEC-ID from state
  acquire_lock
  SPEC_ID=$(yq eval '.current_spec' "$STATE_FILE")
  release_lock

  echo -e "${GREEN}================================================${NC}"
  echo -e "${GREEN}  Feature Workflow Started!${NC}"
  echo -e "${GREEN}================================================${NC}"
  echo ""
  echo "Spec ID: $SPEC_ID"
  echo "Stage: discover"
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "  1. Review spec: .spec-drive/specs/$SPEC_ID.yaml"
  echo "  2. Add acceptance criteria to the spec"
  echo "  3. When ready: /spec-drive:feature advance"
  echo ""

  exit 0
fi

# Unknown command
echo -e "${RED}❌ ERROR: Unknown command: $COMMAND${NC}" >&2
usage
