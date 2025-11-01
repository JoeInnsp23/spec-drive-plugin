#!/bin/bash
# test-feature.sh
# Integration test for feature workflow
#
# Tests:
#   1. Feature start (discover stage)
#   2. Spec creation and validation
#   3. Stage transitions (discover → specify → implement → verify)
#   4. Workflow completion

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

  # Create minimal config.yaml (for test command)
  cat > "$SPEC_DRIVE_DIR/config.yaml" << 'EOF'
project:
  name: "test-project"
tools:
  test_command: "echo 'Tests pass'"
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
# Test 1: Feature start creates spec (discover stage)
# ==============================================================================
test_feature_start() {
  local discover_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/discover.sh"

  # Create mock input
  {
    echo "User authentication feature"
    echo "medium"
  } | "$discover_script" "User Authentication" >/dev/null 2>&1 || true

  # Check spec was created
  local spec_files=(.spec-drive/specs/*.yaml)
  if [[ ! -f "${spec_files[0]}" ]]; then
    echo "ASSERTION FAILED: No spec file created"
    return 1
  fi

  local spec_id=$(yq eval '.spec_id' "${spec_files[0]}")

  # Validate spec format
  if [[ ! "$spec_id" =~ ^[A-Z]+-[0-9]{3}$ ]]; then
    echo "ASSERTION FAILED: Invalid SPEC-ID format: $spec_id"
    return 1
  fi

  # Check workflow state
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local current_spec=$(yq eval '.current_spec' "$STATE_FILE")
  local stage=$(yq eval '.current_stage' "$STATE_FILE")

  if [[ "$workflow" != "feature" ]]; then
    echo "ASSERTION FAILED: workflow should be 'feature', got '$workflow'"
    return 1
  fi

  if [[ "$current_spec" != "$spec_id" ]]; then
    echo "ASSERTION FAILED: current_spec should be '$spec_id', got '$current_spec'"
    return 1
  fi

  if [[ "$stage" != "discover" ]]; then
    echo "ASSERTION FAILED: stage should be 'discover', got '$stage'"
    return 1
  fi

  return 0
}

# ==============================================================================
# Test 2: Specify stage requires acceptance criteria
# ==============================================================================
test_specify_stage() {
  local discover_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/discover.sh"
  local specify_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/specify.sh"
  local engine_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/workflow-engine.sh"

  # Source engine
  source "$engine_script"

  # Create spec via discover
  {
    echo "Test feature"
    echo "medium"
  } | "$discover_script" "Test Feature" >/dev/null 2>&1 || true

  # Get spec ID
  local spec_id=$(yq eval '.current_spec' "$STATE_FILE")
  local spec_file=".spec-drive/specs/$spec_id.yaml"

  # Advance to specify
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    source '$engine_script'
    workflow_advance
  " >/dev/null 2>&1 || true

  # Try specify without criteria (should fail)
  echo "N" | "$specify_script" >/dev/null 2>&1 || true

  local can_advance=$(yq eval '.can_advance' "$STATE_FILE")
  if [[ "$can_advance" == "true" ]]; then
    echo "ASSERTION FAILED: Should not be able to advance without criteria"
    return 1
  fi

  # Add criteria
  yq eval '.acceptance_criteria += ["User can log in"]' "$spec_file" -i

  # Try specify again (should pass)
  echo "N" | "$specify_script" >/dev/null 2>&1 || true

  can_advance=$(yq eval '.can_advance' "$STATE_FILE")
  if [[ "$can_advance" != "true" ]]; then
    echo "ASSERTION FAILED: Should be able to advance with criteria"
    return 1
  fi

  return 0
}

# ==============================================================================
# Test 3: Complete workflow (all 4 stages)
# ==============================================================================
test_complete_workflow() {
  local discover_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/discover.sh"
  local specify_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/specify.sh"
  local implement_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/implement.sh"
  local verify_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/feature/verify.sh"
  local engine_script="$CLAUDE_PLUGIN_ROOT/scripts/workflows/workflow-engine.sh"

  # Source engine
  source "$engine_script"

  # Stage 1: Discover
  {
    echo "Complete workflow test"
    echo "high"
  } | "$discover_script" "Complete Test" >/dev/null 2>&1 || true

  local spec_id=$(yq eval '.current_spec' "$STATE_FILE")
  local spec_file=".spec-drive/specs/$spec_id.yaml"

  # Stage 2: Specify
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    source '$engine_script'
    workflow_advance
  " >/dev/null 2>&1 || true

  # Add criteria
  yq eval '.acceptance_criteria += ["Criterion 1", "Criterion 2"]' "$spec_file" -i

  echo "N" | "$specify_script" >/dev/null 2>&1 || true

  # Stage 3: Implement
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    source '$engine_script'
    workflow_advance
  " >/dev/null 2>&1 || true

  # Create mock implementation with @spec tag
  mkdir -p src tests
  echo "// @spec $spec_id" > src/test.js
  echo "function test() { return true; }" >> src/test.js

  # Create test file with @spec tag (required by Gate 3)
  echo "// @spec $spec_id" > tests/test.test.js
  echo "test('should work', () => { expect(true).toBe(true); });" >> tests/test.test.js

  echo "Y" | "$implement_script" >/dev/null 2>&1 || true

  # Stage 4: Verify
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    source '$engine_script'
    workflow_advance
  " >/dev/null 2>&1 || true

  "$verify_script" >/dev/null 2>&1 || true

  # Check workflow completed
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  if [[ "$workflow" != "null" ]]; then
    echo "ASSERTION FAILED: Workflow should be null after completion, got '$workflow'"
    return 1
  fi

  # Check spec status
  local status=$(yq eval '.status' "$spec_file")
  if [[ "$status" != "implemented" ]]; then
    echo "ASSERTION FAILED: Spec status should be 'implemented', got '$status'"
    return 1
  fi

  # Check traceability
  local trace_count=$(yq eval '.traces.code | length' "$spec_file")
  if [[ $trace_count -lt 1 ]]; then
    echo "ASSERTION FAILED: Should have at least 1 traced file"
    return 1
  fi

  return 0
}

# ==============================================================================
# Main Test Runner
# ==============================================================================
main() {
  echo "========================================"
  echo "  Feature Workflow Integration Tests"
  echo "========================================"
  echo ""

  # Check dependencies
  if ! command -v yq >/dev/null 2>&1; then
    echo -e "${RED}ERROR${NC}: yq is required but not installed"
    exit 1
  fi

  # Run tests
  run_test "Test 1: Feature start creates spec (discover)" test_feature_start
  run_test "Test 2: Specify stage requires acceptance criteria" test_specify_stage
  run_test "Test 3: Complete workflow (all 4 stages)" test_complete_workflow

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
