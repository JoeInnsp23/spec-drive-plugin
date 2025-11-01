#!/bin/bash
# gate-1-discover.sh
# Purpose: Quality gate for Discover stage
# Validates: Requirements documented, understanding confirmed
# Exit: 0 = pass, 1 = fail

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Source workflow engine for lock functions
if [[ -f "$SCRIPT_DIR/../workflows/workflow-engine.sh" ]]; then
  source "$SCRIPT_DIR/../workflows/workflow-engine.sh"
fi

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

if [[ ! -f "$STATE_FILE" ]]; then
  echo -e "${RED}❌ ERROR: state.yaml not found${NC}" >&2
  echo "  Run /spec-drive:feature first" >&2
  exit 1
fi

# Get current spec
if command -v yq &>/dev/null; then
  SPEC_ID=$(yq eval '.current_spec' "$STATE_FILE" 2>/dev/null || echo "null")
else
  echo -e "${RED}❌ ERROR: yq not installed${NC}" >&2
  exit 1
fi

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
# Gate 1 Validation Checks
# ==============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quality Gate 1: Discover${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: Spec file exists and is valid YAML
echo -n "Check 1: Spec file is valid YAML... "
if yq eval '.' "$SPEC_FILE" >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Spec file contains invalid YAML"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: Spec has ID
echo -n "Check 2: Spec has ID... "
ID_VALUE=$(yq eval '.id' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$ID_VALUE" != "null" ]] && [[ -n "$ID_VALUE" ]]; then
  echo -e "${GREEN}✓${NC} ($ID_VALUE)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Add 'id: $SPEC_ID' to spec file"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 3: Spec has title
echo -n "Check 3: Spec has title... "
TITLE_VALUE=$(yq eval '.title' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$TITLE_VALUE" != "null" ]] && [[ -n "$TITLE_VALUE" ]]; then
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Add 'title: <feature title>' to spec file"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 4: Spec has description
echo -n "Check 4: Spec has description... "
DESC_VALUE=$(yq eval '.description' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$DESC_VALUE" != "null" ]] && [[ -n "$DESC_VALUE" ]] && [[ "$DESC_VALUE" != "" ]]; then
  DESC_LENGTH=${#DESC_VALUE}
  if [[ $DESC_LENGTH -ge 20 ]]; then
    echo -e "${GREEN}✓${NC} ($DESC_LENGTH chars)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${YELLOW}⚠${NC} Description too short ($DESC_LENGTH chars, min 20)"
    echo "  Add more detail to the description field"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
else
  echo -e "${RED}✗${NC}"
  echo "  Add 'description:' with feature details"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 5: Spec has status
echo -n "Check 5: Spec has status... "
STATUS_VALUE=$(yq eval '.status' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$STATUS_VALUE" != "null" ]] && [[ -n "$STATUS_VALUE" ]]; then
  echo -e "${GREEN}✓${NC} ($STATUS_VALUE)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Add 'status: draft' to spec file"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Gate 1 Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Gate 1 PASSED${NC}"
  echo ""

  # Set can_advance = true
  if declare -f acquire_lock >/dev/null 2>&1; then
    acquire_lock
    yq eval ".can_advance = true" "$STATE_FILE" -i
    release_lock
  else
    yq eval ".can_advance = true" "$STATE_FILE" -i
  fi

  echo "Ready to advance to Specify stage"
  echo "Run: /spec-drive:feature advance"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Gate 1 FAILED${NC}"
  echo ""
  echo "Fix the issues above before advancing"
  echo ""

  # Set can_advance = false
  if declare -f acquire_lock >/dev/null 2>&1; then
    acquire_lock
    yq eval ".can_advance = false" "$STATE_FILE" -i
    release_lock
  else
    yq eval ".can_advance = false" "$STATE_FILE" -i
  fi

  exit 1
fi
