#!/bin/bash
# posttool.sh
# PostToolUse hook for spec-drive plugin
# Sets dirty flag when code/docs are modified

set -eo pipefail

# Hook receives tool information via environment variables:
# - TOOL_NAME: Name of the tool that was used (Write, Edit, Delete, etc.)
# - TOOL_OUTPUT: Output from the tool
# - TOOL_ERROR: Error from the tool (if any)

# Only proceed if we're in a project with spec-drive initialized
if [[ ! -d ".spec-drive" ]]; then
  # Not a spec-drive project, skip silently
  cat << 'EOF'
{
  "hookEventName": "PostToolUse"
}
EOF
  exit 0
fi

# Check if state.yaml exists, create if missing
STATE_FILE=".spec-drive/state.yaml"
if [[ ! -f "$STATE_FILE" ]]; then
  # Create minimal state file
  mkdir -p .spec-drive
  cat > "$STATE_FILE" << 'YAML'
dirty: false
last_update: null
YAML
fi

# Set dirty flag for Write/Edit/Delete tools
if [[ "$TOOL_NAME" =~ ^(Write|Edit|Delete)$ ]]; then
  # Use yq to set dirty flag
  if command -v yq &>/dev/null; then
    yq eval '.dirty = true | .last_update = now' -i "$STATE_FILE" 2>/dev/null || {
      # Fallback: simple sed replacement
      sed -i 's/^dirty: .*/dirty: true/' "$STATE_FILE" 2>/dev/null || true
    }
  else
    # Fallback: simple sed replacement if yq not available
    sed -i 's/^dirty: .*/dirty: true/' "$STATE_FILE" 2>/dev/null || true
  fi
fi

# Return success
cat << 'EOF'
{
  "hookEventName": "PostToolUse"
}
EOF
