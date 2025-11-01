#!/bin/bash
# init-state.sh
# Purpose: Initialize state.yaml with default runtime state

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Usage
usage() {
  cat << EOF
Usage: $0 <project-root>

Initialize .spec-drive/state.yaml with default runtime state.

Arguments:
  project-root    Path to the project

Example:
  $0 /path/to/my-project
EOF
}

# Validate arguments
if [ $# -ne 1 ]; then
  usage >&2
  exit 1
fi

PROJECT_ROOT="$1"

# Validate project root exists
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "❌ ERROR: Project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

SPEC_DRIVE_DIR="$PROJECT_ROOT/.spec-drive"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SCHEMA_FILE="$SPEC_DRIVE_DIR/schemas/v0.1/state-schema.json"

# Ensure .spec-drive exists
if [ ! -d "$SPEC_DRIVE_DIR" ]; then
  echo "❌ ERROR: .spec-drive/ not found. Run init-directories.sh first." >&2
  exit 1
fi

echo "================================================"
echo "  Initializing state.yaml"
echo "================================================"
echo "Project: $PROJECT_ROOT"
echo ""

# Check if state.yaml already exists
if [ -f "$STATE_FILE" ]; then
  echo "⚠️  WARNING: state.yaml already exists"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
  fi
  # Backup existing state
  cp "$STATE_FILE" "$STATE_FILE.bak"
  echo "  📦 Backed up to state.yaml.bak"
fi

# Generate state.yaml
echo "📝 Generating state.yaml..."

cat > "$STATE_FILE" << EOF
# .spec-drive/state.yaml
# Runtime state for spec-drive workflows
# This file is gitignored and regenerated as needed

# Current workflow state
current_workflow: null
current_spec: null
current_stage: null
can_advance: false
dirty: false

# Workflow history
workflows: {}

# Metadata
meta:
  initialized: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  last_gate_run: null
  last_autodocs_run: null
  spec_drive_version: "0.1.0"

# Notes:
# - current_workflow: "app-new" | "feature" | null
# - current_spec: spec ID (e.g., "AUTH-001") or null
# - current_stage: "discover" | "specify" | "implement" | "verify" | null
# - can_advance: true if current stage gate passed, false otherwise
# - dirty: true if code/docs changed since last autodocs run
# - workflows: map of spec_id -> {status, started, completed, history}
EOF

echo "  ✅ Created $STATE_FILE"

# Validate against schema (if yq available)
if command -v yq &> /dev/null; then
  echo "✅ Validating YAML syntax..."
  if yq eval '.' "$STATE_FILE" > /dev/null 2>&1; then
    echo "  ✅ state.yaml is valid YAML"
  else
    echo "  ❌ state.yaml has syntax errors" >&2
    exit 1
  fi
fi

echo ""
echo "================================================"
echo "  state.yaml initialized successfully!"
echo "================================================"
echo ""
echo "Note: state.yaml is gitignored (runtime only)"
echo ""

exit 0
