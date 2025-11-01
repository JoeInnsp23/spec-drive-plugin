#!/bin/bash
# test-scan-spec-tags.sh
# Unit tests for scan-spec-tags.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCAN_SCRIPT="$PLUGIN_ROOT/scripts/autodocs/scan-spec-tags.sh"

# Verify scan script exists
if [[ ! -x "$SCAN_SCRIPT" ]]; then
  echo "ERROR: Scan script not found or not executable: $SCAN_SCRIPT"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# Test Framework
# ==============================================================================

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$haystack" | grep -q "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected to find: $needle"
    echo "    In: $haystack"
  fi
}

assert_json_valid() {
  local json="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if echo "$json" | jq '.' >/dev/null 2>&1; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Invalid JSON"
  fi
}

# ==============================================================================
# Test Cases
# ==============================================================================

echo "Running scan-spec-tags.sh tests..."
echo ""

# Create test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test 1: TypeScript JSDoc format
echo "Test 1: TypeScript JSDoc format"
mkdir -p "$TEST_DIR/src"
cat > "$TEST_DIR/src/auth.ts" << 'EOF'
/** @spec AUTH-001 */
export function login() {}
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_json_valid "$OUTPUT" "Output is valid JSON"
assert_contains "$OUTPUT" '"AUTH-001"' "Detects AUTH-001"
assert_contains "$OUTPUT" 'auth.ts:1' "Records correct file:line"
echo ""

# Test 2: Single-line comment format
echo "Test 2: Single-line comment formats"
cat > "$TEST_DIR/src/util.ts" << 'EOF'
// @spec UTIL-001
export function formatDate() {}
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_contains "$OUTPUT" '"UTIL-001"' "Detects UTIL-001 from // comment"
echo ""

# Test 3: Python hash comment
echo "Test 3: Python hash comment"
cat > "$TEST_DIR/src/helper.py" << 'EOF'
# @spec HELP-001
def calculate():
    pass
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_contains "$OUTPUT" '"HELP-001"' "Detects HELP-001 from # comment"
echo ""

# Test 4: Python docstring
echo "Test 4: Python docstring"
cat > "$TEST_DIR/src/parser.py" << 'EOF'
"""@spec PARSE-001"""
def parse_data():
    pass
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_contains "$OUTPUT" '"PARSE-001"' "Detects PARSE-001 from docstring"
echo ""

# Test 5: Code vs Test classification
echo "Test 5: Code vs Test classification"
mkdir -p "$TEST_DIR/tests"
cat > "$TEST_DIR/tests/auth.test.ts" << 'EOF'
/** @spec AUTH-001 */
test('login works', () => {});
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
CODE_COUNT=$(echo "$OUTPUT" | jq '.traces."AUTH-001".code | length')
TEST_COUNT=$(echo "$OUTPUT" | jq '.traces."AUTH-001".tests | length')
assert_equals "1" "$CODE_COUNT" "AUTH-001 has 1 code trace"
assert_equals "1" "$TEST_COUNT" "AUTH-001 has 1 test trace"
echo ""

# Test 6: Invalid SPEC-ID format (should be ignored)
echo "Test 6: Invalid SPEC-ID validation"
cat > "$TEST_DIR/src/invalid.ts" << 'EOF'
// @spec lowercase-001
// @spec TOO-1
// @spec VALID-123
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_contains "$OUTPUT" '"VALID-123"' "Accepts valid SPEC-ID"
if echo "$OUTPUT" | jq -e '.traces."lowercase-001"' >/dev/null 2>&1; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Rejects lowercase prefix"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Rejects lowercase prefix"
fi
if echo "$OUTPUT" | jq -e '.traces."TOO-1"' >/dev/null 2>&1; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Rejects insufficient digits"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Rejects insufficient digits"
fi
echo ""

# Test 7: Multiple tags on same line
echo "Test 7: Multiple tags on same line"
cat > "$TEST_DIR/src/multi.sh" << 'EOF'
# @spec MULTI-001 @spec MULTI-002
echo "test"
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_contains "$OUTPUT" '"MULTI-001"' "Detects first tag on line"
assert_contains "$OUTPUT" '"MULTI-002"' "Detects second tag on line"
MULTI1_LINE=$(echo "$OUTPUT" | jq -r '.traces."MULTI-001".code[0]' | grep -o ':[0-9]*$')
MULTI2_LINE=$(echo "$OUTPUT" | jq -r '.traces."MULTI-002".code[0]' | grep -o ':[0-9]*$')
assert_equals "$MULTI1_LINE" "$MULTI2_LINE" "Both tags have same line number"
echo ""

# Test 8: Output to file
echo "Test 8: Output to file"
OUTPUT_FILE="$TEST_DIR/output.json"
"$SCAN_SCRIPT" --dir "$TEST_DIR" --output "$OUTPUT_FILE" 2>/dev/null
if [[ -f "$OUTPUT_FILE" ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Creates output file"
  FILE_CONTENT=$(cat "$OUTPUT_FILE")
  assert_json_valid "$FILE_CONTENT" "Output file contains valid JSON"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Creates output file"
fi
echo ""

# Test 9: Test file classification heuristics
echo "Test 9: Test file classification heuristics"
mkdir -p "$TEST_DIR/src/__tests__"
cat > "$TEST_DIR/src/__tests__/unit.spec.js" << 'EOF'
// @spec TEST-001
test('works', () => {});
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
TEST_COUNT=$(echo "$OUTPUT" | jq '.traces."TEST-001".tests | length')
CODE_COUNT=$(echo "$OUTPUT" | jq '.traces."TEST-001".code | length')
assert_equals "1" "$TEST_COUNT" "Classifies __tests__/ as test"
assert_equals "0" "$CODE_COUNT" "Does not classify as code"
echo ""

# Test 10: Bash script in scripts/ directory
echo "Test 10: Bash scripts classification"
mkdir -p "$TEST_DIR/scripts"
cat > "$TEST_DIR/scripts/deploy.sh" << 'EOF'
#!/bin/bash
# @spec DEPLOY-001
echo "deploy"
EOF

OUTPUT=$("$SCAN_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
CODE_COUNT=$(echo "$OUTPUT" | jq '.traces."DEPLOY-001".code | length')
assert_equals "1" "$CODE_COUNT" "Classifies scripts/ as code"
echo ""

# ==============================================================================
# Summary
# ==============================================================================

echo "================================"
echo "Test Summary"
echo "================================"
echo "Total:  $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
