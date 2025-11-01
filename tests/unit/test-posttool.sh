#!/bin/bash
# test-posttool.sh
# Unit tests for posttool.sh hook handler

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_SCRIPT="$PLUGIN_ROOT/hooks-handlers/posttool.sh"

if [[ ! -x "$HOOK_SCRIPT" ]]; then
  echo "ERROR: posttool.sh not found or not executable: $HOOK_SCRIPT"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
  local actual="$1"
  local expected="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$actual" == "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected: $expected"
    echo "    Got: $actual"
  fi
}

assert_contains() {
  local content="$1"
  local needle="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$content" | grep -qF "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected to find: $needle"
  fi
}

assert_file_exists() {
  local file_path="$1"
  local test_name="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$file_path" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    File not found: $file_path"
  fi
}

echo "Running posttool.sh tests..."
echo ""

# Test 1: Skip if not a spec-drive project
echo "Test 1: Skip if not a spec-drive project"
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

OUTPUT=$(TOOL_NAME="Write" "$HOOK_SCRIPT" 2>&1)
EXIT_CODE=$?

cd "$PLUGIN_ROOT"
assert_equals "$EXIT_CODE" "0" "Returns exit code 0"
assert_contains "$OUTPUT" '"hookEventName": "PostToolUse"' "Returns valid JSON"

rm -rf "$TEST_DIR"
echo ""

# Test 2: Create state.yaml if missing
echo "Test 2: Create state.yaml if missing"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"

cd "$TEST_DIR"
TOOL_NAME="Write" "$HOOK_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

assert_file_exists "$TEST_DIR/.spec-drive/state.yaml" "Creates state.yaml"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty:" "Contains dirty field"

rm -rf "$TEST_DIR"
echo ""

# Test 3: Set dirty flag for Write tool
echo "Test 3: Set dirty flag for Write tool"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
dirty: false
last_update: null
EOF

cd "$TEST_DIR"
TOOL_NAME="Write" "$HOOK_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty: true" "Sets dirty to true for Write"

rm -rf "$TEST_DIR"
echo ""

# Test 4: Set dirty flag for Edit tool
echo "Test 4: Set dirty flag for Edit tool"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
dirty: false
last_update: null
EOF

cd "$TEST_DIR"
TOOL_NAME="Edit" "$HOOK_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty: true" "Sets dirty to true for Edit"

rm -rf "$TEST_DIR"
echo ""

# Test 5: Set dirty flag for Delete tool
echo "Test 5: Set dirty flag for Delete tool"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
dirty: false
last_update: null
EOF

cd "$TEST_DIR"
TOOL_NAME="Delete" "$HOOK_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty: true" "Sets dirty to true for Delete"

rm -rf "$TEST_DIR"
echo ""

# Test 6: Don't set dirty flag for other tools
echo "Test 6: Don't set dirty flag for other tools"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
dirty: false
last_update: null
EOF

cd "$TEST_DIR"
TOOL_NAME="Read" "$HOOK_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty: false" "Keeps dirty as false for Read"

rm -rf "$TEST_DIR"
echo ""

# Test 7: Handle missing yq gracefully
echo "Test 7: Handle missing yq gracefully"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
dirty: false
last_update: null
EOF

cd "$TEST_DIR"
# Temporarily hide yq from PATH
PATH="/usr/bin:/bin" TOOL_NAME="Write" "$HOOK_SCRIPT" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"

assert_equals "$EXIT_CODE" "0" "Returns exit code 0 without yq"

CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$CONTENT" "dirty: true" "Sets dirty even without yq (fallback)"

rm -rf "$TEST_DIR"
echo ""

# Test 8: Returns valid JSON
echo "Test 8: Returns valid JSON"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"

cd "$TEST_DIR"
OUTPUT=$(TOOL_NAME="Write" "$HOOK_SCRIPT" 2>&1)
cd "$PLUGIN_ROOT"

TESTS_RUN=$((TESTS_RUN + 1))
if echo "$OUTPUT" | jq . >/dev/null 2>&1; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Returns valid JSON"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Returns valid JSON"
  echo "    Invalid JSON: $OUTPUT"
fi

rm -rf "$TEST_DIR"
echo ""

# Test 9: Performance (<100ms)
echo "Test 9: Performance (<100ms)"
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive"

cd "$TEST_DIR"
START=$(date +%s%N)
TOOL_NAME="Write" "$HOOK_SCRIPT" >/dev/null 2>&1
END=$(date +%s%N)
cd "$PLUGIN_ROOT"

DURATION_MS=$(( (END - START) / 1000000 ))

TESTS_RUN=$((TESTS_RUN + 1))
if [[ $DURATION_MS -lt 100 ]]; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Runs in <100ms (${DURATION_MS}ms)"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Runs in <100ms (${DURATION_MS}ms)"
fi

rm -rf "$TEST_DIR"
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
