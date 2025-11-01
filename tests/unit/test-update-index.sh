#!/bin/bash
# test-update-index.sh
# Unit tests for update-index.sh

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UPDATE_INDEX_SCRIPT="$PLUGIN_ROOT/scripts/autodocs/update-index.sh"

# Verify script exists
if [[ ! -x "$UPDATE_INDEX_SCRIPT" ]]; then
  echo "ERROR: update-index.sh not found: $UPDATE_INDEX_SCRIPT"
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
assert_file_exists() {
  local file="$1"
  local test_name="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$file" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    File not found: $file"
  fi
}

assert_yaml_valid() {
  local file="$1"
  local test_name="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if yq eval '.' "$file" >/dev/null 2>&1; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
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

echo "Running update-index.sh tests..."
echo ""

# Test 1: Basic index generation
echo "Test 1: Basic index generation"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

mkdir -p "$TEST_DIR/src" "$TEST_DIR/.spec-drive"
cat > "$TEST_DIR/src/example.ts" << 'EOF'
export class Example {}
EOF

cd "$TEST_DIR"
"$UPDATE_INDEX_SCRIPT" 2>&1 >/dev/null
assert_file_exists ".spec-drive/index.yaml" "Creates index.yaml"
assert_yaml_valid ".spec-drive/index.yaml" "Generates valid YAML"
cd - >/dev/null
echo ""

# Test 2: Component detection
echo "Test 2: Component detection"
TEST_DIR2=$(mktemp -d)
trap "rm -rf $TEST_DIR2" EXIT

mkdir -p "$TEST_DIR2/src" "$TEST_DIR2/.spec-drive"
cat > "$TEST_DIR2/src/auth.ts" << 'EOF'
export class AuthService {}
export function login() {}
EOF

cd "$TEST_DIR2"
"$UPDATE_INDEX_SCRIPT" 2>&1 >/dev/null

COMPONENT_COUNT=$(yq eval '.components | length' .spec-drive/index.yaml)
assert_equals "2" "$COMPONENT_COUNT" "Detects 2 components"

FIRST_ID=$(yq eval '.components[0].id' .spec-drive/index.yaml)
assert_equals "auth-service" "$FIRST_ID" "Generates correct component ID"
cd - >/dev/null
echo ""

# Test 3: Spec and trace integration
echo "Test 3: Spec and trace integration"
TEST_DIR3=$(mktemp -d)
trap "rm -rf $TEST_DIR3" EXIT

mkdir -p "$TEST_DIR3/src" "$TEST_DIR3/.spec-drive/specs"
cat > "$TEST_DIR3/src/feature.ts" << 'EOF'
/** @spec FEAT-001 */
export function doSomething() {}
EOF

cat > "$TEST_DIR3/.spec-drive/specs/FEAT-001.yaml" << 'EOF'
spec_id: FEAT-001
title: "Test Feature"
type: feature
status: draft
EOF

cd "$TEST_DIR3"
"$UPDATE_INDEX_SCRIPT" 2>&1 >/dev/null

SPEC_COUNT=$(yq eval '.specs | length' .spec-drive/index.yaml)
assert_equals "1" "$SPEC_COUNT" "Includes spec"

CODE_TRACES=$(yq eval '.specs[0].trace.code | length' .spec-drive/index.yaml 2>/dev/null || echo "0")
if [[ "$CODE_TRACES" -gt 0 ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Links code traces to spec"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Links code traces to spec"
fi
cd - >/dev/null
echo ""

# Test 4: Documentation scanning
echo "Test 4: Documentation scanning"
TEST_DIR4=$(mktemp -d)
trap "rm -rf $TEST_DIR4" EXIT

mkdir -p "$TEST_DIR4/docs/00-overview" "$TEST_DIR4/.spec-drive"
cat > "$TEST_DIR4/docs/00-overview/README.md" << 'EOF'
# Project Overview
EOF

cd "$TEST_DIR4"
"$UPDATE_INDEX_SCRIPT" 2>&1 >/dev/null

DOC_COUNT=$(yq eval '.docs | length' .spec-drive/index.yaml)
assert_equals "1" "$DOC_COUNT" "Scans documentation"

DOC_TYPE=$(yq eval '.docs[0].type' .spec-drive/index.yaml)
assert_equals "overview" "$DOC_TYPE" "Classifies doc type correctly"
cd - >/dev/null
echo ""

# Test 5: Metadata generation
echo "Test 5: Metadata generation"
TEST_DIR5=$(mktemp -d)
trap "rm -rf $TEST_DIR5" EXIT

mkdir -p "$TEST_DIR5/.spec-drive"
cat > "$TEST_DIR5/package.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.2.3"
}
EOF

cd "$TEST_DIR5"
"$UPDATE_INDEX_SCRIPT" 2>&1 >/dev/null

PROJECT_NAME=$(yq eval '.meta.project_name' .spec-drive/index.yaml)
assert_equals "test-project" "$PROJECT_NAME" "Reads project name from package.json"

VERSION=$(yq eval '.meta.version' .spec-drive/index.yaml)
assert_equals "1.2.3" "$VERSION" "Reads version from package.json"

GENERATED=$(yq eval '.meta.generated' .spec-drive/index.yaml)
if [[ -n "$GENERATED" ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} Sets generated timestamp"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} Sets generated timestamp"
fi
cd - >/dev/null
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
