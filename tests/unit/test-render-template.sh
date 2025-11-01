#!/bin/bash
# test-render-template.sh
# Unit tests for render-template.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script under test
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RENDER_TEMPLATE="$SCRIPT_DIR/../../scripts/tools/render-template.sh"

# Test fixtures directory
FIXTURES_DIR="$SCRIPT_DIR/../fixtures"
mkdir -p "$FIXTURES_DIR"

# Cleanup function
cleanup() {
  rm -rf "$FIXTURES_DIR"
}
trap cleanup EXIT

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if grep -q "$pattern" "$file"; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  File $file does not contain: $pattern"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_command_succeeds() {
  local test_name="$1"
  shift
  local cmd="$@"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$cmd" &>/dev/null; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command failed: $cmd"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_command_fails() {
  local test_name="$1"
  shift
  local cmd="$@"

  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$cmd" &>/dev/null; then
    echo -e "${RED}✗${NC} $test_name"
    echo "  Command should have failed: $cmd"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

# ============================================
# TEST 1: Basic Variable Substitution
# ============================================
test_basic_substitution() {
  echo -e "\n${YELLOW}Test 1: Basic Variable Substitution${NC}"

  # Create test template
  cat > "$FIXTURES_DIR/basic.template" << 'EOF'
Project: {{PROJECT_NAME}}
Version: {{VERSION}}
Author: {{AUTHOR}}
EOF

  # Render template
  "$RENDER_TEMPLATE" \
    --template "$FIXTURES_DIR/basic.template" \
    --output "$FIXTURES_DIR/basic.out" \
    --var PROJECT_NAME="test-app" \
    --var VERSION="1.0.0" \
    --var AUTHOR="Test User"

  # Verify output
  assert_file_contains "$FIXTURES_DIR/basic.out" "Project: test-app" "PROJECT_NAME substituted"
  assert_file_contains "$FIXTURES_DIR/basic.out" "Version: 1.0.0" "VERSION substituted"
  assert_file_contains "$FIXTURES_DIR/basic.out" "Author: Test User" "AUTHOR substituted"
}

# ============================================
# TEST 2: Missing Variable Error
# ============================================
test_missing_variable() {
  echo -e "\n${YELLOW}Test 2: Missing Variable Error${NC}"

  # Create test template with undefined variable
  cat > "$FIXTURES_DIR/missing.template" << 'EOF'
Project: {{PROJECT_NAME}}
Missing: {{UNDEFINED_VAR}}
EOF

  # Should fail with error about undefined variable
  assert_command_fails \
    "Undefined variable causes error" \
    "$RENDER_TEMPLATE --template $FIXTURES_DIR/missing.template --output $FIXTURES_DIR/missing.out --var PROJECT_NAME=test"
}

# ============================================
# TEST 3: AUTO Marker Detection
# ============================================
test_auto_markers() {
  echo -e "\n${YELLOW}Test 3: AUTO Marker Detection${NC}"

  # Create template with AUTO markers
  cat > "$FIXTURES_DIR/auto.template" << 'EOF'
# Documentation

Manual section before AUTO

<!-- AUTO:generated -->
This content is generated: {{VERSION}}
<!-- /AUTO -->

Manual section after AUTO
EOF

  # Render template (first time)
  "$RENDER_TEMPLATE" \
    --template "$FIXTURES_DIR/auto.template" \
    --output "$FIXTURES_DIR/auto.out" \
    --var VERSION="1.0.0"

  # Verify AUTO section was generated
  assert_file_contains "$FIXTURES_DIR/auto.out" "This content is generated: 1.0.0" "AUTO section rendered with variable"
  assert_file_contains "$FIXTURES_DIR/auto.out" "Manual section before AUTO" "Manual content before AUTO preserved"
  assert_file_contains "$FIXTURES_DIR/auto.out" "Manual section after AUTO" "Manual content after AUTO preserved"
}

# ============================================
# TEST 4: Content Preservation
# ============================================
test_content_preservation() {
  echo -e "\n${YELLOW}Test 4: Content Preservation${NC}"

  # Create initial template with AUTO marker
  cat > "$FIXTURES_DIR/preserve.template" << 'EOF'
# Documentation

<!-- AUTO:version -->
Version: {{VERSION}}
<!-- /AUTO -->
EOF

  # First render
  "$RENDER_TEMPLATE" \
    --template "$FIXTURES_DIR/preserve.template" \
    --output "$FIXTURES_DIR/preserve.out" \
    --var VERSION="1.0.0"

  # Manually edit the output (add content outside AUTO section)
  cat > "$FIXTURES_DIR/preserve.out" << 'EOF'
# Documentation

This is my manual addition before AUTO!

<!-- AUTO:version -->
Version: 1.0.0
<!-- /AUTO -->

This is my manual addition after AUTO!
EOF

  # Re-render with new version (should preserve manual additions)
  "$RENDER_TEMPLATE" \
    --template "$FIXTURES_DIR/preserve.template" \
    --output "$FIXTURES_DIR/preserve.out" \
    --var VERSION="2.0.0"

  # Verify manual content preserved and AUTO section updated
  assert_file_contains "$FIXTURES_DIR/preserve.out" "This is my manual addition before AUTO!" "Manual content before AUTO preserved"
  assert_file_contains "$FIXTURES_DIR/preserve.out" "This is my manual addition after AUTO!" "Manual content after AUTO preserved"
  assert_file_contains "$FIXTURES_DIR/preserve.out" "Version: 2.0.0" "AUTO section updated with new variable"
}

# ============================================
# TEST 5: Error Cases
# ============================================
test_error_cases() {
  echo -e "\n${YELLOW}Test 5: Error Cases${NC}"

  # Missing template file
  assert_command_fails \
    "Missing template file causes error" \
    "$RENDER_TEMPLATE --template /nonexistent/file.template --output $FIXTURES_DIR/out.txt"

  # Missing required arguments
  assert_command_fails \
    "Missing --template argument causes error" \
    "$RENDER_TEMPLATE --output $FIXTURES_DIR/out.txt"

  assert_command_fails \
    "Missing --output argument causes error" \
    "$RENDER_TEMPLATE --template $FIXTURES_DIR/basic.template"

  # Invalid --var format
  assert_command_fails \
    "Invalid --var format causes error" \
    "$RENDER_TEMPLATE --template $FIXTURES_DIR/basic.template --output $FIXTURES_DIR/out.txt --var BADFORMAT"
}

# ============================================
# RUN ALL TESTS
# ============================================

echo "================================================"
echo "  render-template.sh Unit Tests"
echo "================================================"

test_basic_substitution
test_missing_variable
test_auto_markers
test_content_preservation
test_error_cases

# Print summary
echo ""
echo "================================================"
echo "  Test Results"
echo "================================================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "================================================"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
