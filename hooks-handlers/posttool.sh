#!/usr/bin/env bash
# posttool.sh
# PostToolUse hook for spec-drive plugin
# Sets dirty flag when code/docs are modified

# NOTE: Don't use ANY error flags in hooks - we must always return success to avoid crashing Claude Code
# NO set -e, NO set -o pipefail - hooks must be bulletproof

# Hook receives tool information via environment variables:
# - TOOL_NAME: Name of the tool that was used (Write, Edit, Delete, etc.)
# - TOOL_OUTPUT: Output from the tool
# - TOOL_ERROR: Error from the tool (if any)

# Constants
SPEC_DRIVE_DIR=".spec-drive"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
LOCK_FILE="$SPEC_DRIVE_DIR/.state.lock"

# Utility: Acquire lock with short timeout for hooks
# Returns 0 on success, 1 on failure (caller should handle gracefully)
acquire_lock() {
  local max_wait=2  # Short timeout for hooks (total hook timeout is 5s)
  local waited=0

  while ! mkdir "$LOCK_FILE" 2>/dev/null; do
    if [[ $waited -ge $max_wait ]]; then
      # Lock acquisition failed - return failure but don't crash
      return 1
    fi
    sleep 0.1
    waited=$((waited + 1))
  done

  # Store PID for debugging
  echo $$ > "$LOCK_FILE/pid" 2>/dev/null || true
  return 0
}

# Utility: Release lock
release_lock() {
  rm -rf "$LOCK_FILE" 2>/dev/null || true
}

# Ensure lock is always released on exit
trap release_lock EXIT

# Only proceed if we're in a project with spec-drive initialized
if [[ ! -d "$SPEC_DRIVE_DIR" ]]; then
  # Not a spec-drive project, skip silently
  cat << 'EOF'
{
  "hookEventName": "PostToolUse"
}
EOF
  exit 0
fi

# Check if state.yaml exists, create if missing
if [[ ! -f "$STATE_FILE" ]]; then
  # Try to acquire lock (short timeout)
  if acquire_lock; then
    # Create full state schema matching workflow-engine.sh expectations
    mkdir -p "$SPEC_DRIVE_DIR"
    cat > "$STATE_FILE" << 'YAML'
current_workflow: null
current_stage: null
current_spec: null
can_advance: false
dirty: false
workflows: {}
YAML
    release_lock
  else
    # Lock acquisition failed - skip state creation, return success
    cat << 'EOF'
{
  "hookEventName": "PostToolUse"
}
EOF
    exit 0
  fi
fi

# Set dirty flag for Write/Edit/Delete tools
if [[ "$TOOL_NAME" =~ ^(Write|Edit|Delete)$ ]]; then
  # Try to acquire lock
  if acquire_lock; then
    # Use yq to set dirty flag
    if command -v yq &>/dev/null; then
      yq eval '.dirty = true' -i "$STATE_FILE" 2>/dev/null || true
    else
      # Fallback: simple sed replacement if yq not available
      sed -i.bak 's/^dirty: .*/dirty: true/' "$STATE_FILE" 2>/dev/null || true
      rm -f "$STATE_FILE.bak" 2>/dev/null || true
    fi
    release_lock
  fi
  # If lock acquisition fails, skip silently - don't crash Claude Code
fi

# Always return success
cat << 'EOF'
{
  "hookEventName": "PostToolUse"
}
EOF
