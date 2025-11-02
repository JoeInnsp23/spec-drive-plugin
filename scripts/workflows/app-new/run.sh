#!/bin/bash
# run.sh
# Purpose: Orchestrate app-new workflow (planning + docs generation)
# Usage: ./run.sh [project-name]

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
Usage: $0 [project-name]

Initialize a new project with guided planning session and documentation.

Arguments:
  project-name    Name of the project (optional, will prompt if not provided)

Options:
  --help          Show this help message

Examples:
  $0 my-app
  $0              # Interactive mode (will prompt)

Prerequisites:
  - No active workflow (complete or abandon current workflow first)
  - spec-drive plugin initialized
EOF
  exit 0
}

# Parse arguments
PROJECT_NAME=""
PROJECT_VISION=""
KEY_FEATURES=""
TARGET_USERS=""
TECH_STACK=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage
      ;;
    --name)
      PROJECT_NAME="$2"
      shift 2
      ;;
    --vision)
      PROJECT_VISION="$2"
      shift 2
      ;;
    --features)
      KEY_FEATURES="$2"
      shift 2
      ;;
    --users)
      TARGET_USERS="$2"
      shift 2
      ;;
    --stack)
      TECH_STACK="$2"
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

# Validate required arguments
if [[ -z "$PROJECT_NAME" ]]; then
  echo -e "${RED}❌ ERROR: --name is required${NC}" >&2
  echo "Usage: $0 --name <name> --vision <vision> --features <features> --users <users> --stack <stack>" >&2
  exit 1
fi

if [[ -z "$PROJECT_VISION" ]]; then
  echo -e "${RED}❌ ERROR: --vision is required${NC}" >&2
  exit 1
fi

if [[ -z "$KEY_FEATURES" ]]; then
  echo -e "${RED}❌ ERROR: --features is required${NC}" >&2
  exit 1
fi

if [[ -z "$TARGET_USERS" ]]; then
  echo -e "${RED}❌ ERROR: --users is required${NC}" >&2
  exit 1
fi

if [[ -z "$TECH_STACK" ]]; then
  echo -e "${RED}❌ ERROR: --stack is required${NC}" >&2
  exit 1
fi

# Validate project name (alphanumeric, dashes, underscores)
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo -e "${RED}❌ ERROR: Invalid project name${NC}" >&2
  echo "Project name must contain only letters, numbers, dashes, and underscores" >&2
  exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Project name: $PROJECT_NAME"
echo ""

# ==============================================================================
# Step 1: Planning Session
# ==============================================================================

echo -e "${BLUE}Step 1/3: Planning Session${NC}"
echo "Creating APP-001 spec..."
echo ""

if ! "$SCRIPT_DIR/planning-session.sh" \
  --name "$PROJECT_NAME" \
  --vision "$PROJECT_VISION" \
  --features "$KEY_FEATURES" \
  --users "$TARGET_USERS" \
  --stack "$TECH_STACK"; then
  echo -e "${RED}❌ ERROR: Planning session failed${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Planning session complete"
echo ""

# ==============================================================================
# Step 2: Generate Documentation
# ==============================================================================

echo -e "${BLUE}Step 2/3: Generate Documentation${NC}"
echo "Creating initial documentation suite..."
echo ""

if ! "$SCRIPT_DIR/generate-docs.sh"; then
  echo -e "${RED}❌ ERROR: Documentation generation failed${NC}" >&2
  # Rollback: Remove APP-001 spec
  rm -f "$SPEC_DRIVE_DIR/specs/APP-001.yaml"
  echo "Rolled back APP-001 spec" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Documentation generated"
echo ""

# ==============================================================================
# Step 3: Initialize Workflow State
# ==============================================================================

echo -e "${BLUE}Step 3/3: Initialize Workflow${NC}"
echo "Setting up workflow state..."
echo ""

# Start workflow using workflow engine
if ! workflow_start "app-new" "APP-001" 2>&1; then
  echo -e "${RED}❌ ERROR: Failed to initialize workflow state${NC}" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Workflow initialized"
echo ""

# ==============================================================================
# Success Summary
# ==============================================================================

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  🎉 app-new Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Your project is ready to start building features."
echo ""
echo -e "${YELLOW}What was created:${NC}"
echo "  • APP-001 spec in .spec-drive/specs/"
echo "  • Documentation suite in docs/"
echo "  • Workflow state initialized"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review generated docs: README.md, ARCHITECTURE.md"
echo "  2. Start building features: /spec-drive:feature"
echo "  3. Check workflow status: /spec-drive:status"
echo ""
echo -e "${BLUE}Happy building! 🚀${NC}"
echo ""
