# spec-drive v0.1 Test Plan

**Version:** 0.1.0
**Target Release:** TBD
**Last Updated:** 2025-11-01
**Status:** Planning Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Test Strategy](#test-strategy)
3. [Test Levels](#test-levels)
4. [Coverage Goals](#coverage-goals)
5. [Critical Test Scenarios](#critical-test-scenarios)
6. [Test Environment Setup](#test-environment-setup)
7. [Test Data Management](#test-data-management)
8. [Regression Testing](#regression-testing)
9. [Performance Testing](#performance-testing)
10. [Platform Testing](#platform-testing)
11. [Security Testing](#security-testing)
12. [Test Automation](#test-automation)
13. [Test Execution Schedule](#test-execution-schedule)
14. [Test Metrics & Reporting](#test-metrics--reporting)
15. [Exit Criteria](#exit-criteria)

---

## Overview

### Purpose

This test plan defines the testing strategy, approach, and requirements for spec-drive v0.1. It ensures comprehensive validation of all systems (behavior optimization, autodocs, spec-driven workflows, quality gates) before release.

### Scope

**In Scope:**
- All Phase 1-5 implementations (Foundation, Workflows, Autodocs, Gates, Integration)
- Unit tests for all scripts and modules
- Integration tests for end-to-end workflows
- Platform compatibility tests (Linux, macOS)
- Performance tests (large codebases)
- Regression tests (prevent breakage)

**Out of Scope (v0.2+):**
- Multi-developer concurrent workflows
- Web UI testing
- Windows platform support
- Load testing (multi-user scenarios)

### Test Objectives

1. **Functional Correctness** - All features work as specified
2. **Reliability** - System handles errors gracefully, no data corruption
3. **Performance** - Meets performance targets (analysis <30s, autodocs <60s)
4. **Platform Compatibility** - Works on Linux and macOS
5. **Usability** - Clear error messages, intuitive workflows
6. **Security** - No secrets leaked, safe file operations

---

## Test Strategy

### Testing Approach

**Test-Driven Development (TDD):**
- Write tests before implementation (where feasible)
- Red → Green → Refactor cycle
- Tests as specification (executable documentation)

**Test Pyramid:**
```
        /\
       /E2E\       ← 10% (integration tests, full workflows)
      /------\
     /Integration\ ← 30% (component integration, APIs)
    /------------\
   /   Unit Tests \ ← 60% (individual functions, scripts)
  /----------------\
```

**Testing Phases:**

1. **Development Phase** (continuous)
   - Unit tests written alongside implementation
   - Developer runs tests locally before commit
   - CI runs tests on every push

2. **Integration Phase** (end of each implementation phase)
   - Integration tests for phase deliverables
   - Smoke tests for critical paths
   - Platform tests (Linux, macOS)

3. **System Phase** (end of Phase 5)
   - End-to-end workflow tests
   - Performance tests (large codebases)
   - Regression test suite (full run)
   - User acceptance scenarios

4. **Release Phase** (before v0.1 release)
   - Final regression run (all tests)
   - Platform validation (all supported platforms)
   - Documentation validation (test all examples)
   - Release candidate testing (full workflows on fresh projects)

### Test Priorities

**P0 (Critical)** - Must pass for release:
- Core workflows (app-new, feature)
- State management (no corruption)
- Quality gates (enforcement)
- Data validation (schemas)

**P1 (High)** - Should pass for release:
- Autodocs (code analysis, index generation)
- Template rendering (AUTO sections)
- Platform compatibility (Linux, macOS)
- Error handling (graceful failures)

**P2 (Medium)** - Nice to have:
- Performance optimization
- Edge case handling
- User experience polish
- Error message clarity

**P3 (Low)** - Future enhancements:
- Advanced features (parallel workflows)
- Optimization (caching, parallelization)
- Additional platforms (Windows)

---

## Test Levels

### 1. Unit Tests

**Purpose:** Validate individual functions, scripts, and modules in isolation.

**Scope:**
- All shell scripts (bash functions)
- All JavaScript/Node.js modules
- Template rendering logic
- State management functions
- Schema validation
- Code analysis parsers

**Framework:**
- Bash: `bats` (Bash Automated Testing System)
- JavaScript: `jest` or `mocha`

**Coverage Target:** 80% line coverage, 90% branch coverage

**Example Unit Tests:**

```bash
# tests/unit/workflow-engine.bats
@test "workflow_start sets current_workflow correctly" {
  # Setup
  ./scripts/tools/init-state.sh

  # Execute
  ./scripts/workflows/workflow-engine.sh start --workflow feature --spec AUTH-001

  # Assert
  result=$(yq eval '.current_workflow' .spec-drive/state.yaml)
  [ "$result" = "feature" ]
}

@test "workflow_advance checks can_advance flag" {
  # Setup
  yq eval '.can_advance = false' -i .spec-drive/state.yaml

  # Execute & Assert
  run ./scripts/workflows/workflow-engine.sh advance
  [ "$status" -eq 1 ]  # Should fail
  [[ "$output" =~ "Cannot advance" ]]
}
```

```javascript
// tests/unit/analyze-code.test.js
describe('Component Detection', () => {
  test('detects TypeScript classes', () => {
    const code = `
      export class AuthService {
        login() {}
      }
    `;
    const components = analyzeCode(code, 'typescript');
    expect(components).toHaveLength(1);
    expect(components[0].id).toBe('auth-service');
    expect(components[0].type).toBe('class');
  });

  test('detects Python functions', () => {
    const code = `
      def authenticate_user(username, password):
          pass
    `;
    const components = analyzeCode(code, 'python');
    expect(components).toHaveLength(1);
    expect(components[0].id).toBe('authenticate-user');
    expect(components[0].type).toBe('function');
  });
});
```

**Unit Test Checklist:**
- [ ] Template rendering (render-template.sh)
- [ ] Workflow state machine (workflow-engine.sh)
- [ ] Config generation (generate-config.sh)
- [ ] State initialization (init-state.sh)
- [ ] Index initialization (init-index.sh)
- [ ] Component detection (analyze-code.js)
- [ ] @spec tag scanning (scan-spec-tags.js)
- [ ] Dependency mapping (map-dependencies.js)
- [ ] Index population (index-docs.js)
- [ ] Doc update (update-docs.js)
- [ ] Gate runner (run-gate.sh)
- [ ] Gate 1-4 scripts (gate-1.sh through gate-4.sh)

---

### 2. Integration Tests

**Purpose:** Validate interactions between components, subsystems, and external tools.

**Scope:**
- Workflow orchestration (stage transitions)
- Autodocs trigger (PostToolUse hook → index update → doc update)
- Gate enforcement (gate fail → can_advance=false → advance blocked)
- Template + directory scaffolding integration
- Schema validation integration (ajv + YAML files)

**Framework:** Bash scripts with test harness

**Coverage Target:** 100% critical paths

**Example Integration Tests:**

```bash
# tests/integration/test-workflow-gates.sh
test_gate_blocks_invalid_transition() {
  # Setup: Initialize project
  ./scripts/commands/spec-drive-app-new.sh --defaults

  # Start feature workflow
  ./scripts/commands/spec-drive-feature.sh --start --title "Test Feature"

  # Try to advance without meeting gate-1 requirements
  # (no acceptance criteria added yet)
  ./scripts/commands/spec-drive-feature.sh --advance

  # Assert: Advance should be blocked
  assert_equals "$?" "1"  # Exit code 1 (failure)

  can_advance=$(yq eval '.can_advance' .spec-drive/state.yaml)
  assert_equals "$can_advance" "false"

  stage=$(yq eval '.current_stage' .spec-drive/state.yaml)
  assert_equals "$stage" "discover"  # Still in discover stage
}

test_gate_allows_valid_transition() {
  # Setup: Create valid spec with acceptance criteria
  ./scripts/commands/spec-drive-feature.sh --start --title "Test Feature"
  yq eval '.acceptance_criteria += [{"criterion": "Test passes", "testable": true}]' \
    -i .spec-drive/specs/TEST-001.yaml

  # Run gate manually
  ./scripts/gates/run-gate.sh --gate 1 --spec TEST-001

  # Assert: Gate passes, can_advance set to true
  can_advance=$(yq eval '.can_advance' .spec-drive/state.yaml)
  assert_equals "$can_advance" "true"

  # Advance to next stage
  ./scripts/commands/spec-drive-feature.sh --advance

  stage=$(yq eval '.current_stage' .spec-drive/state.yaml)
  assert_equals "$stage" "specify"  # Advanced successfully
}
```

**Integration Test Checklist:**
- [ ] app-new workflow (planning → doc generation)
- [ ] feature workflow (4 stages: discover → specify → implement → verify → done)
- [ ] Workflow + gates integration (gates block invalid transitions)
- [ ] Autodocs trigger (PostToolUse → index → docs)
- [ ] Template + config integration (variable substitution)
- [ ] Schema validation integration (all YAML files validate)
- [ ] State persistence (atomic writes, corruption prevention)
- [ ] Index population (code analysis → index.yaml)
- [ ] Doc update (index.yaml → AUTO sections)
- [ ] Existing project init (analysis → specs → docs)

---

### 3. End-to-End (E2E) Tests

**Purpose:** Validate complete user workflows from start to finish.

**Scope:**
- Full app-new workflow (new project creation)
- Full feature workflow (discover → done)
- Existing project initialization
- Multi-feature development (sequential features)

**Framework:** Bash scripts simulating user interactions

**Coverage Target:** All user-facing workflows

**Example E2E Tests:**

```bash
# tests/e2e/test-new-project-complete.sh
test_complete_new_project_workflow() {
  echo "=== Test: Complete New Project Workflow ==="

  # Step 1: Initialize new project
  echo "Step 1: Running app-new..."
  ./scripts/commands/spec-drive-app-new.sh \
    --project-name "test-app" \
    --version "0.1.0" \
    --description "Test application" \
    --tech-stack "TypeScript, React" \
    --key-features "Authentication, User profiles"

  assert_success "app-new failed"
  assert_file_exists ".spec-drive/config.yaml"
  assert_file_exists "docs/README.md"
  assert_file_exists ".spec-drive/specs/APP-001.yaml"

  # Step 2: Start first feature
  echo "Step 2: Starting feature workflow..."
  ./scripts/commands/spec-drive-feature.sh --start --title "User authentication"

  spec_id=$(yq eval '.current_spec' .spec-drive/state.yaml)
  assert_equals "$spec_id" "AUTH-001"

  # Step 3: Add acceptance criteria (specify stage)
  echo "Step 3: Adding acceptance criteria..."
  yq eval '.acceptance_criteria += [
    {"criterion": "User can log in with email/password", "testable": true},
    {"criterion": "User receives JWT token on success", "testable": true}
  ]' -i .spec-drive/specs/AUTH-001.yaml

  # Step 4: Advance to implement stage
  echo "Step 4: Advancing to implement..."
  ./scripts/commands/spec-drive-feature.sh --advance

  stage=$(yq eval '.current_stage' .spec-drive/state.yaml)
  assert_equals "$stage" "implement"

  # Step 5: Mock implementation (create code + tests)
  echo "Step 5: Mocking implementation..."
  mkdir -p src/auth tests/auth
  cat > src/auth/login.ts <<EOF
/** @spec AUTH-001 */
export class AuthService {
  async login(email: string, password: string): Promise<string> {
    // Mock implementation
    return "mock-jwt-token";
  }
}
EOF

  cat > tests/auth/login.test.ts <<EOF
/** @spec AUTH-001 */
import { AuthService } from '../../src/auth/login';

test('login returns JWT token', async () => {
  const auth = new AuthService();
  const token = await auth.login('test@example.com', 'password');
  expect(token).toBe('mock-jwt-token');
});
EOF

  # Step 6: Advance to verify stage
  echo "Step 6: Advancing to verify..."
  # (mock: test command passes)
  echo "exit 0" > scripts/mock-test.sh
  chmod +x scripts/mock-test.sh
  yq eval '.tools.test_command = "./scripts/mock-test.sh"' -i .spec-drive/config.yaml

  ./scripts/commands/spec-drive-feature.sh --advance

  stage=$(yq eval '.current_stage' .spec-drive/state.yaml)
  assert_equals "$stage" "verify"

  # Step 7: Complete workflow
  echo "Step 7: Completing workflow..."
  # (mock: create feature doc)
  mkdir -p docs/60-features
  echo "# AUTH-001: User authentication" > docs/60-features/AUTH-001.md

  ./scripts/commands/spec-drive-feature.sh --advance

  # Assert: Workflow complete
  status=$(yq eval '.workflows.AUTH-001.status' .spec-drive/state.yaml)
  assert_equals "$status" "done"

  current_workflow=$(yq eval '.current_workflow' .spec-drive/state.yaml)
  assert_equals "$current_workflow" "null"

  echo "✅ Complete new project workflow test PASSED"
}
```

**E2E Test Checklist:**
- [ ] New project creation (app-new → docs generated)
- [ ] Single feature development (AUTH-001: discover → done)
- [ ] Multiple features (AUTH-001 → PROFILE-001 sequential)
- [ ] Existing project initialization (legacy code → specs + docs)
- [ ] Autodocs regeneration (code change → docs updated)
- [ ] Gate failure recovery (gate fails → fix → retry)
- [ ] Workflow abandonment (start feature → abandon → clean state)

---

### 4. System Tests

**Purpose:** Validate system-level behaviors, configurations, and edge cases.

**Scope:**
- Error handling (missing files, invalid YAML, corrupted state)
- Configuration validation (invalid config.yaml)
- Edge cases (empty codebase, no tests, no acceptance criteria)
- Platform-specific behaviors (Linux vs macOS)

**Framework:** Bash scripts with error injection

**Example System Tests:**

```bash
# tests/system/test-error-handling.sh
test_corrupted_state_recovery() {
  # Setup: Initialize project
  ./scripts/commands/spec-drive-app-new.sh --defaults

  # Corrupt state.yaml (invalid YAML)
  echo "invalid: yaml: syntax:" > .spec-drive/state.yaml

  # Execute: Try to run workflow command
  run ./scripts/commands/spec-drive-feature.sh --status

  # Assert: Should detect corruption and fail gracefully
  assert_failure
  assert_output_contains "state.yaml is corrupted"
  assert_output_contains "Run /spec-drive:reset-state to recover"
}

test_missing_dependencies() {
  # Simulate missing yq
  PATH="/bin:/usr/bin" run ./scripts/tools/init-state.sh

  # Assert: Should detect missing dependency
  assert_failure
  assert_output_contains "yq not found"
  assert_output_contains "Install yq"
}
```

**System Test Checklist:**
- [ ] Corrupted state.yaml (invalid YAML, missing fields)
- [ ] Corrupted config.yaml (invalid values, missing required fields)
- [ ] Missing dependencies (yq, jq, ajv, node)
- [ ] File permission errors (read-only .spec-drive/)
- [ ] Disk space errors (no space for docs/)
- [ ] Concurrent modifications (two terminals, same workflow)
- [ ] Large codebases (1000+ files, performance)
- [ ] Empty codebase (no code to analyze)
- [ ] Platform differences (Linux vs macOS path handling)

---

## Coverage Goals

### Code Coverage Targets

**Unit Test Coverage:**
- **Line Coverage:** 80% minimum, 90% target
- **Branch Coverage:** 90% minimum, 95% target
- **Function Coverage:** 100% (all exported functions tested)

**Integration Test Coverage:**
- **Critical Paths:** 100% (all user workflows tested)
- **API Boundaries:** 100% (all script interfaces tested)
- **Error Paths:** 90% (most error scenarios tested)

**E2E Test Coverage:**
- **User Workflows:** 100% (all documented workflows tested)
- **Happy Paths:** 100% (all success scenarios)
- **Error Recovery:** 80% (major error scenarios)

### Coverage Measurement

**Tools:**
- Bash: `kcov` (coverage for bash scripts)
- JavaScript: `jest --coverage` or `nyc` (istanbul)

**Reporting:**
- Coverage reports generated after each test run
- CI publishes coverage to dashboard (codecov.io or similar)
- Coverage trend tracked over time (should not decrease)

**Coverage Exceptions:**
- Logging/debugging code (not critical)
- Error messages (strings)
- Platform-specific fallbacks (tested manually)

---

## Critical Test Scenarios

### Scenario 1: New Project Creation

**Description:** User creates a new project from scratch.

**Steps:**
1. Run `/spec-drive:app-new`
2. Answer planning questions (project vision, features, stack)
3. Verify docs/ generated (12 documents)
4. Verify .spec-drive/ created (config, state, index, schemas)
5. Verify APP-001 spec created
6. Verify index.yaml populated
7. Verify config.yaml valid

**Expected Results:**
- All 12 docs exist and valid markdown
- .spec-drive/ structure complete
- APP-001 spec has status=draft
- state.yaml shows workflow=app-new, status=done
- No errors or warnings

**Priority:** P0 (Critical)

---

### Scenario 2: Feature Development (Happy Path)

**Description:** User develops a feature through all 4 stages.

**Steps:**
1. Start feature: `/spec-drive:feature --start --title "User login"`
2. Discover stage: Spec created (AUTH-001)
3. Add acceptance criteria (manual edit)
4. Advance to specify: `/spec-drive:feature --advance` (gate-1 passes)
5. Implement code + tests with @spec tags
6. Advance to verify: `/spec-drive:feature --advance` (gate-3 passes)
7. Create feature doc (docs/60-features/AUTH-001.md)
8. Complete: `/spec-drive:feature --advance` (gate-4 passes)

**Expected Results:**
- Spec AUTH-001 created with status progression: draft → specified → implemented → verified → done
- All gates pass at appropriate stages
- index.yaml shows traceability (code, tests, docs)
- docs/ AUTO sections updated
- state.yaml shows workflow complete

**Priority:** P0 (Critical)

---

### Scenario 3: Gate Blocks Invalid Transition

**Description:** User tries to advance without meeting gate requirements.

**Steps:**
1. Start feature (AUTH-001)
2. Try to advance without adding acceptance criteria
3. Gate-1 runs, fails (no acceptance criteria)
4. Verify can_advance=false
5. Try to force advance: `/spec-drive:feature --advance`
6. Verify advance blocked

**Expected Results:**
- Gate-1 fails with clear error message ("acceptance_criteria is empty")
- can_advance=false in state.yaml
- Advance command blocked (exit code 1)
- Current stage remains "discover"
- User sees actionable error message

**Priority:** P0 (Critical)

---

### Scenario 4: Autodocs Regeneration

**Description:** Code changes trigger autodocs update.

**Steps:**
1. Initialize project (app-new)
2. Create feature (AUTH-001)
3. Add code file with @spec tag (src/auth/login.ts)
4. dirty flag set (PostToolUse hook)
5. Advance to verify stage (triggers autodocs)
6. Verify index.yaml updated (component detected, trace added)
7. Verify docs/ AUTO sections regenerated (README, ARCHITECTURE, TRACEABILITY)
8. Verify dirty flag cleared

**Expected Results:**
- index.yaml has new component entry (auth-service)
- index.yaml specs[AUTH-001].trace.code has src/auth/login.ts:N
- docs/README.md AUTO section lists auth-service
- docs/90-reference/TRACEABILITY.md shows AUTH-001 → code/tests/docs links
- dirty=false in state.yaml

**Priority:** P0 (Critical)

---

### Scenario 5: Existing Project Initialization

**Description:** User initializes spec-drive on existing codebase.

**Steps:**
1. Create mock legacy codebase (10 files, no docs)
2. Run `/spec-drive:init-existing` (or script equivalent)
3. Confirm archive existing docs (if any)
4. Deep code analysis runs (components detected)
5. Specs auto-generated (COMP-001, COMP-002, ...)
6. Docs generated (12 documents)
7. index.yaml populated from analysis

**Expected Results:**
- Old docs/ archived to docs-archive-{timestamp}/
- New docs/ created with 12 documents
- Components detected (at least 5)
- Specs auto-generated (one per major component)
- index.yaml populated (components, specs, code, docs)
- AUTO sections have real data (not placeholders)

**Priority:** P1 (High)

---

### Scenario 6: Multiple Features Sequential

**Description:** User develops 3 features in sequence.

**Steps:**
1. Create project (app-new)
2. Feature 1: AUTH-001 (discover → done)
3. Feature 2: PROFILE-001 (discover → done)
4. Feature 3: SESSION-001 (discover → done)
5. Verify state.yaml history tracks all 3
6. Verify index.yaml has all 3 specs
7. Verify traceability complete for all

**Expected Results:**
- state.yaml workflows object has 3 entries (AUTH-001, PROFILE-001, SESSION-001)
- All 3 specs have status=done
- index.yaml specs array has 3 entries
- Traceability complete (code, tests, docs) for all 3
- No state corruption or conflicts

**Priority:** P1 (High)

---

### Scenario 7: Performance (Large Codebase)

**Description:** Autodocs on large codebase (1000+ files).

**Steps:**
1. Generate mock codebase (1000 files, 10k LOC)
2. Run code analysis (analyze-code.js)
3. Measure time (should be <30 seconds)
4. Run autodocs (index-docs + update-docs)
5. Measure time (should be <60 seconds)
6. Measure memory (should be <500MB)

**Expected Results:**
- Analysis completes in <30 seconds
- Autodocs completes in <60 seconds
- Memory usage <500MB
- All components detected (no timeouts)
- index.yaml valid (no truncation)

**Priority:** P1 (High)

---

### Scenario 8: Gate Failure Recovery

**Description:** User fixes issues after gate failure.

**Steps:**
1. Start feature (AUTH-001)
2. Try to advance (gate-1 fails: no acceptance criteria)
3. Add acceptance criteria (fix issue)
4. Re-run gate manually: `/spec-drive:gate --gate 1 --spec AUTH-001`
5. Gate passes, can_advance=true
6. Advance successfully

**Expected Results:**
- Gate failure shows clear error message
- User fixes issue (adds acceptance criteria)
- Re-running gate succeeds
- can_advance flag updated
- Advance proceeds to next stage

**Priority:** P1 (High)

---

### Scenario 9: Workflow Abandonment

**Description:** User starts feature, then abandons it.

**Steps:**
1. Start feature (AUTH-001)
2. Abandon: `/spec-drive:feature --abandon`
3. Verify state reset (current_workflow=null)
4. Verify spec marked abandoned
5. Start new feature (PROFILE-001)
6. Verify clean state (no interference from AUTH-001)

**Expected Results:**
- state.yaml current_workflow=null
- state.yaml workflows.AUTH-001.status=abandoned
- New feature (PROFILE-001) starts cleanly
- No state corruption or leftover data

**Priority:** P2 (Medium)

---

### Scenario 10: Platform Compatibility

**Description:** All workflows work on Linux and macOS.

**Steps:**
1. Run full test suite on Ubuntu 22.04
2. Run full test suite on macOS 14
3. Verify all tests pass on both platforms
4. Verify no platform-specific failures

**Expected Results:**
- All tests pass on Ubuntu 22.04
- All tests pass on macOS 14
- No bash compatibility issues (bash 4 vs 3)
- No path handling differences (/ vs ~)
- No tool version issues (yq, jq)

**Priority:** P1 (High)

---

## Test Environment Setup

### Local Development Environment

**Prerequisites:**
- Operating System: Linux (Ubuntu 22.04+) or macOS (13+)
- Shell: bash 4.0+ (Linux) or bash 3.2+ / zsh (macOS)
- Node.js: v18+ (for JavaScript scripts)
- Tools:
  - `yq` v4+ (YAML processor)
  - `jq` v1.6+ (JSON processor)
  - `ajv-cli` (JSON Schema validator)
  - `bats` (Bash testing framework)
  - `kcov` (bash coverage tool)

**Setup Steps:**

```bash
# Install dependencies (Ubuntu)
sudo apt-get update
sudo apt-get install -y nodejs npm jq
sudo snap install yq
npm install -g ajv-cli bats kcov

# Install dependencies (macOS)
brew install node jq yq bats-core kcov

# Clone repository
git clone https://github.com/your-org/spec-drive-plugin.git
cd spec-drive-plugin

# Install npm dependencies
npm install

# Run test suite
./tests/run-all-tests.sh
```

### CI/CD Environment

**Platform:** GitHub Actions (or GitLab CI, CircleCI)

**Test Matrix:**
- Ubuntu 22.04 (bash 5.1)
- Ubuntu 24.04 (bash 5.2)
- macOS 13 (bash 3.2 / zsh)
- macOS 14 (bash 3.2 / zsh)

**CI Workflow:**

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test-linux:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: sudo snap install yq
      - run: sudo apt-get install -y jq
      - run: npm install -g ajv-cli bats kcov
      - run: npm install
      - run: ./tests/run-all-tests.sh
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  test-macos:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: brew install jq yq bats-core kcov
      - run: npm install -g ajv-cli
      - run: npm install
      - run: ./tests/run-all-tests.sh
```

### Test Data Repositories

**Location:** `tests/fixtures/`

**Contents:**
- `mock-codebases/` - Sample codebases for testing
  - `simple-ts/` - Small TypeScript project (10 files)
  - `large-ts/` - Large TypeScript project (1000 files)
  - `python-fastapi/` - Python FastAPI project
  - `legacy-no-tests/` - Legacy codebase (no tests, no docs)
- `mock-specs/` - Sample spec YAML files
- `mock-configs/` - Sample config.yaml files
- `expected-outputs/` - Expected output files for comparison

---

## Test Data Management

### Test Data Strategy

**Approach:** Generate test data dynamically, avoid committing large fixtures.

**Test Data Types:**

1. **Minimal Fixtures** (committed to repo)
   - Small sample specs (5-10 examples)
   - Small sample codebases (3-5 files each)
   - Template examples

2. **Generated Data** (created during test runs)
   - Large codebases (1000+ files) - generated by script
   - Mock implementations (code, tests) - generated per test
   - State files - created fresh for each test

3. **Ephemeral Data** (cleaned up after tests)
   - Temp directories (mktemp -d)
   - Test projects (created in /tmp)
   - Coverage reports (archived, then deleted)

### Test Data Cleanup

**Strategy:** Each test cleans up after itself.

```bash
# Test template
test_example() {
  # Setup: Create isolated environment
  local test_dir=$(mktemp -d)
  cd "$test_dir"

  # Execute test
  # ...

  # Cleanup: Always runs (even on failure)
  cd - > /dev/null
  rm -rf "$test_dir"
}
```

**CI Cleanup:** CI deletes all test artifacts after run (except coverage reports).

---

## Regression Testing

### Regression Test Suite

**Purpose:** Ensure new changes don't break existing functionality.

**Scope:** All P0 and P1 test scenarios.

**Execution:** Run on every commit (CI), before every release.

**Regression Test Catalog:**

| Test ID | Scenario | Priority | Frequency |
|---------|----------|----------|-----------|
| REG-001 | New project creation | P0 | Every commit |
| REG-002 | Feature workflow (full cycle) | P0 | Every commit |
| REG-003 | Gate enforcement | P0 | Every commit |
| REG-004 | Autodocs regeneration | P0 | Every commit |
| REG-005 | Existing project init | P1 | Every commit |
| REG-006 | Multiple features sequential | P1 | Daily |
| REG-007 | Performance (large codebase) | P1 | Weekly |
| REG-008 | Platform compatibility | P1 | Before release |
| REG-009 | Gate failure recovery | P1 | Every commit |
| REG-010 | Workflow abandonment | P2 | Daily |

### Regression Detection

**Baseline:** Capture "golden" outputs for critical scenarios.

**Comparison:** Compare test outputs against baseline.

**Failure Handling:**
1. Test fails → CI fails
2. Investigate: Bug or expected change?
3. If bug: Fix immediately
4. If expected: Update baseline (with approval)

**Baseline Updates:** Require manual approval (PR review).

---

## Performance Testing

### Performance Targets

| Operation | Target | Acceptable | Max |
|-----------|--------|------------|-----|
| Code analysis (1000 files) | <20s | <30s | 60s |
| Autodocs (1000 files) | <40s | <60s | 120s |
| Template rendering | <1s | <2s | 5s |
| State update | <100ms | <200ms | 500ms |
| Gate execution | <5s | <10s | 30s |
| Schema validation | <100ms | <500ms | 1s |

### Performance Test Scenarios

**Test 1: Large Codebase Analysis**
- Input: 1000 TypeScript files (10k LOC)
- Operation: analyze-code.js
- Measure: Time, memory, CPU

**Test 2: Autodocs Full Regeneration**
- Input: 1000 files, 50 specs, 12 docs
- Operation: index-docs.js + update-docs.js
- Measure: Time, memory

**Test 3: Incremental Autodocs**
- Input: 1000 files (only 10 changed)
- Operation: index-docs.js (incremental)
- Measure: Time (should be <10s)

**Test 4: State Update Concurrency**
- Input: 100 parallel state updates
- Operation: workflow-engine.sh (concurrent calls)
- Measure: No corruption, all updates succeed

### Performance Benchmarking

**Tool:** `hyperfine` (command-line benchmarking)

```bash
# Benchmark code analysis
hyperfine --warmup 3 \
  './scripts/autodocs/analyze-code.js --dir tests/fixtures/large-ts/'

# Results:
# Time (mean ± σ):     15.2 s ±  0.5 s    [User: 12.1 s, System: 2.8 s]
# Range (min … max):   14.5 s … 16.3 s    10 runs
```

**Performance Regression:** Fail CI if performance degrades >20%.

---

## Platform Testing

### Supported Platforms

**v0.1 Support:**
- Linux: Ubuntu 22.04+, Debian 12+
- macOS: macOS 13 (Ventura)+

**v0.2+ (Future):**
- Windows: WSL2 or Git Bash

### Platform Test Matrix

| Platform | Bash Version | Tools | Test Status |
|----------|--------------|-------|-------------|
| Ubuntu 22.04 | bash 5.1 | yq, jq, ajv | ✅ Tested |
| Ubuntu 24.04 | bash 5.2 | yq, jq, ajv | ✅ Tested |
| Debian 12 | bash 5.2 | yq, jq, ajv | ⏳ To test |
| macOS 13 | bash 3.2 / zsh | brew install | ✅ Tested |
| macOS 14 | bash 3.2 / zsh | brew install | ✅ Tested |

### Platform-Specific Tests

**bash 3.2 Compatibility (macOS):**
- No associative arrays (bash 4+ feature)
- Use indexed arrays or workarounds
- Test: All scripts run without errors

**Path Handling:**
- Linux: `/home/user/...`
- macOS: `/Users/user/...`
- Test: Scripts handle both path styles

**Tool Versions:**
- yq v4 (different from yq v3, breaking changes)
- jq v1.6+ (older versions have bugs)
- Test: Detect tool versions, warn if incompatible

---

## Security Testing

### Security Test Scenarios

**Test 1: No Secrets in Generated Docs**
- Generate docs with mock config (includes secrets)
- Verify secrets not written to docs/
- Verify .env patterns excluded from analysis

**Test 2: Safe File Operations**
- Test: Cannot overwrite files outside project (path traversal)
- Test: Cannot delete files without confirmation
- Test: Atomic writes prevent corruption

**Test 3: Input Validation**
- Test: Reject invalid spec IDs (SQL injection patterns)
- Test: Reject invalid YAML (YAML bombs)
- Test: Reject invalid paths (../../../etc/passwd)

**Test 4: State File Security**
- Test: State file permissions (600, not world-readable)
- Test: State file not committed to git (.gitignore)
- Test: No sensitive data in state.yaml

### Security Test Checklist

- [ ] No secrets in docs/ (API keys, passwords, tokens)
- [ ] No secrets in .spec-drive/ (config.yaml validated)
- [ ] No path traversal vulnerabilities (file operations)
- [ ] No command injection (shell escaping)
- [ ] No YAML bombs (schema validation limits)
- [ ] State file permissions correct (600)
- [ ] .gitignore includes state.yaml

---

## Test Automation

### Automated Test Execution

**Local:** Developer runs `./tests/run-all-tests.sh` before commit.

**CI:** GitHub Actions runs tests on every push.

**Schedule:** Nightly full regression run (all tests, all platforms).

### Test Automation Tools

**Unit Tests:** `bats` (bash), `jest` (JavaScript)
**Integration Tests:** Bash scripts with assertions
**E2E Tests:** Bash scripts simulating user interactions
**Performance Tests:** `hyperfine` (benchmarking)
**Coverage:** `kcov` (bash), `jest --coverage` (JavaScript)
**Reporting:** `jest-html-reporter`, codecov.io

### Test Execution Scripts

**Run All Tests:**
```bash
#!/bin/bash
# tests/run-all-tests.sh

set -e

echo "=== Running Unit Tests ==="
bats tests/unit/*.bats
npm test  # Jest for JavaScript

echo "=== Running Integration Tests ==="
for test in tests/integration/*.sh; do
  bash "$test"
done

echo "=== Running E2E Tests ==="
for test in tests/e2e/*.sh; do
  bash "$test"
done

echo "=== Running System Tests ==="
for test in tests/system/*.sh; do
  bash "$test"
done

echo "=== Generating Coverage Report ==="
kcov --exclude-pattern=/usr coverage/ tests/unit/*.bats
npm run coverage

echo "✅ All tests passed!"
```

**Run Specific Test Suite:**
```bash
# Run only unit tests
./tests/run-all-tests.sh --unit

# Run only integration tests
./tests/run-all-tests.sh --integration

# Run specific test file
bats tests/unit/workflow-engine.bats
```

---

## Test Execution Schedule

### Development Phase

**Continuous (on every code change):**
- Unit tests (developer runs locally)
- Lint/format checks (pre-commit hook)

**On every commit (CI):**
- All unit tests
- Critical integration tests (P0)
- Platform tests (Linux, macOS)

**Daily (scheduled CI):**
- Full regression suite
- Performance tests
- System tests

### Integration Phase (End of Each Implementation Phase)

**Phase 1 Exit:**
- All Phase 1 unit tests
- Foundation integration tests (templates, directories, config)

**Phase 2 Exit:**
- All Phase 2 unit tests
- Workflow integration tests (app-new, feature)

**Phase 3 Exit:**
- All Phase 3 unit tests
- Autodocs integration tests (analysis, index, doc update)

**Phase 4 Exit:**
- All Phase 4 unit tests
- Gate integration tests (enforcement, blocking)

**Phase 5 Exit:**
- Full regression suite (all tests)
- E2E tests (all user workflows)
- Performance tests (large codebases)
- Platform tests (all supported platforms)

### Release Phase

**Release Candidate Testing:**
- Full test suite (all levels, all platforms)
- Manual smoke tests (fresh project, existing project)
- Documentation validation (all examples work)
- Performance validation (benchmarks meet targets)

**Final Release:**
- Re-run full test suite (sanity check)
- Manual acceptance test (full workflow)
- Sign-off from core team

---

## Test Metrics & Reporting

### Key Metrics

**Coverage Metrics:**
- Line coverage: 80% minimum, 90% target
- Branch coverage: 90% minimum, 95% target
- Test count: Track over time (should increase)

**Quality Metrics:**
- Test pass rate: 100% required for merge
- Flaky tests: <1% (tests that fail intermittently)
- Test execution time: <5 minutes for fast feedback

**Defect Metrics:**
- Bugs found by tests (before release)
- Bugs escaped to production (after release)
- Bug fix time (time from bug report to fix)

### Test Reports

**Generated Reports:**
- Coverage report (HTML, lcov.info)
- Test results (JUnit XML)
- Performance benchmarks (JSON)
- Platform compatibility matrix (markdown)

**Dashboards:**
- CI dashboard (GitHub Actions UI)
- Coverage dashboard (codecov.io)
- Test trend graph (pass rate over time)

**Distribution:**
- Test reports published to CI artifacts
- Coverage reports published to codecov.io
- Weekly test summary email to team

---

## Exit Criteria

### Test Completion Criteria

**Unit Tests:**
- [ ] All unit tests written (100% functions covered)
- [ ] All unit tests passing (0 failures)
- [ ] Coverage targets met (80% line, 90% branch)

**Integration Tests:**
- [ ] All integration scenarios tested (10 scenarios)
- [ ] All integration tests passing (0 failures)
- [ ] Critical paths 100% covered

**E2E Tests:**
- [ ] All user workflows tested (7 workflows)
- [ ] All E2E tests passing (0 failures)
- [ ] Happy paths 100% covered

**System Tests:**
- [ ] All error scenarios tested
- [ ] All platform tests passing (Linux, macOS)
- [ ] Edge cases validated

**Performance Tests:**
- [ ] All performance benchmarks run
- [ ] All targets met (analysis <30s, autodocs <60s)
- [ ] No performance regressions

**Regression Tests:**
- [ ] Full regression suite passing (0 failures)
- [ ] Baseline updated (if needed)

### Release Readiness Criteria

**Functional:**
- [ ] All P0 tests passing (100%)
- [ ] All P1 tests passing (>95%)
- [ ] All critical scenarios working

**Quality:**
- [ ] No critical bugs (severity 1)
- [ ] No high bugs blocking release (severity 2)
- [ ] Test coverage targets met

**Performance:**
- [ ] All performance targets met
- [ ] No performance regressions

**Platform:**
- [ ] All supported platforms tested
- [ ] All platform tests passing

**Documentation:**
- [ ] All test documentation complete
- [ ] All test examples validated
- [ ] Test reports published

**Sign-Off:**
- [ ] Core team approval
- [ ] QA sign-off (if applicable)
- [ ] Release notes include test results

---

## Appendix

### Test Naming Conventions

**Unit Tests:**
- File: `test-{module-name}.bats` or `{module-name}.test.js`
- Test: `test_{function_name}_{scenario}`
- Example: `test_workflow_start_sets_current_workflow`

**Integration Tests:**
- File: `test-{feature}-{scenario}.sh`
- Example: `test-workflow-gates-integration.sh`

**E2E Tests:**
- File: `test-{workflow}-complete.sh`
- Example: `test-new-project-complete.sh`

### Test Utilities

**Assertion Library (Bash):**
```bash
# tests/lib/assertions.sh

assert_equals() {
  local actual="$1"
  local expected="$2"
  if [ "$actual" != "$expected" ]; then
    echo "❌ Assertion failed: expected '$expected', got '$actual'"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "❌ Assertion failed: file '$file' does not exist"
    return 1
  fi
}

assert_success() {
  if [ $? -ne 0 ]; then
    echo "❌ Assertion failed: command failed (exit code $?)"
    return 1
  fi
}
```

### Mock Data Generators

**Generate Large Codebase:**
```bash
# tests/fixtures/generate-large-codebase.sh

generate_large_codebase() {
  local output_dir="$1"
  local file_count="${2:-1000}"

  mkdir -p "$output_dir/src"

  for i in $(seq 1 $file_count); do
    cat > "$output_dir/src/module-$i.ts" <<EOF
export class Module$i {
  process() {
    return "Module $i processing";
  }
}
EOF
  done

  echo "Generated $file_count files in $output_dir"
}
```

---

**Maintained By:** Core Team
**Update Frequency:** Updated during implementation (as tests are written)
**Last Review:** 2025-11-01
