#!/bin/bash
# test-app-new.sh
# Integration test for app-new workflow
#
# Tests:
#   1. planning-session.sh creates APP-001 spec
#   2. generate-docs.sh creates documentation
#   3. run.sh orchestrates full workflow
#   4. State is initialized correctly

set -euo pipefail

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test setup
setup_test_env() {
  export TEST_DIR=$(mktemp -d)
  export SPEC_DRIVE_DIR="$TEST_DIR/.spec-drive"
  export STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
  export CLAUDE_PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

  echo "Test environment: $TEST_DIR"

  # Create minimal .spec-drive structure
  mkdir -p "$SPEC_DRIVE_DIR/specs"
  mkdir -p "$SPEC_DRIVE_DIR/schemas/v0.1"

  # Create minimal state.yaml
  cat > "$STATE_FILE" << 'EOF'
current_workflow: null
current_spec: null
current_stage: null
can_advance: false
dirty: false
workflows: {}
EOF

  # Create minimal state schema
  cat > "$SPEC_DRIVE_DIR/schemas/v0.1/state-schema.json" << 'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object"
}
EOF

  # Create minimal SPECS-INDEX.yaml
  cat > "$SPEC_DRIVE_DIR/SPECS-INDEX.yaml" << 'EOF'
version: "0.1"
updated: "2025-11-01T00:00:00Z"
specs: []
docs: []
meta:
  total_specs: 0
  total_docs: 0
EOF

  # Change to test directory
  cd "$TEST_DIR"
}

# Test teardown
teardown_test_env() {
  if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test runner
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -n "Running: $test_name ... "

  # Use temp file for output
  local output_file=$(mktemp)

  # Run test in subshell
  (
    setup_test_env
    $test_func
    local result=$?
    teardown_test_env
    exit $result
  ) > "$output_file" 2>&1

  local test_exit=$?
  local test_output=$(cat "$output_file")
  rm -f "$output_file"

  # Check result
  if [[ $test_exit -eq 0 ]] && ! echo "$test_output" | grep -q "ASSERTION FAILED"; then
    echo -e "${GREEN}PASSED${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}FAILED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    if [[ -n "$test_output" ]]; then
      echo "$test_output"
    fi
  fi
}

# ==============================================================================
# Test 1: planning-session.sh creates APP-001 spec
# ==============================================================================
test_planning_session() {
  local script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/app-new/planning-session.sh"

  # Create test inputs
  echo "Test project vision" > /tmp/test-vision.txt
  echo "Feature 1" > /tmp/test-features.txt
  echo "Test users" > /tmp/test-users.txt
  echo "Node.js, React" > /tmp/test-stack.txt

  # Run planning session with mocked input
  {
    echo "Test project vision"
    echo "Feature 1"
    echo ""
    echo "Test users"
    echo "Node.js, React"
  } | "$script" "test-app" >/dev/null 2>&1 || true

  # Check APP-001 created
  if [[ ! -f ".spec-drive/specs/APP-001.yaml" ]]; then
    echo "ASSERTION FAILED: APP-001 spec not created"
    return 1
  fi

  # Check spec contains project name
  if ! grep -q "test-app" ".spec-drive/specs/APP-001.yaml"; then
    echo "ASSERTION FAILED: APP-001 does not contain project name"
    return 1
  fi

  # Check SPECS-INDEX updated
  local spec_count=$(yq eval '.specs | length' ".spec-drive/SPECS-INDEX.yaml")
  if [[ "$spec_count" -ne 1 ]]; then
    echo "ASSERTION FAILED: SPECS-INDEX should have 1 spec, got $spec_count"
    return 1
  fi

  return 0
}

# ==============================================================================
# Test 2: generate-docs.sh creates documentation
# ==============================================================================
test_generate_docs() {
  local planning_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/app-new/planning-session.sh"
  local docs_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/app-new/generate-docs.sh"

  # First run planning session to create APP-001
  {
    echo "Test project"
    echo "Feature 1"
    echo ""
    echo "Test users"
    echo "Node.js"
  } | "$planning_script" "test-app" >/dev/null 2>&1 || true

  # Run generate-docs
  if ! "$docs_script" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: generate-docs.sh failed"
    return 1
  fi

  # Check docs/ directory created
  if [[ ! -d "docs" ]]; then
    echo "ASSERTION FAILED: docs/ directory not created"
    return 1
  fi

  # Check at least some docs were created
  local doc_count=$(find docs -name "*.md" | wc -l)
  if [[ $doc_count -lt 3 ]]; then
    echo "ASSERTION FAILED: Expected at least 3 docs, got $doc_count"
    return 1
  fi

  # Check SPECS-INDEX updated with docs
  local index_doc_count=$(yq eval '.docs | length' ".spec-drive/SPECS-INDEX.yaml")
  if [[ $index_doc_count -lt 1 ]]; then
    echo "ASSERTION FAILED: SPECS-INDEX should have docs"
    return 1
  fi

  return 0
}

# ==============================================================================
# Test 3: Full workflow state initialization
# ==============================================================================
test_workflow_state() {
  local planning_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/app-new/planning-session.sh"
  local docs_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/app-new/generate-docs.sh"
  local engine_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/workflow-engine.sh"

  # Source workflow engine
  source "$engine_script"

  # Run planning + docs
  {
    echo "Test project"
    echo "Feature 1"
    echo ""
    echo "Test users"
    echo "Node.js"
  } | "$planning_script" "test-app" >/dev/null 2>&1 || true

  "$docs_script" >/dev/null 2>&1 || true

  # Initialize workflow
  workflow_start "app-new" "APP-001" >/dev/null 2>&1

  # Check state
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local spec=$(yq eval '.current_spec' "$STATE_FILE")
  local stage=$(yq eval '.current_stage' "$STATE_FILE")

  if [[ "$workflow" != "app-new" ]]; then
    echo "ASSERTION FAILED: workflow should be 'app-new', got '$workflow'"
    return 1
  fi

  if [[ "$spec" != "APP-001" ]]; then
    echo "ASSERTION FAILED: spec should be 'APP-001', got '$spec'"
    return 1
  fi

  if [[ "$stage" != "discover" ]]; then
    echo "ASSERTION FAILED: stage should be 'discover', got '$stage'"
    return 1
  fi

  return 0
}

# ==============================================================================
# Main Test Runner
# ==============================================================================
main() {
  echo "========================================"
  echo "  app-new Workflow Integration Tests"
  echo "========================================"
  echo ""

  # Check dependencies
  if ! command -v yq >/dev/null 2>&1; then
    echo -e "${RED}ERROR${NC}: yq is required but not installed"
    exit 1
  fi

  # Run tests
  run_test "Test 1: planning-session creates APP-001 spec" test_planning_session
  run_test "Test 2: generate-docs creates documentation" test_generate_docs
  run_test "Test 3: Workflow state initialization" test_workflow_state

  # Summary
  echo ""
  echo "========================================"
  echo "  Test Summary"
  echo "========================================"
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
  fi
}

# Run tests
main "$@"
