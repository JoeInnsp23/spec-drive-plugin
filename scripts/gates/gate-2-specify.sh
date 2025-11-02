#!/usr/bin/env bash
# gate-2-specify.sh
# Purpose: Quality gate for Specify stage
# Validates: Spec structure, acceptance criteria, no clarity markers, API contracts
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
  exit 1
fi

# Get current spec
SPEC_ID=$(yq eval '.current_spec' "$STATE_FILE" 2>/dev/null || echo "null")

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
# Gate 2 Validation Checks
# ==============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quality Gate 2: Specify${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: Acceptance criteria exist
echo -n "Check 1: Acceptance criteria defined... "
AC_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ $AC_COUNT -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($AC_COUNT criteria)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Add at least one acceptance criterion"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: Each AC is non-empty
if [[ $AC_COUNT -gt 0 ]]; then
  echo -n "Check 2: All criteria have content... "
  EMPTY_COUNT=0

  for ((i=0; i<AC_COUNT; i++)); do
    AC=$(yq eval ".acceptance_criteria[$i]" "$SPEC_FILE" 2>/dev/null || echo "")
    if [[ -z "$AC" ]] || [[ "$AC" == "null" ]]; then
      EMPTY_COUNT=$((EMPTY_COUNT + 1))
    fi
  done

  if [[ $EMPTY_COUNT -eq 0 ]]; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  $EMPTY_COUNT criteria are empty"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
fi

# Check 3: No clarity markers ([NEEDS CLARIFICATION], [TBD], etc.)
echo -n "Check 3: No clarity markers... "
SPEC_CONTENT=$(cat "$SPEC_FILE")
if echo "$SPEC_CONTENT" | grep -qiE '\[NEEDS CLARIFICATION\]|\[TBD\]|\[TODO\]|\[FIXME\]'; then
  echo -e "${RED}✗${NC}"
  echo "  Found clarity markers in spec:"
  echo "$SPEC_CONTENT" | grep -niE '\[NEEDS CLARIFICATION\]|\[TBD\]|\[TODO\]|\[FIXME\]' | sed 's/^/    /' || true
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
else
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 4: API contracts defined (if applicable)
echo -n "Check 4: API contracts defined (if needed)... "
# Check if spec mentions API/endpoint/route/interface
if echo "$SPEC_CONTENT" | grep -qiE 'api|endpoint|route|interface|contract'; then
  # Spec mentions APIs, check if api_contracts section exists
  API_CONTRACTS=$(yq eval '.api_contracts' "$SPEC_FILE" 2>/dev/null || echo "null")
  if [[ "$API_CONTRACTS" != "null" ]] && [[ -n "$API_CONTRACTS" ]]; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${YELLOW}⚠${NC}"
    echo "  Spec mentions APIs but no api_contracts section"
    echo "  Add 'api_contracts:' section if exposing APIs"
    # Not a hard failure, just a warning
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi
else
  # No API mentions, skip check
  echo -e "${GREEN}✓${NC} (N/A)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 5: Test scenarios exist
echo -n "Check 5: Test scenarios defined... "
TEST_SCENARIOS=$(yq eval '.test_scenarios | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ $TEST_SCENARIOS -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($TEST_SCENARIOS scenarios)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  No test scenarios defined"
  echo "  Add 'test_scenarios:' to guide test implementation"
  # Soft warning, not a hard failure
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 6: Non-functional requirements considered
echo -n "Check 6: Non-functional requirements... "
NFR=$(yq eval '.non_functional_requirements' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$NFR" != "null" ]] && [[ -n "$NFR" ]]; then
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC}"
  echo "  No non-functional requirements defined"
  echo "  Consider adding performance, security, or scalability requirements"
  # Soft warning
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Gate 2 Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Gate 2 PASSED${NC}"
  echo ""

  # Set can_advance = true
  if declare -f acquire_lock >/dev/null 2>&1; then
    acquire_lock
    yq eval ".can_advance = true" "$STATE_FILE" -i
    release_lock
  else
    yq eval ".can_advance = true" "$STATE_FILE" -i
  fi

  echo "Ready to advance to Implement stage"
  echo "Run: /spec-drive:feature advance"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Gate 2 FAILED${NC}"
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
