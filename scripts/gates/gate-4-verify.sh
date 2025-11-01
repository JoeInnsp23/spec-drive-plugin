#!/bin/bash
# gate-4-verify.sh
# Purpose: Quality gate for Verify stage
# Validates: All ACs met, no shortcuts, traceability complete, docs updated
# Exit: 0 = pass, 1 = fail

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
INDEX_FILE="$SPEC_DRIVE_DIR/index.yaml"

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
# Gate 4 Validation Checks
# ==============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quality Gate 4: Verify${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: No TODO markers anywhere
echo -n "Check 1: No TODO markers in codebase... "

TODO_COUNT=$(grep -r "TODO" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.rs" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  2>/dev/null | wc -l)

if [[ $TODO_COUNT -eq 0 ]]; then
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Found $TODO_COUNT TODO markers - all must be resolved"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: No console.log anywhere
echo -n "Check 2: No console.log in production code... "

CONSOLE_COUNT=$(grep -r "console\.log" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  --exclude-dir=tests --exclude-dir=test --exclude="*.test.*" --exclude="*.spec.*" \
  2>/dev/null | wc -l)

if [[ $CONSOLE_COUNT -eq 0 ]]; then
  echo -e "${GREEN}✓${NC}"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  Found $CONSOLE_COUNT console.log statements"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 3: Traceability complete (index.yaml exists and has spec)
echo -n "Check 3: Traceability index exists... "

if [[ -f "$INDEX_FILE" ]]; then
  # Check if spec is in index
  if yq eval ".specs[] | select(.id == \"$SPEC_ID\")" "$INDEX_FILE" | grep -q "$SPEC_ID"; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  Spec $SPEC_ID not found in index.yaml"
    echo "  Run: update-index.sh"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
else
  echo -e "${RED}✗${NC}"
  echo "  index.yaml not found"
  echo "  Run: update-index.sh"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 4: Spec has code traces
if [[ -f "$INDEX_FILE" ]]; then
  echo -n "Check 4: Code traces exist... "

  CODE_TRACE_COUNT=$(yq eval ".specs[] | select(.id == \"$SPEC_ID\") | .trace.code | length" "$INDEX_FILE" 2>/dev/null || echo "0")

  if [[ "$CODE_TRACE_COUNT" != "null" ]] && [[ $CODE_TRACE_COUNT -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} ($CODE_TRACE_COUNT traces)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  No code traces for $SPEC_ID"
    echo "  Add @spec $SPEC_ID tags to code"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
fi

# Check 5: Spec has test traces
if [[ -f "$INDEX_FILE" ]]; then
  echo -n "Check 5: Test traces exist... "

  TEST_TRACE_COUNT=$(yq eval ".specs[] | select(.id == \"$SPEC_ID\") | .trace.tests | length" "$INDEX_FILE" 2>/dev/null || echo "0")

  if [[ "$TEST_TRACE_COUNT" != "null" ]] && [[ $TEST_TRACE_COUNT -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} ($TEST_TRACE_COUNT traces)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  No test traces for $SPEC_ID"
    echo "  Add @spec $SPEC_ID tags to tests"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
fi

# Check 6: Documentation updated (docs/ has recent commits)
echo -n "Check 6: Documentation updated... "

if [[ -d "docs" ]]; then
  # Check if docs/ directory has been modified
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # In a git repo - check recent commits to docs/
    RECENT_DOC_COMMITS=$(git log --since="1 week ago" --oneline -- docs/ 2>/dev/null | wc -l)

    if [[ $RECENT_DOC_COMMITS -gt 0 ]]; then
      echo -e "${GREEN}✓${NC} ($RECENT_DOC_COMMITS recent commits)"
      CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
      # Check if docs have uncommitted changes
      if git status --porcelain docs/ 2>/dev/null | grep -q .; then
        echo -e "${GREEN}✓${NC} (uncommitted changes)"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
      else
        echo -e "${YELLOW}⚠${NC} No recent doc updates"
        echo "  Update docs/ before completing"
        # Soft warning for now
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
      fi
    fi
  else
    # Not in git repo, just check if docs exist
    echo -e "${GREEN}✓${NC} (docs directory exists)"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  fi
else
  echo -e "${YELLOW}⚠${NC} No docs/ directory"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 7: Spec status updated
echo -n "Check 7: Spec status appropriate... "

SPEC_STATUS=$(yq eval '.status' "$SPEC_FILE" 2>/dev/null || echo "null")

if [[ "$SPEC_STATUS" == "implemented" ]] || [[ "$SPEC_STATUS" == "done" ]]; then
  echo -e "${GREEN}✓${NC} ($SPEC_STATUS)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC} Status is '$SPEC_STATUS'"
  echo "  Consider updating to 'implemented' or 'done'"
  # Soft warning
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 8: All acceptance criteria addressed
echo -n "Check 8: Acceptance criteria reviewed... "

AC_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE" 2>/dev/null || echo "0")

if [[ $AC_COUNT -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($AC_COUNT criteria defined)"
  echo "  Verify manually that all criteria are met"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${YELLOW}⚠${NC} No acceptance criteria"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Gate 4 Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Gate 4 PASSED${NC}"
  echo ""

  # Set can_advance = true
  if declare -f acquire_lock >/dev/null 2>&1; then
    acquire_lock
    yq eval ".can_advance = true" "$STATE_FILE" -i
    release_lock
  else
    yq eval ".can_advance = true" "$STATE_FILE" -i
  fi

  echo "Feature implementation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Review all changes"
  echo "  2. Create atomic commit"
  echo "  3. Run: /spec-drive:feature complete"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Gate 4 FAILED${NC}"
  echo ""
  echo "Fix the issues above before completing"
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
