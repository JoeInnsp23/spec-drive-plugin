#!/bin/bash
# verify.sh
# Purpose: Verify stage - final checks, complete workflow
# Usage: Called automatically by workflow advance

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
INDEX_FILE="$SPEC_DRIVE_DIR/SPECS-INDEX.yaml"

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
# Verify Stage Activities
# ==============================================================================

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Verify Stage: $SPEC_ID${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo -e "${YELLOW}Final Verification${NC}"
echo ""

# ==============================================================================
# Verification Checks
# ==============================================================================

CHECKS_PASSED=0
CHECKS_TOTAL=0

# Check 1: Acceptance criteria defined
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
CRITERIA_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE")

echo -n "  Acceptance criteria... "
if [[ "$CRITERIA_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($CRITERIA_COUNT defined)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC} None defined"
fi

# Check 2: @spec tags present
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
TAG_COUNT=$(grep -r "@spec $SPEC_ID" . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.spec-drive 2>/dev/null | wc -l || echo "0")

echo -n "  @spec tags... "
if [[ "$TAG_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($TAG_COUNT found)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC}  None found"
fi

# Check 3: Spec status
CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
SPEC_STATUS=$(yq eval '.status' "$SPEC_FILE")

echo -n "  Spec status... "
echo "$SPEC_STATUS"

echo ""

# ==============================================================================
# Update Spec to Implemented
# ==============================================================================

echo -e "${BLUE}Finalizing spec...${NC}"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Update spec status to implemented
yq eval ".status = \"implemented\" | .updated = \"$TIMESTAMP\"" "$SPEC_FILE" -i

# Update traceability (basic - find files with @spec tags)
echo -n "  Updating traceability... "

# Find code files
CODE_FILES=$(grep -r -l "@spec $SPEC_ID" . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.spec-drive 2>/dev/null || true)

if [[ -n "$CODE_FILES" ]]; then
  # Clear existing traces
  yq eval ".traces.code = []" "$SPEC_FILE" -i

  # Add each file
  while IFS= read -r file; do
    # Remove leading ./
    file="${file#./}"
    yq eval ".traces.code += [\"$file\"]" "$SPEC_FILE" -i
  done <<< "$CODE_FILES"

  FILE_COUNT=$(echo "$CODE_FILES" | wc -l)
  echo -e "${GREEN}✓${NC} ($FILE_COUNT files)"
else
  echo -e "${YELLOW}⚠${NC}  No files found"
fi

# Update index
yq eval "(.specs[] | select(.spec_id == \"$SPEC_ID\") | .status) = \"implemented\" | \
         (.specs[] | select(.spec_id == \"$SPEC_ID\") | .updated) = \"$TIMESTAMP\" | \
         .updated = \"$TIMESTAMP\"" \
  "$INDEX_FILE" -i

echo -e "${GREEN}✓${NC} Spec updated to implemented"

# ==============================================================================
# Run Quality Gate 4 (Verify)
# ==============================================================================

echo ""
echo -e "${BLUE}Running Quality Gate 4 (Verify)...${NC}"
echo ""

GATE_SCRIPT="$SCRIPT_DIR/../../gates/gate-4-verify.sh"

if [[ -x "$GATE_SCRIPT" ]]; then
  if "$GATE_SCRIPT"; then
    echo ""
    echo -e "${GREEN}✓ Quality Gate 4 PASSED${NC}"
  else
    echo ""
    echo -e "${RED}✗ Quality Gate 4 FAILED${NC}"
    echo "Fix the issues above before completing"
    exit 1
  fi
else
  # Fallback if gate script not found
  echo -e "${YELLOW}⚠${NC}  Gate script not found, proceeding without gate check"
fi

# ==============================================================================
# Archive Development Work to Completed
# ==============================================================================

echo ""
echo -e "${BLUE}Archiving development work...${NC}"

DEV_CURRENT_DIR="$SPEC_DRIVE_DIR/development/current/$SPEC_ID"
DEV_COMPLETED_DIR="$SPEC_DRIVE_DIR/development/completed"

if [[ -d "$DEV_CURRENT_DIR" ]]; then
  mkdir -p "$DEV_COMPLETED_DIR"

  # Add completion timestamp to directory name
  COMPLETION_DATE=$(date -u +%Y%m%d)
  TARGET_DIR="$DEV_COMPLETED_DIR/${SPEC_ID}_${COMPLETION_DATE}"

  # If dir already exists (re-run), add counter
  if [[ -d "$TARGET_DIR" ]]; then
    counter=1
    while [[ -d "${TARGET_DIR}_${counter}" ]]; do
      counter=$((counter + 1))
    done
    TARGET_DIR="${TARGET_DIR}_${counter}"
  fi

  mv "$DEV_CURRENT_DIR" "$TARGET_DIR"
  echo -e "${GREEN}✓${NC} Moved: development/current/$SPEC_ID → completed/$(basename "$TARGET_DIR")"
else
  echo -e "${YELLOW}⚠${NC}  No development folder found (skipped)"
fi

# ==============================================================================
# Complete Workflow
# ==============================================================================

echo ""
echo -e "${BLUE}Completing workflow...${NC}"

workflow_complete >/dev/null 2>&1

echo -e "${GREEN}✓${NC} Workflow complete"

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  🎉 Feature Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Spec: $SPEC_ID"
echo "Status: implemented"
echo "Acceptance criteria: $CRITERIA_COUNT"
echo "Code files traced: $(yq eval '.traces.code | length' "$SPEC_FILE")"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  ✓ Spec created and specified"
echo "  ✓ Feature implemented"
echo "  ✓ Traceability established"
echo "  ✓ Workflow completed"
echo ""
echo -e "${BLUE}What's next:${NC}"
echo "  • Start another feature: /spec-drive:feature start <title>"
echo "  • View all specs: cat .spec-drive/SPECS-INDEX.yaml"
echo "  • Check status: /spec-drive:status"
echo ""
