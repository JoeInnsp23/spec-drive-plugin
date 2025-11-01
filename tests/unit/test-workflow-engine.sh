#!/bin/bash
# test-workflow-engine.sh
# Unit tests for workflow-engine.sh state machine
#
# Tests:
#   1. Atomic state transitions (workflow_start)
#   2. can_advance enforcement (workflow_advance blocks)
#   3. History tracking (workflow_complete)
#   4. SPEC-ID validation (reject invalid formats)
#   5. Concurrent access handling (flock prevents corruption)

set -euo pipefail

# Test framework
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test setup
setup_test_env() {
  export TEST_DIR=$(mktemp -d)
  export SPEC_DRIVE_DIR="$TEST_DIR/.spec-drive"
  export STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"
  export STATE_SCHEMA="$SPEC_DRIVE_DIR/schemas/v0.1/state-schema.json"
  export LOCK_FILE="$SPEC_DRIVE_DIR/.state.lock"

  # Create directory structure
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

  # Create minimal state-schema.json (stub for validation)
  cat > "$STATE_SCHEMA" << 'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "current_workflow": {"type": ["string", "null"]},
    "current_spec": {"type": ["string", "null"]},
    "current_stage": {"type": ["string", "null"]},
    "can_advance": {"type": "boolean"},
    "dirty": {"type": "boolean"},
    "workflows": {"type": "object"}
  },
  "required": ["current_workflow", "current_spec", "current_stage", "can_advance", "dirty", "workflows"]
}
EOF

  # Source the workflow engine
  source "$(dirname "$0")/../../scripts/workflows/workflow-engine.sh"
}

# Test teardown
teardown_test_env() {
  rm -rf "$TEST_DIR"
}

# Assert functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  if [[ "$expected" == "$actual" ]]; then
    return 0
  else
    echo -e "${RED}ASSERTION FAILED${NC}: $message"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    return 1
  fi
}

assert_not_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  if [[ "$expected" != "$actual" ]]; then
    return 0
  else
    echo -e "${RED}ASSERTION FAILED${NC}: $message"
    echo "  Expected NOT: $expected"
    echo "  Actual:       $actual"
    return 1
  fi
}

assert_command_fails() {
  local message="${1:-}"
  shift

  if "$@" 2>/dev/null; then
    echo -e "${RED}ASSERTION FAILED${NC}: $message"
    echo "  Command should have failed: $*"
    return 1
  else
    return 0
  fi
}

# Test runner
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -n "Running: $test_name ... "

  # Use temp file for output since exit calls in tests complicate subshell capture
  local output_file=$(mktemp)

  # Run test in subshell, write output to file
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
# Test 1: Atomic State Transitions (workflow_start)
# ==============================================================================
test_workflow_start() {
  # Start workflow
  workflow_start "feature" "AUTH-001" >/dev/null 2>&1

  # Verify state was updated atomically
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local spec=$(yq eval '.current_spec' "$STATE_FILE")
  local stage=$(yq eval '.current_stage' "$STATE_FILE")
  local can_advance=$(yq eval '.can_advance' "$STATE_FILE")

  assert_equals "feature" "$workflow" "current_workflow should be 'feature'" || return 1
  assert_equals "AUTH-001" "$spec" "current_spec should be 'AUTH-001'" || return 1
  assert_equals "discover" "$stage" "current_stage should be 'discover'" || return 1
  assert_equals "false" "$can_advance" "can_advance should be false initially" || return 1
}

# ==============================================================================
# Test 2: can_advance Enforcement (workflow_advance blocks)
# ==============================================================================
test_can_advance_enforcement() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Start workflow
  workflow_start "feature" "AUTH-002" >/dev/null 2>&1

  # Try to advance with can_advance=false (should fail with exit code 2)
  # Must run in subprocess since exit will kill current shell
  # Use || to capture exit code without triggering set -e
  local advance_exit=0
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_advance
  " >/dev/null 2>&1 || advance_exit=$?

  if [[ $advance_exit -ne 2 ]]; then
    echo "ASSERTION FAILED: workflow_advance should have exited with code 2, got $advance_exit"
    return 1
  fi

  # Verify stage did NOT change
  local stage=$(yq eval '.current_stage' "$STATE_FILE")
  assert_equals "discover" "$stage" "Stage should still be 'discover'" || return 1

  # Set can_advance=true
  yq eval '.can_advance = true' "$STATE_FILE" -i

  # Now advance should work
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_advance
  " >/dev/null 2>&1

  # Verify stage changed
  local new_stage=$(yq eval '.current_stage' "$STATE_FILE")
  assert_equals "specify" "$new_stage" "Stage should advance to 'specify'" || return 1

  # Verify can_advance was reset to false
  local can_advance=$(yq eval '.can_advance' "$STATE_FILE")
  assert_equals "false" "$can_advance" "can_advance should be reset to false" || return 1
}

# ==============================================================================
# Test 3: History Tracking (workflow_complete)
# ==============================================================================
test_workflow_complete() {
  # Start workflow
  workflow_start "feature" "AUTH-003" >/dev/null 2>&1

  # Complete workflow
  workflow_complete >/dev/null 2>&1

  # Verify current_* fields are reset
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  local spec=$(yq eval '.current_spec' "$STATE_FILE")
  local stage=$(yq eval '.current_stage' "$STATE_FILE")

  assert_equals "null" "$workflow" "current_workflow should be null after completion" || return 1
  assert_equals "null" "$spec" "current_spec should be null after completion" || return 1
  assert_equals "null" "$stage" "current_stage should be null after completion" || return 1

  # Verify workflow history was added
  local status=$(yq eval '.workflows."AUTH-003".status' "$STATE_FILE")
  local wf_type=$(yq eval '.workflows."AUTH-003".workflow_type' "$STATE_FILE")
  local completed=$(yq eval '.workflows."AUTH-003".completed' "$STATE_FILE")

  assert_equals "done" "$status" "Workflow status should be 'done'" || return 1
  assert_equals "feature" "$wf_type" "Workflow type should be 'feature'" || return 1
  assert_not_equals "null" "$completed" "Completed timestamp should be set" || return 1
}

# ==============================================================================
# Test 4: SPEC-ID Validation
# ==============================================================================
test_spec_id_validation() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Valid formats should work
  workflow_start "feature" "AUTH-001" >/dev/null 2>&1
  workflow_complete >/dev/null 2>&1

  workflow_start "feature" "PROFILE-042" >/dev/null 2>&1
  workflow_complete >/dev/null 2>&1

  # Invalid formats should fail - run in subprocess since they call exit
  local exit_code

  exit_code=0
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_start 'feature' 'auth-001'
  " >/dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "ASSERTION FAILED: Should reject lowercase prefix"
    return 1
  fi

  exit_code=0
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_start 'feature' 'AUTH001'
  " >/dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "ASSERTION FAILED: Should reject missing dash"
    return 1
  fi

  exit_code=0
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_start 'feature' 'AUTH-01'
  " >/dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "ASSERTION FAILED: Should reject short number"
    return 1
  fi

  exit_code=0
  bash -c "
    export SPEC_DRIVE_DIR='$SPEC_DRIVE_DIR'
    export STATE_FILE='$STATE_FILE'
    export STATE_SCHEMA='$STATE_SCHEMA'
    export LOCK_FILE='$LOCK_FILE'
    source '$script_dir/../../scripts/workflows/workflow-engine.sh'
    workflow_start 'feature' 'AUTH-ABC'
  " >/dev/null 2>&1 || exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "ASSERTION FAILED: Should reject non-numeric suffix"
    return 1
  fi

  return 0
}

# ==============================================================================
# Test 5: Concurrent Access Handling (flock prevents corruption)
# ==============================================================================
test_concurrent_access() {
  # Start a workflow
  workflow_start "feature" "AUTH-005" >/dev/null 2>&1

  # Simulate concurrent access by trying to acquire lock while holding it
  # This tests that flock properly serializes access

  # Function to simulate concurrent write
  concurrent_writer() {
    local pid=$$
    # Try to complete workflow (will need lock)
    workflow_complete >/dev/null 2>&1 || true
  }

  # Start background process that will try to complete
  concurrent_writer &
  local bg_pid=$!

  # Main process also tries to complete
  workflow_complete >/dev/null 2>&1 || true

  # Wait for background process
  wait $bg_pid || true

  # Verify state is still valid (not corrupted)
  if ! yq eval '.' "$STATE_FILE" >/dev/null 2>&1; then
    echo "ASSERTION FAILED: state.yaml is corrupted (invalid YAML)"
    return 1
  fi

  # Verify state has expected structure
  local workflow=$(yq eval '.current_workflow' "$STATE_FILE")
  if [[ -z "$workflow" ]]; then
    echo "ASSERTION FAILED: state.yaml missing current_workflow field"
    return 1
  fi

  return 0
}

# ==============================================================================
# Main Test Runner
# ==============================================================================
main() {
  echo "========================================"
  echo "  Workflow Engine Unit Tests"
  echo "========================================"
  echo ""

  # Check dependencies
  if ! command -v yq >/dev/null 2>&1; then
    echo -e "${RED}ERROR${NC}: yq is required but not installed"
    exit 1
  fi

  # Run tests
  run_test "Test 1: Atomic state transitions (workflow_start)" test_workflow_start
  run_test "Test 2: can_advance enforcement (workflow_advance blocks)" test_can_advance_enforcement
  run_test "Test 3: History tracking (workflow_complete)" test_workflow_complete
  run_test "Test 4: SPEC-ID validation" test_spec_id_validation
  run_test "Test 5: Concurrent access handling (flock)" test_concurrent_access

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
