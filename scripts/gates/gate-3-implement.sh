#!/bin/bash
# gate-3-implement.sh
# Purpose: Quality gate for Implement stage
# Validates: Tests pass, lint pass, type-check pass, @spec tags present
# Exit: 0 = pass, 1 = fail

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
CONFIG_FILE="$SPEC_DRIVE_DIR/config.yaml"

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
# Get Project Commands
# ==============================================================================

# Try to get commands from config.yaml
TEST_CMD="null"
LINT_CMD="null"
TYPECHECK_CMD="null"

if [[ -f "$CONFIG_FILE" ]]; then
  TEST_CMD=$(yq eval '.commands.test' "$CONFIG_FILE" 2>/dev/null || echo "null")
  LINT_CMD=$(yq eval '.commands.lint' "$CONFIG_FILE" 2>/dev/null || echo "null")
  TYPECHECK_CMD=$(yq eval '.commands.typecheck' "$CONFIG_FILE" 2>/dev/null || echo "null")
fi

# Fallback: Detect from package.json if present
if [[ -f "package.json" ]]; then
  if [[ "$TEST_CMD" == "null" ]] && jq -e '.scripts.test' package.json >/dev/null 2>&1; then
    TEST_CMD="npm test"
  fi

  if [[ "$LINT_CMD" == "null" ]] && jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
    LINT_CMD="npm run lint"
  fi

  if [[ "$TYPECHECK_CMD" == "null" ]]; then
    # Check for TypeScript
    if jq -e '.devDependencies.typescript' package.json >/dev/null 2>&1; then
      TYPECHECK_CMD="npx tsc --noEmit"
    fi
  fi
fi

# ==============================================================================
# Gate 3 Validation Checks
# ==============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Quality Gate 3: Implement${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# Check 1: @spec tags present
echo -n "Check 1: @spec tags present... "

# Find all @spec tags for this spec
TAG_COUNT=$(grep -r "@spec $SPEC_ID" . --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" --include="*.go" --include="*.rs" 2>/dev/null | wc -l)

if [[ $TAG_COUNT -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($TAG_COUNT tags found)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  No @spec $SPEC_ID tags found in code"
  echo "  Add '// @spec $SPEC_ID' comments to implementation"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 2: Tests exist
echo -n "Check 2: Tests exist... "

# Find test files with @spec tags
TEST_TAG_COUNT=$(grep -r "@spec $SPEC_ID" . --include="*.test.*" --include="*.spec.*" --include="*_test.*" 2>/dev/null | wc -l)

if [[ $TEST_TAG_COUNT -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} ($TEST_TAG_COUNT test tags found)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
  echo -e "${RED}✗${NC}"
  echo "  No test files with @spec $SPEC_ID tags found"
  echo "  Add tests with '// @spec $SPEC_ID' comments"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 3: Run tests
if [[ "$TEST_CMD" != "null" ]] && [[ -n "$TEST_CMD" ]]; then
  echo -n "Check 3: Tests pass... "

  # Run tests, capture output
  TEST_OUTPUT=$(mktemp)
  if $TEST_CMD > "$TEST_OUTPUT" 2>&1; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  Test failures:"
    tail -20 "$TEST_OUTPUT" | sed 's/^/    /'
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
  rm -f "$TEST_OUTPUT"
else
  echo "Check 3: Tests pass... ${YELLOW}⚠${NC} (no test command configured)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 4: Run lint
if [[ "$LINT_CMD" != "null" ]] && [[ -n "$LINT_CMD" ]]; then
  echo -n "Check 4: Lint passes... "

  LINT_OUTPUT=$(mktemp)
  if $LINT_CMD > "$LINT_OUTPUT" 2>&1; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  Lint errors:"
    tail -20 "$LINT_OUTPUT" | sed 's/^/    /'
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
  rm -f "$LINT_OUTPUT"
else
  echo "Check 4: Lint passes... ${YELLOW}⚠${NC} (no lint command configured)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 5: Run type-check
if [[ "$TYPECHECK_CMD" != "null" ]] && [[ -n "$TYPECHECK_CMD" ]]; then
  echo -n "Check 5: Type-check passes... "

  TYPE_OUTPUT=$(mktemp)
  if $TYPECHECK_CMD > "$TYPE_OUTPUT" 2>&1; then
    echo -e "${GREEN}✓${NC}"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "  Type errors:"
    tail -20 "$TYPE_OUTPUT" | sed 's/^/    /'
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
  rm -f "$TYPE_OUTPUT"
else
  echo "Check 5: Type-check passes... ${YELLOW}⚠${NC} (no typecheck command configured)"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

# Check 6: No TODO markers in implementation
echo -n "Check 6: No TODO markers... "

# Find TODO markers in source (excluding node_modules, .git, etc.)
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
  echo "  Found $TODO_COUNT TODO markers:"
  grep -rn "TODO" . \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --include="*.py" --include="*.go" --include="*.rs" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    2>/dev/null | head -5 | sed 's/^/    /'
  if [[ $TODO_COUNT -gt 5 ]]; then
    echo "    ... and $((TODO_COUNT - 5)) more"
  fi
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# Check 7: No console.log in production code
echo -n "Check 7: No console.log statements... "

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
  echo "  Found $CONSOLE_COUNT console.log statements:"
  grep -rn "console\.log" . \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --exclude-dir=tests --exclude-dir=test --exclude="*.test.*" --exclude="*.spec.*" \
    2>/dev/null | head -5 | sed 's/^/    /'
  if [[ $CONSOLE_COUNT -gt 5 ]]; then
    echo "    ... and $((CONSOLE_COUNT - 5)) more"
  fi
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Gate 3 Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [[ $CHECKS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ Gate 3 PASSED${NC}"
  echo ""

  # Set can_advance = true
  if declare -f acquire_lock >/dev/null 2>&1; then
    acquire_lock
    yq eval ".can_advance = true" "$STATE_FILE" -i
    release_lock
  else
    yq eval ".can_advance = true" "$STATE_FILE" -i
  fi

  echo "Ready to advance to Verify stage"
  echo "Run: /spec-drive:feature advance"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Gate 3 FAILED${NC}"
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
