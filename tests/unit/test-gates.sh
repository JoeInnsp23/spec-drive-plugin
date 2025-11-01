#!/bin/bash
# test-gates.sh
# Unit tests for quality gate scripts

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_exit_code() {
  local actual="$1"
  local expected="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$actual" -eq "$expected" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected exit code: $expected, got: $actual"
  fi
}

echo "Running quality gate tests..."
echo ""

# ============================================================================
# Gate 1: Discover Tests
# ============================================================================
echo "Gate 1: Discover Tests"

# Test 1.1: Fails when spec file doesn't exist
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-001"
stage: "discover"
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-1-discover.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "1" "Fails when spec file missing"

# Test 1.2: Passes with valid spec
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-001"
stage: "discover"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-001.yaml" << 'EOF'
id: TEST-001
title: "Test Feature"
description: "This is a test description with enough content to pass validation"
status: "draft"
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-1-discover.sh" >/dev/null 2>&1
EXIT_CODE=$?
CAN_ADVANCE=$(yq eval '.can_advance' ".spec-drive/state.yaml" 2>/dev/null || echo "false")
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "0" "Passes with valid spec"
TESTS_RUN=$((TESTS_RUN + 1))
if [[ "$CAN_ADVANCE" == "true" ]]; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Sets can_advance=true"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Sets can_advance=true (got: $CAN_ADVANCE)"
fi

echo ""

# ============================================================================
# Gate 2: Specify Tests
# ============================================================================
echo "Gate 2: Specify Tests"

# Test 2.1: Fails without acceptance criteria
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-002"
stage: "specify"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-002.yaml" << 'EOF'
id: TEST-002
title: "Test Feature"
description: "Test description"
status: "draft"
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-2-specify.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "1" "Fails without acceptance criteria"

# Test 2.2: Passes with valid spec
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-004"
stage: "specify"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-004.yaml" << 'EOF'
id: TEST-004
title: "Test Feature"
description: "Clear description"
status: "draft"
acceptance_criteria:
  - "Given valid input, when user submits, then success"
  - "Given invalid input, when user submits, then error"
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-2-specify.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "0" "Passes with valid spec and ACs"

echo ""

# ============================================================================
# Gate 3: Implement Tests
# ============================================================================
echo "Gate 3: Implement Tests"

# Test 3.1: Fails without @spec tags
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs" "$TEST_DIR/src"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-005"
stage: "implement"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-005.yaml" << 'EOF'
id: TEST-005
title: "Test"
EOF

cat > "$TEST_DIR/src/feature.ts" << 'EOF'
export function doSomething() {}
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-3-implement.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "1" "Fails without @spec tags"

# Test 3.2: Passes with valid implementation
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs" "$TEST_DIR/src" "$TEST_DIR/tests"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-007"
stage: "implement"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-007.yaml" << 'EOF'
id: TEST-007
title: "Test"
EOF

cat > "$TEST_DIR/src/feature.ts" << 'EOF'
// @spec TEST-007
export function doSomething() {
  return true;
}
EOF

cat > "$TEST_DIR/tests/feature.test.ts" << 'EOF'
// @spec TEST-007
test('does something', () => {
  expect(doSomething()).toBe(true);
});
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-3-implement.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "0" "Passes with valid implementation"

echo ""

# ============================================================================
# Gate 4: Verify Tests
# ============================================================================
echo "Gate 4: Verify Tests"

# Test 4.1: Fails without traceability
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-008"
stage: "verify"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-008.yaml" << 'EOF'
id: TEST-008
title: "Test"
status: "implemented"
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-4-verify.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "1" "Fails without traceability index"

# Test 4.2: Passes with complete traceability
TEST_DIR=$(mktemp -d)
mkdir -p "$TEST_DIR/.spec-drive/specs" "$TEST_DIR/src" "$TEST_DIR/tests"
cat > "$TEST_DIR/.spec-drive/state.yaml" << 'EOF'
current_spec: "TEST-009"
stage: "verify"
EOF

cat > "$TEST_DIR/.spec-drive/specs/TEST-009.yaml" << 'EOF'
id: TEST-009
title: "Test"
status: "implemented"
acceptance_criteria:
  - "Works correctly"
EOF

cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
specs:
  - id: "TEST-009"
    title: "Test"
    status: "implemented"
    trace:
      code: ["src/feature.ts:1"]
      tests: ["tests/feature.test.ts:1"]
      docs: []
EOF

cat > "$TEST_DIR/src/feature.ts" << 'EOF'
// @spec TEST-009
export function test() {}
EOF

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/gates/gate-4-verify.sh" >/dev/null 2>&1
EXIT_CODE=$?
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

assert_exit_code "$EXIT_CODE" "0" "Passes with complete traceability"

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "================================"
echo "Test Summary"
echo "================================"
echo "Total:  $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All gate tests passed!${NC}"
  exit 0
else
  echo -e "${RED}✗ Some gate tests failed${NC}"
  exit 1
fi
