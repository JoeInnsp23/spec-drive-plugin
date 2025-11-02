#!/usr/bin/env bash
# run.sh
# Purpose: Orchestrate app-new workflow (discovery → spec → workspace → state)
# Usage: ./run.sh --discovery-json "$(cat /tmp/discovery-data.json)"

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"

# Check dependencies
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -x "$PLUGIN_ROOT/scripts/check-dependencies.sh" ]]; then
  "$PLUGIN_ROOT/scripts/check-dependencies.sh" || exit 1
else
  echo -e "${YELLOW}⚠${NC}  Warning: Dependency check script not found at $PLUGIN_ROOT/scripts/check-dependencies.sh"
  echo "Proceeding anyway, but errors may occur if dependencies are missing"
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
Usage: $0 --discovery-json <json-string>

Initialize a new project from comprehensive discovery data.

Required Arguments:
  --discovery-json <json>    JSON string containing discovery interview results

Options:
  --help                     Show this help message

Example:
  $0 --discovery-json "\$(cat /tmp/discovery-data.json)"

Prerequisites:
  - No active workflow (complete or abandon current workflow first)
  - spec-drive plugin initialized
  - Valid discovery JSON with all required fields
EOF
  exit 0
}

# Parse arguments
DISCOVERY_JSON=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage
      ;;
    --discovery-json)
      DISCOVERY_JSON="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}❌ ERROR: Unknown argument: $1${NC}" >&2
      usage
      ;;
  esac
done

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  spec-drive: app-new Workflow${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Validate discovery JSON provided
if [[ -z "$DISCOVERY_JSON" ]]; then
  echo -e "${RED}❌ ERROR: --discovery-json is required${NC}" >&2
  usage
fi

# Validate discovery JSON is valid JSON
if ! echo "$DISCOVERY_JSON" | python3 -m json.tool >/dev/null 2>&1; then
  echo -e "${RED}❌ ERROR: Invalid JSON provided${NC}" >&2
  echo "Discovery data must be valid JSON" >&2
  exit 1
fi

# Extract project name for validation
PROJECT_NAME=$(echo "$DISCOVERY_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['project']['name'])" 2>/dev/null || echo "")
if [[ -z "$PROJECT_NAME" ]]; then
  echo -e "${RED}❌ ERROR: Discovery JSON missing project.name${NC}" >&2
  exit 1
fi

# Validate project name (alphanumeric, dashes, underscores)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo -e "${RED}❌ ERROR: Invalid project name: $PROJECT_NAME${NC}" >&2
  echo "Project name must contain only letters, numbers, dashes, and underscores" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Project name: $PROJECT_NAME"
echo ""

# Check 1: spec-drive initialized
if [[ ! -d "$SPEC_DRIVE_DIR" ]]; then
  echo -e "${RED}❌ ERROR: spec-drive not initialized${NC}" >&2
  echo "Run /spec-drive:init first" >&2
  exit 1
fi

# Check 2: No active workflow
acquire_lock

current_workflow=$(yq eval '.current_workflow' "$STATE_FILE" 2>/dev/null || echo "null")
if [[ "$current_workflow" != "null" ]]; then
  echo -e "${RED}❌ ERROR: Active workflow exists: $current_workflow${NC}" >&2
  echo "Complete or abandon current workflow before starting app-new" >&2
  echo "" >&2
  echo "To abandon: Run /spec-drive:status and follow instructions" >&2
  release_lock
  exit 1
fi

release_lock

echo -e "${GREEN}✓${NC} All prerequisite checks passed"
echo ""

# ==============================================================================
# Step 1: Create Comprehensive Spec
# ==============================================================================

echo -e "${BLUE}Step 1/4: Create Comprehensive Spec${NC}"
echo "Generating APP-001 spec from discovery data..."
echo ""

if ! "$SCRIPT_DIR/create-spec.sh" "$DISCOVERY_JSON"; then
  echo -e "${RED}❌ ERROR: Spec creation failed${NC}" >&2
  exit 1
fi

SPEC_ID="APP-001"
echo -e "${GREEN}✓${NC} Created $SPEC_ID spec"
echo ""

# ==============================================================================
# Step 2: Update AI-Navigable Index
# ==============================================================================

echo -e "${BLUE}Step 2/4: Update AI-Navigable Index${NC}"
echo "Creating index for AI navigation..."
echo ""

if ! "$SCRIPT_DIR/update-index.sh" "$SPEC_ID"; then
  echo -e "${RED}❌ ERROR: Index update failed${NC}" >&2
  # Rollback: Remove spec
  rm -f "$SPEC_DRIVE_DIR/specs/$SPEC_ID.yaml"
  echo "Rolled back $SPEC_ID spec" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Updated index"
echo ""

# ==============================================================================
# Step 3: Initialize Development Workspace
# ==============================================================================

echo -e "${BLUE}Step 3/4: Initialize Development Workspace${NC}"
echo "Setting up workspace for $SPEC_ID..."
echo ""

if ! "$SCRIPT_DIR/init-development.sh" "$SPEC_ID"; then
  echo -e "${RED}❌ ERROR: Workspace initialization failed${NC}" >&2
  # Rollback: Remove spec and index entry
  rm -f "$SPEC_DRIVE_DIR/specs/$SPEC_ID.yaml"
  echo "Rolled back $SPEC_ID spec" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Workspace initialized"
echo ""

# ==============================================================================
# Step 4: Initialize Workflow State
# ==============================================================================

echo -e "${BLUE}Step 4/4: Initialize Workflow State${NC}"
echo "Setting up workflow state..."
echo ""

# Start workflow using workflow engine
if ! workflow_start "app-new" "$SPEC_ID" 2>&1; then
  echo -e "${RED}❌ ERROR: Failed to initialize workflow state${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Workflow state initialized"
echo ""

# ==============================================================================
# Success Summary
# ==============================================================================

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  🎉 app-new Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Your project is initialized with comprehensive specifications."
echo ""
echo -e "${YELLOW}What was created:${NC}"
echo "  • $SPEC_ID spec: .spec-drive/specs/$SPEC_ID.yaml"
echo "  • AI-navigable index: .spec-drive/index.yaml"
echo "  • Development workspace: .spec-drive/development/current/$SPEC_ID/"
echo "  • Workflow state initialized (app-new → discover stage)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review spec: .spec-drive/specs/$SPEC_ID.yaml"
echo "  2. Check AI index: .spec-drive/index.yaml"
echo "  3. Review workspace: .spec-drive/development/current/$SPEC_ID/"
echo "  4. Resolve any open questions if documented"
echo "  5. Start building features: /spec-drive:feature"
echo "  6. Check status anytime: /spec-drive:status"
echo ""
echo -e "${BLUE}Happy building! 🚀${NC}"
echo ""
