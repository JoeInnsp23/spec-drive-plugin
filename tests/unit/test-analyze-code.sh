#!/bin/bash
# test-analyze-code.sh
# Unit tests for analyze-code.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANALYZE_SCRIPT="$PLUGIN_ROOT/scripts/autodocs/analyze-code.sh"

# Verify script exists
if [[ ! -x "$ANALYZE_SCRIPT" ]]; then
  echo "ERROR: Analyze script not found: $ANALYZE_SCRIPT"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework
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
  fi
}

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
    echo "    Expected: $expected, Got: $actual"
  fi
}

echo "Running analyze-code.sh tests..."
echo ""

# Create test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Test 1: TypeScript class detection
echo "Test 1: TypeScript class detection"
mkdir -p "$TEST_DIR/src"
cat > "$TEST_DIR/src/Service.ts" << 'EOF'
export class AuthService {
  login() {}
}
EOF

OUTPUT=$("$ANALYZE_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
assert_json_valid "$OUTPUT" "Output is valid JSON"
assert_contains "$OUTPUT" '"auth-service"' "Detects AuthService class"
assert_contains "$OUTPUT" '"type": "class"' "Identifies as class type"
echo ""

# Test 2: Function detection
echo "Test 2: Function detection"
TEST_DIR2=$(mktemp -d)
trap "rm -rf $TEST_DIR2" EXIT
mkdir -p "$TEST_DIR2/src"
cat > "$TEST_DIR2/src/utils.ts" << 'EOF'
export function validateEmail(email: string) {
  return email.includes('@');
}
EOF

OUTPUT=$("$ANALYZE_SCRIPT" --dir "$TEST_DIR2" 2>/dev/null)
assert_contains "$OUTPUT" '"validate-email"' "Detects validateEmail function"
assert_contains "$OUTPUT" '"type": "function"' "Identifies as function type"
echo ""

# Test 3: Python class detection
echo "Test 3: Python class detection"
TEST_DIR3=$(mktemp -d)
trap "rm -rf $TEST_DIR3" EXIT
mkdir -p "$TEST_DIR3/src"
cat > "$TEST_DIR3/src/logger.py" << 'EOF'
class DatabaseClient:
    def connect(self):
        pass
EOF

OUTPUT=$("$ANALYZE_SCRIPT" --dir "$TEST_DIR3" 2>/dev/null)
assert_contains "$OUTPUT" '"database-client"' "Detects Python class"
echo ""

# Test 4: Combined component count
echo "Test 4: Combined component count"
cat > "$TEST_DIR/src/utils.ts" << 'EOF'
export function validateEmail(email: string) {
  return email.includes('@');
}
EOF
cat > "$TEST_DIR/src/logger.py" << 'EOF'
class DatabaseClient:
    def connect(self):
        pass
EOF

OUTPUT=$("$ANALYZE_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
COMPONENT_COUNT=$(echo "$OUTPUT" | jq '.components | length')
assert_equals "3" "$COMPONENT_COUNT" "Finds all 3 components"
echo ""

# Test 5: Excludes test files
echo "Test 5: Excludes test files"
mkdir -p "$TEST_DIR/tests"
cat > "$TEST_DIR/tests/auth.test.ts" << 'EOF'
export class TestHelper {
  setup() {}
}
EOF

OUTPUT=$("$ANALYZE_SCRIPT" --dir "$TEST_DIR" 2>/dev/null)
if echo "$OUTPUT" | jq -e '.components[] | select(.id == "test-helper")' >/dev/null 2>&1; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Excludes test files"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Excludes test files"
fi
echo ""

# Test 6: Output to file
echo "Test 6: Output to file"
OUTPUT_FILE="$TEST_DIR/components.json"
"$ANALYZE_SCRIPT" --dir "$TEST_DIR/src" --output "$OUTPUT_FILE" 2>/dev/null
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

# Summary
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
