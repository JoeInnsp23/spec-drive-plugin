#!/bin/bash
# test-update-docs.sh
# Unit tests for update-docs.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UPDATE_DOCS_SCRIPT="$PLUGIN_ROOT/scripts/autodocs/update-docs.sh"

if [[ ! -x "$UPDATE_DOCS_SCRIPT" ]]; then
  echo "ERROR: update-docs.sh not found: $UPDATE_DOCS_SCRIPT"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

assert_not_contains() {
  local content="$1"
  local needle="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if ! echo "$content" | grep -qF "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Did not expect to find: $needle"
  fi
}

echo "Running update-docs.sh tests..."
echo ""

# Test 1: Components AUTO section
echo "Test 1: Components AUTO section"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
components:
  - id: "auth-service"
    name: "AuthService"
    type: "class"
    path: "src/auth.ts:10"
EOF

cat > "$TEST_DIR/docs/README.md" << 'EOF'
# Header
<!-- AUTO:components -->
<!-- /AUTO -->
EOF

cd "$TEST_DIR"
"$UPDATE_DOCS_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/docs/README.md")
assert_contains "$CONTENT" "AuthService" "Includes component name"
assert_contains "$CONTENT" "class" "Includes component type"
assert_contains "$CONTENT" "src/auth.ts:10" "Includes component path"

rm -rf "$TEST_DIR"
echo ""

# Test 2: Preserve manual content
echo "Test 2: Preserve manual content"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
components: []
EOF

cat > "$TEST_DIR/docs/README.md" << 'EOF'
Manual before
<!-- AUTO:components -->
Old content
<!-- /AUTO -->
Manual after
EOF

cd "$TEST_DIR"
"$UPDATE_DOCS_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/docs/README.md")
assert_contains "$CONTENT" "Manual before" "Preserves content before AUTO"
assert_contains "$CONTENT" "Manual after" "Preserves content after AUTO"
assert_not_contains "$CONTENT" "Old content" "Replaces old AUTO content"

rm -rf "$TEST_DIR"
echo ""

# Test 3: Specs list
echo "Test 3: Specs list"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
specs:
  - id: "AUTH-001"
    title: "User Authentication"
    status: "implemented"
  - id: "AUTH-002"
    title: "Password Reset"
    status: "draft"
EOF

cat > "$TEST_DIR/docs/SPECS.md" << 'EOF'
<!-- AUTO:specs -->
<!-- /AUTO -->
EOF

cd "$TEST_DIR"
"$UPDATE_DOCS_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/docs/SPECS.md")
assert_contains "$CONTENT" "AUTH-001" "Includes first spec"
assert_contains "$CONTENT" "AUTH-002" "Includes second spec"
assert_contains "$CONTENT" "implemented" "Includes status"

rm -rf "$TEST_DIR"
echo ""

# Test 4: Traceability matrix
echo "Test 4: Traceability matrix"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
specs:
  - id: "TEST-001"
    title: "Test Spec"
    status: "implemented"
    trace:
      code: ["src/test.ts:10"]
      tests: []
      docs: []
EOF

cat > "$TEST_DIR/docs/TRACE.md" << 'EOF'
<!-- AUTO:matrix -->
<!-- /AUTO -->
EOF

cd "$TEST_DIR"
"$UPDATE_DOCS_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/docs/TRACE.md")
assert_contains "$CONTENT" "TEST-001" "Includes spec ID in matrix"
assert_contains "$CONTENT" "✅" "Shows checkmark for existing traces"
assert_contains "$CONTENT" "❌" "Shows X for missing traces"

rm -rf "$TEST_DIR"
echo ""

# Test 5: Multiple AUTO sections in one file
echo "Test 5: Multiple AUTO sections"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
components:
  - id: "comp1"
    name: "Component1"
    type: "class"
    path: "src/comp1.ts:1"
specs:
  - id: "SPEC-001"
    title: "Spec One"
    status: "draft"
EOF

cat > "$TEST_DIR/docs/FULL.md" << 'EOF'
# Full Doc
<!-- AUTO:components -->
<!-- /AUTO -->
Middle content
<!-- AUTO:specs -->
<!-- /AUTO -->
EOF

cd "$TEST_DIR"
"$UPDATE_DOCS_SCRIPT" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

CONTENT=$(cat "$TEST_DIR/docs/FULL.md")
assert_contains "$CONTENT" "Component1" "Updates first AUTO section"
assert_contains "$CONTENT" "SPEC-001" "Updates second AUTO section"
assert_contains "$CONTENT" "Middle content" "Preserves content between sections"

rm -rf "$TEST_DIR"
echo ""

# Test 6: No AUTO markers
echo "Test 6: No AUTO markers"
TEST_DIR=$(mktemp -d)

mkdir -p "$TEST_DIR/.spec-drive" "$TEST_DIR/docs"
cat > "$TEST_DIR/.spec-drive/index.yaml" << 'EOF'
components: []
EOF

cat > "$TEST_DIR/docs/PLAIN.md" << 'EOF'
Plain document without AUTO markers
EOF

cd "$TEST_DIR"
OUTPUT=$("$UPDATE_DOCS_SCRIPT" 2>&1)
cd "$PLUGIN_ROOT"

TESTS_RUN=$((TESTS_RUN + 1))
if echo "$OUTPUT" | grep -q "No AUTO sections found"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Warns when no AUTO markers found"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Warns when no AUTO markers found"
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
