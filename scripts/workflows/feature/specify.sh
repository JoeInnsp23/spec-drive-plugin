#!/bin/bash
# specify.sh
# Purpose: Specify stage - add/validate acceptance criteria
# Usage: Called automatically by workflow advance

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"

# Source workflow engine
source "$SCRIPT_DIR/../workflow-engine.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Get Current Spec
# ==============================================================================

acquire_lock
SPEC_ID=$(yq eval '.current_spec' "$STATE_FILE")
release_lock

if [[ "$SPEC_ID" == "null" ]] || [[ -z "$SPEC_ID" ]]; then
  echo -e "${RED}❌ ERROR: No active spec${NC}" >&2
  exit 1
fi

SPEC_FILE="$SPECS_DIR/$SPEC_ID.yaml"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo -e "${RED}❌ ERROR: Spec file not found: $SPEC_FILE${NC}" >&2
  exit 1
fi

# ==============================================================================
# Specify Stage Activities
# ==============================================================================

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Specify Stage: $SPEC_ID${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo -e "${YELLOW}Define Acceptance Criteria${NC}"
echo ""
echo "Add testable acceptance criteria to: $SPEC_FILE"
echo ""

# Show current acceptance criteria
echo -e "${BLUE}Current acceptance criteria:${NC}"
CRITERIA_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE")

if [[ "$CRITERIA_COUNT" -eq 0 ]]; then
  echo "  (none yet)"
else
  yq eval '.acceptance_criteria[]' "$SPEC_FILE" | sed 's/^/  - /'
fi

echo ""

# Prompt to open spec in editor
echo -e "${YELLOW}Would you like to add acceptance criteria now? [y/N]${NC}"
read -p "→ " ADD_NOW

if [[ "$ADD_NOW" =~ ^[Yy]$ ]]; then
  echo ""
  echo "Opening spec in editor..."
  echo "(Add items to the acceptance_criteria array)"
  echo ""

  # Detect editor
  EDITOR="${EDITOR:-${VISUAL:-vi}}"

  # Open in editor
  "$EDITOR" "$SPEC_FILE"

  # Check if criteria were added
  NEW_CRITERIA_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE")

  if [[ "$NEW_CRITERIA_COUNT" -gt "$CRITERIA_COUNT" ]]; then
    echo ""
    echo -e "${GREEN}✓${NC} Added $((NEW_CRITERIA_COUNT - CRITERIA_COUNT)) criteria"
  else
    echo ""
    echo -e "${YELLOW}⚠${NC}  No new criteria added"
  fi
fi

echo ""

# ==============================================================================
# Validation Check (Simple - no full quality gate)
# ==============================================================================

echo -e "${BLUE}Validation Check${NC}"

# Check: At least one acceptance criterion
CRITERIA_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE")

if [[ "$CRITERIA_COUNT" -eq 0 ]]; then
  echo -e "${RED}✗${NC} No acceptance criteria defined"
  echo "  Add at least one criterion before advancing"
  echo ""
  echo -e "${YELLOW}To add criteria:${NC}"
  echo "  1. Edit: $SPEC_FILE"
  echo "  2. Add items to acceptance_criteria array"
  echo "  3. Run: /spec-drive:feature advance"
  echo ""

  # Set can_advance to false
  acquire_lock
  yq eval ".can_advance = false" "$STATE_FILE" -i
  release_lock

  exit 1
fi

echo -e "${GREEN}✓${NC} $CRITERIA_COUNT acceptance criteria defined"

# Update spec timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
yq eval ".updated = \"$TIMESTAMP\"" "$SPEC_FILE" -i

# ==============================================================================
# Run Quality Gate 2 (Specify)
# ==============================================================================

echo ""
echo -e "${BLUE}Running Quality Gate 2 (Specify)...${NC}"
echo ""

GATE_SCRIPT="$SCRIPT_DIR/../../gates/gate-2-specify.sh"

if [[ -x "$GATE_SCRIPT" ]]; then
  if "$GATE_SCRIPT"; then
    echo ""
    echo -e "${GREEN}✓ Quality Gate 2 PASSED${NC}"
  else
    echo ""
    echo -e "${RED}✗ Quality Gate 2 FAILED${NC}"
    echo "Fix the issues above before advancing"
    exit 1
  fi
else
  # Fallback if gate script not found
  echo -e "${YELLOW}⚠${NC}  Gate script not found, setting can_advance manually"
  acquire_lock
  yq eval ".can_advance = true" "$STATE_FILE" -i
  release_lock
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}Specify stage complete!${NC}"
echo ""
echo "Acceptance criteria: $CRITERIA_COUNT"
echo ""
echo -e "${YELLOW}Next: Implement the feature${NC}"
echo "  1. Write code to satisfy acceptance criteria"
echo "  2. Add @spec $SPEC_ID tags to code"
echo "  3. Write tests for each criterion"
echo "  4. Run: /spec-drive:feature advance"
echo ""
