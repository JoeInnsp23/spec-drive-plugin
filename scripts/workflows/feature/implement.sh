#!/bin/bash
# implement.sh
# Purpose: Implement stage - guide implementation, check @spec tags
# Usage: Called automatically by workflow advance

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
CONFIG_FILE="$SPEC_DRIVE_DIR/config.yaml"

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
# Implement Stage Activities
# ==============================================================================

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Implement Stage: $SPEC_ID${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Show acceptance criteria checklist
echo -e "${YELLOW}Acceptance Criteria Checklist:${NC}"
echo ""

yq eval '.acceptance_criteria[]' "$SPEC_FILE" 2>/dev/null | while IFS= read -r criterion; do
  echo "  [ ] $criterion"
done

echo ""

# @spec tag examples
echo -e "${YELLOW}Remember to add @spec tags to your code:${NC}"
echo ""
echo "  JavaScript/TypeScript:"
echo "    // @spec $SPEC_ID"
echo ""
echo "  Python:"
echo "    # @spec $SPEC_ID"
echo ""
echo "  Bash:"
echo "    # @spec $SPEC_ID"
echo ""

# ==============================================================================
# Implementation Check
# ==============================================================================

echo -e "${BLUE}Implementation Check${NC}"
echo ""

# Check 1: @spec tags present
echo -n "Checking for @spec tags... "

TAG_COUNT=$(grep -r "@spec $SPEC_ID" . --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.spec-drive 2>/dev/null | wc -l || echo "0")

if [[ "$TAG_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} Found $TAG_COUNT @spec tag(s)"
else
  echo -e "${YELLOW}⚠${NC}  No @spec tags found"
  echo "  Add @spec $SPEC_ID comments to your implementation"
fi

# Check 2: Test command (if configured)
if [[ -f "$CONFIG_FILE" ]]; then
  TEST_CMD=$(yq eval '.tools.test_command' "$CONFIG_FILE" 2>/dev/null || echo "null")

  if [[ "$TEST_CMD" != "null" ]] && [[ -n "$TEST_CMD" ]]; then
    echo -n "Running tests... "

    if $TEST_CMD >/dev/null 2>&1; then
      echo -e "${GREEN}✓${NC} Tests pass"
    else
      echo -e "${RED}✗${NC} Tests failing"
      echo ""
      echo -e "${YELLOW}Fix test failures before advancing${NC}"
      echo ""

      # Set can_advance to false
      acquire_lock
      yq eval ".can_advance = false" "$STATE_FILE" -i
      release_lock

      exit 1
    fi
  fi
fi

# ==============================================================================
# Ready to Advance?
# ==============================================================================

echo ""
echo -e "${YELLOW}Is implementation complete and ready for verification? [y/N]${NC}"
read -p "→ " READY

if [[ ! "$READY" =~ ^[Yy]$ ]]; then
  echo ""
  echo "Continue implementing and run /spec-drive:feature advance when ready"
  echo ""

  # Set can_advance to false
  acquire_lock
  yq eval ".can_advance = false" "$STATE_FILE" -i
  release_lock

  exit 0
fi

# Update spec timestamp
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
yq eval ".updated = \"$TIMESTAMP\"" "$SPEC_FILE" -i

# Set can_advance to true
acquire_lock
yq eval ".can_advance = true" "$STATE_FILE" -i
release_lock

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}Implement stage complete!${NC}"
echo ""
echo "  @spec tags: $TAG_COUNT"
echo ""
echo -e "${YELLOW}Next: Verify and finalize${NC}"
echo "  Run: /spec-drive:feature advance"
echo ""
