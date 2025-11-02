#!/usr/bin/env bash
# session-start.sh
# SessionStart hook for spec-drive plugin
# Injects strict-concise behavior prompt into Claude Code sessions

set -euo pipefail

# Locate behavior file using CLAUDE_PLUGIN_ROOT
BEHAVIOR_FILE="${CLAUDE_PLUGIN_ROOT}/assets/strict-concise-behavior.md"

# Validate file exists
if [ ! -f "$BEHAVIOR_FILE" ]; then
  echo "{\"hookEventName\": \"SessionStart\", \"error\": \"Behavior file not found: $BEHAVIOR_FILE\"}" >&2
  exit 1
fi

# Read behavior content
BEHAVIOR_CONTENT=$(cat "$BEHAVIOR_FILE")

# Return JSON with additionalContext
# Use jq to properly escape the markdown content as JSON string
cat << EOF
{
  "hookEventName": "SessionStart",
  "additionalContext": $(echo "$BEHAVIOR_CONTENT" | jq -Rs .)
}
EOF
