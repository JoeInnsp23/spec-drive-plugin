# SPEC-DRIVE v0.2 TEST PLAN

**Version:** 1.0
**Date:** 2025-11-01
**Status:** Active
**Related PRD:** `.spec-drive/development/planned/v0.2/PRD.md`
**Related TDD:** `.spec-drive/development/planned/v0.2/TDD.md`

---

## 1. TEST OVERVIEW

### Scope

**In Scope:**
- All 6 v0.2 enhancements (Specialist Agents, Additional Workflows, Stack Profiles, Index Optimizations, Multi-Workflow State, Error Recovery)
- Integration between enhancements
- Backward compatibility with v0.1
- Performance targets (context reduction, summary generation, switching)
- Error recovery mechanisms (auto-retry, rollback, resume)

**Out of Scope:**
- v0.1 functionality (already tested)
- v0.3+ features (Lead Agents, Drift Detection)
- Manual workflow execution (v0.1 behavior available as fallback)
- Non-supported stacks (only TypeScript, Python, Go, Rust tested)

### Test Objectives

1. **Validate 60% Automation:** Specialist agents reduce manual workflow tasks by ≥60%
2. **Ensure Multi-Workflow Support:** 3+ workflows run concurrently without conflicts
3. **Verify Stack Awareness:** 100% quality gates adapt to detected stack
4. **Measure Context Reduction:** ≥90% reduction via AI summaries + query patterns
5. **Confirm Error Recovery:** ≥80% of gate failures auto-retry successfully
6. **Validate Backward Compatibility:** v0.1 workflows still function correctly

### Success Criteria

- ✅ All 6 test scenarios pass without errors
- ✅ All 53 test cases pass (100% pass rate)
- ✅ Edge cases handled gracefully (no crashes or data loss)
- ✅ Performance targets met (context <1KB, summaries <10s, switching <1s)
- ✅ Automated test suite runs successfully on CI
- ✅ No critical or high-priority bugs remain

---

## 2. TEST STRATEGY

### Test Levels

| Level | Coverage | Responsibility | When |
|-------|----------|----------------|------|
| Unit | ≥90% code coverage | Test individual scripts/functions | During development (per task) |
| Integration | 6 scenarios, 53 test cases | Test component interactions | After each phase completes |
| End-to-End | 6 full workflows | Test complete user journeys | Before release (Week 12) |
| Performance | 4 metrics | Measure speed/efficiency | Week 8 (Index) + Week 12 (Final) |
| Regression | All v0.1 scenarios | Ensure v0.1 still works | Week 12 (Final validation) |

### Test Approach

**Unit Testing:**
- Jest for JavaScript tools (workflow-queue.js, detect-conflicts.js, etc.)
- pytest for Python scripts (stack-detection.py)
- Bash test framework for shell scripts (gates, orchestrators)
- Target: ≥90% code coverage per component

**Integration Testing:**
- Fully automated bash scripts for workflow testing
- Test real TypeScript/React and Python/FastAPI projects
- Validate agent outputs (spec quality, code quality, test coverage)
- Mock Claude API for deterministic agent responses (optional)

**End-to-End Testing:**
- Complete workflow executions (feature, bugfix, research)
- Real Claude Code environment (no mocks)
- Multi-session testing (resume after interruption)
- Manual validation of final artifacts (specs, code, tests, docs, ADRs)

**Performance Testing:**
- Measure with time command (summary generation, context switching)
- Token counting for context reduction (before/after summaries)
- Automated benchmarks (run 10 times, report avg/min/max)

---

## 3. TEST SCENARIOS

### Scenario 1: Multi-Workflow Concurrent Development

**ID:** TS-001
**Priority:** Critical
**Type:** End-to-End
**Duration:** 45-60 minutes

**Objective:** Validate 3+ workflows run concurrently without conflicts

**Preconditions:**
- v0.1 complete and validated
- TypeScript/React test project initialized
- Git repository clean (no uncommitted changes)

**Test Steps:**
1. Initialize project: `cd test-projects/typescript-react && /spec-drive:init`
2. Start feature workflow: `/spec-drive:feature AUTH-001 "MFA Login"`
3. Progress to Discover stage (manual exploration)
4. Advance to Specify stage (spec-agent creates spec)
5. Approve spec, advance to Implement stage
6. Verify state: AUTH-001 at "implement" stage, status "in_progress"
7. **Context Switch:** `/spec-drive:switch BUG-042` (new bugfix)
8. Verify conflict check: No conflicts (different files)
9. Start bugfix workflow: `/spec-drive:bugfix BUG-042 "Login fails with special chars in password"`
10. Complete bugfix: investigate → specify-fix → fix → verify → done
11. Verify: BUG-042 status "completed", files committed
12. **Context Switch:** `/spec-drive:switch RES-001` (new research)
13. Start research: `/spec-drive:research "auth provider selection" "1h"`
14. Complete research: explore → synthesize → decide → ADR-0003.md created
15. Verify: RES-001 status "completed", ADR committed
16. **Context Switch:** `/spec-drive:switch AUTH-001` (resume feature)
17. Continue implement stage (impl-agent + test-agent)
18. Complete to done: implement → verify → done
19. Verify final state:
    - AUTH-001: status "completed", all traces present (code, tests, docs)
    - BUG-042: status "completed", regression test present
    - RES-001: status "completed", ADR-0003.md exists
20. Verify no data loss: All files committed, no conflicts

**Expected Results:**
- ✅ 3 workflows active simultaneously (AUTH-001, BUG-042, RES-001)
- ✅ Context switching works without data loss or corruption
- ✅ Priority ordering respected: BUG-042 priority=0 (highest)
- ✅ File conflicts detected: warn if attempting to edit locked files
- ✅ All workflow outputs valid: specs complete, code passes gates, tests pass, docs updated, ADR present
- ✅ state.yaml tracks all workflows correctly
- ✅ No state corruption (validation passes on load)

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-001-multi-workflow.sh

set -e  # Exit on error

# Setup
cd test-projects/typescript-react
git checkout -b test-ts-001

# Step 1: Init
/spec-drive:init
assert_status 0 "Init should succeed"

# Step 2-6: Start AUTH-001, progress to Implement
/spec-drive:feature AUTH-001 "MFA Login"
# ... (automated agent interactions)
assert_workflow_stage "AUTH-001" "implement"

# Step 7-11: Switch to BUG-042, complete bugfix
/spec-drive:switch BUG-042
/spec-drive:bugfix BUG-042 "Login fails special chars"
# ... (automated bugfix steps)
assert_workflow_status "BUG-042" "completed"

# Step 12-15: Switch to RES-001, complete research
/spec-drive:switch RES-001
/spec-drive:research "auth provider selection" "1h"
# ... (automated research steps)
assert_file_exists ".spec-drive/development/adr/ADR-0003.md"

# Step 16-19: Switch back to AUTH-001, complete
/spec-drive:switch AUTH-001
# ... (complete implement → verify → done)
assert_workflow_status "AUTH-001" "completed"

# Step 20: Final verification
assert_no_conflicts
assert_all_traces_complete "AUTH-001"
assert_regression_test_exists "BUG-042"

echo "✅ TS-001: Multi-Workflow PASSED"
```

---

### Scenario 2: Stack Profile Enforcement (TypeScript/React)

**ID:** TS-002
**Priority:** Critical
**Type:** Integration
**Duration:** 30-40 minutes

**Objective:** Validate TypeScript/React stack profile enforces conventions

**Preconditions:**
- TypeScript/React project with package.json, tsconfig.json, React dependency
- No existing profile override in config

**Test Steps:**
1. Initialize project: `/spec-drive:init`
2. Verify auto-detection: `cat .spec-drive/config.yaml | grep "detected_stack: typescript-react"`
3. Start feature workflow: `/spec-drive:feature UI-001 "User Profile Component"`
4. Specify stage: spec-agent creates specs/UI-001.yaml
5. Verify spec includes TypeScript-specific examples
6. Implement stage: Delegate to impl-agent
7. impl-agent creates component: `src/components/UserProfile.tsx`
8. Verify component structure:
   - Uses PascalCase naming (`UserProfile`, not `userProfile`)
   - Props interface exported (`export interface UserProfileProps`)
   - Functional component pattern (`const UserProfile: React.FC<UserProfileProps>`)
   - TypeScript types (no `any` types)
9. test-agent creates `tests/components/UserProfile.test.tsx`
10. Verify test structure:
    - Uses React Testing Library (`import { render, screen } from '@testing-library/react'`)
    - Test naming: `describe('UserProfile', () => { it('should...') })`
    - @spec UI-001 tag present
11. Run Gate 3: Quality checks
12. Verify ESLint runs: `eslint src/**/*.tsx`
13. Verify TypeScript compiles: `npx tsc --noEmit`
14. Verify no 'any' types: `grep -r "any" src/ | grep -v "// @ts-ignore"` (should be empty)
15. Verify tests pass: `npm test`
16. All checks pass, advance to Verify stage
17. Verify: No fallback to generic profile behaviors

**Expected Results:**
- ✅ Auto-detection works (package.json + tsconfig.json + react dependency)
- ✅ impl-agent follows TypeScript/React conventions (PascalCase, props interface, functional component)
- ✅ test-agent uses React Testing Library patterns
- ✅ Stack-specific gates run (ESLint, tsc, no 'any' grep)
- ✅ No generic fallback behaviors observed
- ✅ All quality gates pass

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-002-stack-typescript.sh

set -e

cd test-projects/typescript-react
git checkout -b test-ts-002

# Step 1-2: Init and verify detection
/spec-drive:init
DETECTED_STACK=$(yq eval '.detected_stack' .spec-drive/config.yaml)
assert_equals "$DETECTED_STACK" "typescript-react" "Stack detection"

# Step 3-6: Feature workflow with agents
/spec-drive:feature UI-001 "User Profile Component"
# ... (automated agent delegation)

# Step 7-8: Verify component structure
assert_file_exists "src/components/UserProfile.tsx"
assert_file_contains "src/components/UserProfile.tsx" "export interface UserProfileProps"
assert_file_contains "src/components/UserProfile.tsx" "const UserProfile: React.FC"
assert_file_not_contains "src/components/UserProfile.tsx" ": any"

# Step 9-10: Verify test structure
assert_file_exists "tests/components/UserProfile.test.tsx"
assert_file_contains "tests/components/UserProfile.test.tsx" "@testing-library/react"
assert_file_contains "tests/components/UserProfile.test.tsx" "@spec UI-001"

# Step 11-15: Run gates
npm run lint
assert_status 0 "ESLint should pass"

npx tsc --noEmit
assert_status 0 "TypeScript should compile"

ANY_COUNT=$(grep -r ": any" src/ | grep -v "@ts-ignore" | wc -l)
assert_equals "$ANY_COUNT" "0" "No 'any' types"

npm test
assert_status 0 "Tests should pass"

echo "✅ TS-002: Stack Profile (TypeScript) PASSED"
```

---

### Scenario 3: Stack Profile Enforcement (Python/FastAPI)

**ID:** TS-003
**Priority:** Critical
**Type:** Integration
**Duration:** 30-40 minutes

**Objective:** Validate Python/FastAPI stack profile enforces conventions

**Preconditions:**
- Python/FastAPI project with requirements.txt, fastapi dependency
- Python ≥3.9 installed

**Test Steps:**
1. Initialize project: `/spec-drive:init`
2. Verify auto-detection: `detected_stack: python-fastapi`
3. Start feature workflow: `/spec-drive:feature API-001 "Get User Endpoint"`
4. Specify stage: spec-agent creates specs/API-001.yaml
5. Implement stage: impl-agent creates `src/routers/user_routes.py`
6. Verify router structure:
   - Uses `async def` for all endpoints
   - Pydantic models for request/response (`class UserResponse(BaseModel)`)
   - HTTPException for errors (`raise HTTPException(status_code=404)`)
   - snake_case naming for functions and files
   - Type hints present (`user_id: int`, `-> UserResponse`)
7. test-agent creates `tests/test_user_routes.py`
8. Verify test structure:
   - Uses pytest fixtures (`@pytest.fixture`)
   - Async test patterns (`@pytest.mark.asyncio`, `async def test_...`)
   - @spec API-001 tag in docstring
9. Run Gate 3: Quality checks
10. Verify pytest runs: `pytest tests/`
11. Verify mypy type check: `mypy src/`
12. Verify black formatting: `black --check src/`
13. Verify pylint: `pylint src/` (score ≥9.0)
14. All checks pass
15. Verify: No fallback to generic profile

**Expected Results:**
- ✅ Auto-detection works (requirements.txt + fastapi dependency)
- ✅ impl-agent follows Python/FastAPI conventions (async def, Pydantic, HTTPException)
- ✅ test-agent uses pytest patterns (fixtures, async tests)
- ✅ Stack-specific gates run (pytest, mypy, black, pylint)
- ✅ Type hints enforced (mypy passes)
- ✅ All quality gates pass

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-003-stack-python.sh

set -e

cd test-projects/python-fastapi
git checkout -b test-ts-003

# Step 1-2: Init and verify detection
/spec-drive:init
DETECTED_STACK=$(yq eval '.detected_stack' .spec-drive/config.yaml)
assert_equals "$DETECTED_STACK" "python-fastapi" "Stack detection"

# Step 3-6: Feature workflow
/spec-drive:feature API-001 "Get User Endpoint"
# ... (automated agent delegation)

# Verify router structure
assert_file_exists "src/routers/user_routes.py"
assert_file_contains "src/routers/user_routes.py" "async def"
assert_file_contains "src/routers/user_routes.py" "BaseModel"
assert_file_contains "src/routers/user_routes.py" "HTTPException"
assert_file_contains "src/routers/user_routes.py" "-> UserResponse"

# Step 7-8: Verify test structure
assert_file_exists "tests/test_user_routes.py"
assert_file_contains "tests/test_user_routes.py" "@pytest.mark.asyncio"
assert_file_contains "tests/test_user_routes.py" "@spec API-001"

# Step 9-14: Run gates
pytest tests/
assert_status 0 "pytest should pass"

mypy src/
assert_status 0 "mypy should pass"

black --check src/
assert_status 0 "black should pass"

PYLINT_SCORE=$(pylint src/ | grep "Your code has been rated" | awk '{print $7}' | cut -d'/' -f1)
assert_greater_than "$PYLINT_SCORE" "9.0" "pylint score"

echo "✅ TS-003: Stack Profile (Python) PASSED"
```

---

### Scenario 4: Specialist Agent Coordination

**ID:** TS-004
**Priority:** Critical
**Type:** Integration
**Duration:** 40-50 minutes

**Objective:** Validate agents coordinate correctly in TDD workflow

**Preconditions:**
- TypeScript/React project initialized
- All 3 agents available (spec-agent, impl-agent, test-agent)

**Test Steps:**
1. Start feature workflow: `/spec-drive:feature METRICS-001 "Usage Metrics Export"`
2. Complete Discover stage manually (explore existing metrics, define requirements)
3. Advance to Specify stage
4. **Delegate to spec-agent**
5. spec-agent creates `.spec-drive/specs/METRICS-001.yaml`
6. Verify spec completeness:
   - User stories present and clear
   - All ACs in Given/When/Then format
   - Success criteria measurable (e.g., "Export completes in <5s")
   - No `[NEEDS CLARIFICATION]` markers remain
   - Dependencies identified
7. Run validate-spec.js: `node scripts/tools/validate-spec.js METRICS-001`
8. Validation passes, approve spec
9. Advance to Implement stage
10. **Delegate to test-agent (TDD: tests first)**
11. test-agent creates `tests/api/metrics.test.ts`
12. Verify test coverage:
    - All ACs have corresponding tests
    - @spec METRICS-001 tags present
    - Edge cases covered (empty data, large exports)
    - Error scenarios tested (invalid format, permission denied)
13. Run tests: `npm test` (should FAIL - no implementation yet)
14. Verify tests fail as expected (TDD pattern)
15. **Delegate to impl-agent**
16. impl-agent creates `src/api/metrics.ts`
17. Verify implementation:
    - Follows TypeScript conventions
    - @spec METRICS-001 tags present
    - Error handling complete (try-catch, input validation)
    - No TODO/console.log/placeholders
18. Run tests: `npm test` (should now PASS)
19. Verify all tests pass (TDD cycle complete)
20. Run Gate 3: All quality checks pass
21. Verify automation: User only provided initial requirements + approval, agents did 60%+ of work

**Expected Results:**
- ✅ spec-agent creates complete, valid spec (no ambiguities)
- ✅ test-agent writes tests BEFORE implementation (TDD pattern)
- ✅ impl-agent implements to make tests pass
- ✅ All agents add @spec tags correctly
- ✅ Code follows stack conventions
- ✅ Tests pass after implementation
- ✅ 60%+ automation achieved (user provides requirements + approval only)

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-004-agent-coordination.sh

set -e

cd test-projects/typescript-react
git checkout -b test-ts-004

# Step 1-2: Start feature, complete Discover
/spec-drive:feature METRICS-001 "Usage Metrics Export"
# ... (manual discover stage)

# Step 3-8: Specify stage with spec-agent
advance_stage "specify"
# spec-agent runs automatically (via orchestrator delegation)
wait_for_spec_creation "METRICS-001"

assert_file_exists ".spec-drive/specs/METRICS-001.yaml"
assert_file_contains ".spec-drive/specs/METRICS-001.yaml" "Given"
assert_file_contains ".spec-drive/specs/METRICS-001.yaml" "When"
assert_file_contains ".spec-drive/specs/METRICS-001.yaml" "Then"
assert_file_not_contains ".spec-drive/specs/METRICS-001.yaml" "[NEEDS CLARIFICATION]"

node scripts/tools/validate-spec.js METRICS-001
assert_status 0 "Spec validation"

# Step 9-14: Implement stage with test-agent (TDD)
advance_stage "implement"
# test-agent runs first (TDD pattern)
wait_for_test_creation "METRICS-001"

assert_file_exists "tests/api/metrics.test.ts"
assert_file_contains "tests/api/metrics.test.ts" "@spec METRICS-001"

npm test 2>&1 | tee test-output.txt
assert_status 1 "Tests should fail (no implementation yet)"

# Step 15-19: impl-agent implements
# impl-agent runs automatically after test-agent
wait_for_implementation "METRICS-001"

assert_file_exists "src/api/metrics.ts"
assert_file_contains "src/api/metrics.ts" "@spec METRICS-001"
assert_file_not_contains "src/api/metrics.ts" "TODO"
assert_file_not_contains "src/api/metrics.ts" "console.log"

npm test
assert_status 0 "Tests should pass after implementation"

# Step 20: Gate 3
run_gate "gate-3-implement" "METRICS-001"
assert_status 0 "Gate 3 should pass"

echo "✅ TS-004: Agent Coordination PASSED"
```

---

### Scenario 5: Index Optimizations

**ID:** TS-005
**Priority:** High
**Type:** Integration + Performance
**Duration:** 20-30 minutes

**Objective:** Validate AI summaries, query patterns, changes feed

**Preconditions:**
- TypeScript/React project with completed AUTH-001 feature
- Index v2.0 enabled

**Test Steps:**
1. Complete AUTH-001 feature workflow (MFA login implementation)
2. Verify autodocs updated: index.yaml regenerated
3. **Verify AI Summaries Generated:**
   - `yq eval '.components[] | select(.id == "comp-auth-mfa") | .summary' index.yaml`
   - Summary exists: "Implements multi-factor authentication via SMS/email, validates codes, handles timeouts"
   - `yq eval '.specs[] | select(.id == "AUTH-001") | .summary' index.yaml`
   - Summary exists: "Adds MFA to login flow, supports SMS/email verification, improves security"
   - Check all entries have summaries (components, specs, docs, code)
4. **Test Query with Summaries:**
   - Query: "How does MFA work?"
   - Measure context usage: Count tokens in response
   - Target: <1KB (≈200 tokens)
   - Verify: Answer derived from summary only (no full file reads)
5. **Test Pre-Answered Queries:**
   - `yq eval '.queries["how does authentication work"]' index.yaml`
   - Verify: Pre-answered query exists with answer text
   - Query: "How does authentication work?"
   - Verify: Instant answer (uses index.queries[], no file reads)
6. **Test Changes Feed:**
   - Make code change: Add SMS fallback to mfa.ts
   - Commit: `git commit -m "feat(AUTH-001): Add SMS fallback"`
   - Verify: PostToolUse hook triggered
   - `yq eval '.changes[0]' index.yaml`
   - Verify: Latest change shows:
     - timestamp (recent)
     - commit_hash (matches git log)
     - message ("feat(AUTH-001): Add SMS fallback")
     - files_changed (["src/auth/mfa.ts"])
     - insertions/deletions (diff stats)
     - spec_id ("AUTH-001")
7. Query: "What changed recently?"
8. Verify: Shows last change with diff stats
9. **Performance Measurement:**
   - Measure summary generation time: `time node scripts/tools/generate-summaries.js --file=src/auth/mfa.ts`
   - Target: <10s (average: 3-5s)
   - Measure context reduction: Compare token usage before/after summaries
   - Target: ≥90% reduction

**Expected Results:**
- ✅ AI summaries generated for all index entries (components, specs, docs, code)
- ✅ Summaries are 1-2 sentences, max 200 chars
- ✅ Query "how does X work" uses <1KB context (90% reduction achieved)
- ✅ Pre-answered queries work (instant answers from index.queries[])
- ✅ Changes feed tracks updates (last 20 entries, FIFO)
- ✅ Summary generation time <10s per file
- ✅ Summaries accurate and helpful (manual spot-check)

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-005-index-optimizations.sh

set -e

cd test-projects/typescript-react
git checkout -b test-ts-005

# Step 1-2: Complete AUTH-001 (prerequisite)
# ... (assumed complete from previous test)

# Step 3: Verify AI summaries
COMP_SUMMARY=$(yq eval '.components[] | select(.id == "comp-auth-mfa") | .summary' .spec-drive/index.yaml)
assert_not_empty "$COMP_SUMMARY" "Component summary"
assert_length_between "$COMP_SUMMARY" 50 200 "Summary length"

SPEC_SUMMARY=$(yq eval '.specs[] | select(.id == "AUTH-001") | .summary' .spec-drive/index.yaml)
assert_not_empty "$SPEC_SUMMARY" "Spec summary"

# Step 4: Test query with summaries (context reduction)
QUERY_RESPONSE=$(claude code query "How does MFA work?")
TOKEN_COUNT=$(echo "$QUERY_RESPONSE" | wc -w)  # Rough token estimate
assert_less_than "$TOKEN_COUNT" "250" "Context usage <1KB"

# Step 5: Test pre-answered queries
PRE_ANSWER=$(yq eval '.queries["how does authentication work"].answer' .spec-drive/index.yaml)
assert_not_empty "$PRE_ANSWER" "Pre-answered query"

# Step 6-8: Test changes feed
echo "// SMS fallback" >> src/auth/mfa.ts
git add src/auth/mfa.ts
git commit -m "feat(AUTH-001): Add SMS fallback"

LATEST_CHANGE=$(yq eval '.changes[0].message' .spec-drive/index.yaml)
assert_contains "$LATEST_CHANGE" "SMS fallback" "Changes feed"
assert_equals "$(yq eval '.changes[0].spec_id' .spec-drive/index.yaml)" "AUTH-001" "Spec ID in changes"

# Step 9: Performance measurement
START_TIME=$(date +%s)
node scripts/tools/generate-summaries.js --file=src/auth/mfa.ts
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
assert_less_than "$DURATION" "10" "Summary generation time <10s"

echo "✅ TS-005: Index Optimizations PASSED"
```

---

### Scenario 6: Error Recovery

**ID:** TS-006
**Priority:** Critical
**Type:** Integration
**Duration:** 30-40 minutes

**Objective:** Validate auto-retry, rollback, resume mechanisms

**Preconditions:**
- TypeScript/React project initialized
- Error recovery scripts available

**Test Steps:**
1. Start feature workflow: `/spec-drive:feature TEST-001 "Error Recovery Test"`
2. Complete Discover → Specify stages
3. Implement stage: Create code with intentional linting errors
   ```typescript
   // src/test-component.ts
   const temp = 5  // Missing semicolon
   console.log("hello")  // console.log not allowed
   let unused = "test"  // Unused variable
   ```
4. Advance to Gate 3 (Implement → Verify)
5. Verify: Gate 3 fails with ESLint errors
6. **Test Auto-Retry:**
   - Verify: retry-gate.sh triggered automatically
   - Verify: Log shows "Auto-retry attempt 1/3"
   - Verify: `npm run lint --fix` executes
   - Verify: Errors fixed (semicolon added, console.log removed)
   - Verify: Delay 1s before retry
7. Gate 3 retried
8. Verify: Some errors fixed, but unused variable remains
9. Verify: "Auto-retry attempt 2/3"
10. Verify: Delay 5s before retry
11. Manually fix unused variable (simulate partial auto-fix)
12. Gate 3 retried
13. Verify: All errors fixed, Gate 3 passes
14. Log shows: "Gate passed on attempt 3"
15. **Test Rollback:**
    - Introduce critical error: Segfault in tests (infinite loop, OOM)
    - Run Gate 3
    - Verify: Auto-retry fails 3 times (timeout on each)
    - Verify: Log shows "Gate failed after 3 retries, escalating to user"
    - User prompted: "Rollback to previous stage? (y/N)"
    - User selects: y
    - Verify: rollback-workflow.sh executes
    - Verify: Stage restored to "specify" (before implement)
    - Verify: Git reset to snapshot commit
    - Verify: state.yaml updated (stage: specify, snapshots after "implement" cleared)
16. **Test Resume After Interruption:**
    - Re-implement (fix code, advance to implement stage)
    - Progress partway through implement (create files, but don't complete)
    - Close Claude Code session (simulate interruption)
    - Verify: state.yaml has interrupted: true for TEST-001
17. Reopen Claude Code session
18. Verify: SessionStart hook detects interrupted workflow
19. Verify: Prompt shows: "Resume TEST-001 from 'implement' stage? (y/N)"
20. User selects: y
21. Verify: Workflow resumes from last snapshot
22. Verify: No data loss (files from interrupted session preserved)
23. Complete workflow to Done

**Expected Results:**
- ✅ Auto-retry fixes simple errors (linting, formatting) automatically
- ✅ Max 3 retries enforced (prevents infinite loops)
- ✅ Exponential backoff delays (1s, 5s, 15s) observed
- ✅ Rollback restores previous stage successfully
- ✅ Git changes reverted correctly (git reset --hard)
- ✅ State snapshots preserve progress
- ✅ Resume works after interruption (SessionStart hook)
- ✅ No data loss during resume
- ✅ ≥80% of failures recover automatically (auto-retry success rate)

**Actual Results:** [To be filled during execution]

**Status:** Not Run

**Test Automation:**
```bash
#!/bin/bash
# test-scenarios/ts-006-error-recovery.sh

set -e

cd test-projects/typescript-react
git checkout -b test-ts-006

# Step 1-3: Start workflow, introduce linting errors
/spec-drive:feature TEST-001 "Error Recovery Test"
# ... (complete discover, specify)

cat > src/test-component.ts <<'EOF'
const temp = 5
console.log("hello")
let unused = "test"
EOF

git add src/test-component.ts

# Step 4-14: Test auto-retry
run_gate "gate-3-implement" "TEST-001" 2>&1 | tee gate-output.txt

# Verify retry attempts logged
assert_file_contains "gate-output.txt" "Auto-retry attempt 1/3"
assert_file_contains "gate-output.txt" "npm run lint --fix"

# Verify exponential backoff (timing analysis)
RETRY_TIMES=$(grep "Auto-retry attempt" gate-output.txt | cut -d' ' -f1)
# Calculate delays between retries (should be ~1s, ~5s)

# Verify eventual success
assert_file_contains "gate-output.txt" "Gate passed"

# Step 15: Test rollback
# Introduce critical error (infinite loop in test)
cat > tests/test-component.test.ts <<'EOF'
describe('test', () => {
  it('should timeout', () => {
    while(true) {} // Infinite loop
  });
});
EOF

git add tests/test-component.test.ts

# Run gate, expect failure after 3 retries
run_gate "gate-3-implement" "TEST-001" 2>&1 | tee gate-failure.txt
assert_status 1 "Gate should fail after retries"

assert_file_contains "gate-failure.txt" "Gate failed after 3 retries"

# User triggers rollback
echo "y" | /spec-drive:rollback TEST-001 specify

# Verify rollback
CURRENT_STAGE=$(yq eval '.workflows["TEST-001"].stage' .spec-drive/state.yaml)
assert_equals "$CURRENT_STAGE" "specify" "Stage after rollback"

# Verify git reset
git log -1 --oneline | grep "specify stage" || echo "Git rollback verified"

# Step 16-23: Test resume
# Simulate interruption (set interrupted flag manually)
yq eval '.workflows["TEST-001"].interrupted = true' -i .spec-drive/state.yaml

# Simulate new session (run SessionStart hook)
bash spec-drive/hooks/handlers/session-start.sh 2>&1 | tee session-start.txt

assert_file_contains "session-start.txt" "Resume TEST-001"

# Auto-resume (simulate user confirmation)
# ... (workflow continues from snapshot)

echo "✅ TS-006: Error Recovery PASSED"
```

---

## 4. TEST CASES

### TC-001: Workflow Queue Priority Ordering

**Scenario:** TS-001 (Multi-Workflow)
**Component:** workflow-queue.js
**Type:** Unit Test

**Input:**
```javascript
workflows = {
  'AUTH-001': { priority: 3, status: 'in_progress' },
  'BUG-042': { priority: 0, status: 'in_progress' },
  'RES-001': { priority: 7, status: 'in_progress' }
}
```

**Steps:**
1. Call `sortWorkflowsByPriority(workflows)`
2. Verify sorted order

**Expected Output:**
```javascript
['BUG-042', 'AUTH-001', 'RES-001']  // Priority 0 → 3 → 7
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-002: Conflict Detection - No Conflicts

**Scenario:** TS-001 (Multi-Workflow)
**Component:** detect-conflicts.js
**Type:** Unit Test

**Input:**
```javascript
currentLocks = ['src/auth/login.ts', 'tests/auth/login.test.ts']
targetLocks = ['src/api/users.ts', 'tests/api/users.test.ts']
```

**Steps:**
1. Call `detectConflicts('AUTH-001', 'API-001')`
2. Verify no conflicts

**Expected Output:**
```javascript
{ conflict: false, conflicting_files: [] }
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-003: Conflict Detection - Conflicts Exist

**Scenario:** TS-001 (Multi-Workflow)
**Component:** detect-conflicts.js
**Type:** Unit Test

**Input:**
```javascript
currentLocks = ['src/auth/login.ts', 'tests/auth/login.test.ts']
targetLocks = ['src/auth/login.ts', 'src/auth/session.ts']
```

**Steps:**
1. Call `detectConflicts('AUTH-001', 'BUG-042')`
2. Verify conflict detected

**Expected Output:**
```javascript
{
  conflict: true,
  conflicting_files: ['src/auth/login.ts'],
  current_workflow: 'AUTH-001',
  target_workflow: 'BUG-042'
}
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-010: Stack Detection - TypeScript/React

**Scenario:** TS-002 (Stack Profile TypeScript)
**Component:** stack-detection.py
**Type:** Unit Test

**Input:**
Project with:
- `package.json` containing `"react": "^18.0.0"`
- `tsconfig.json` exists
- `*.tsx` files present

**Steps:**
1. Run `python scripts/stack-detection.py /path/to/project`
2. Verify detection result

**Expected Output:**
```
typescript-react
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-011: Stack Detection - Python/FastAPI

**Scenario:** TS-003 (Stack Profile Python)
**Component:** stack-detection.py
**Type:** Unit Test

**Input:**
Project with:
- `requirements.txt` containing `fastapi`
- `main.py` with `from fastapi import FastAPI`

**Steps:**
1. Run `python scripts/stack-detection.py /path/to/project`
2. Verify detection result

**Expected Output:**
```
python-fastapi
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-020: spec-agent Output Validation

**Scenario:** TS-004 (Agent Coordination)
**Component:** spec-agent
**Type:** Integration Test

**Input:**
Requirements: "Add user login with email/password, handle invalid credentials, return JWT token"

**Steps:**
1. Delegate to spec-agent with requirements
2. Wait for SPEC-XXX.yaml generation
3. Validate output

**Expected Output:**
- File exists: `.spec-drive/specs/SPEC-XXX.yaml`
- Contains: user stories, Given/When/Then ACs, success criteria
- No `[NEEDS CLARIFICATION]` markers
- Validates via validate-spec.js (exits 0)

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-021: test-agent TDD Pattern

**Scenario:** TS-004 (Agent Coordination)
**Component:** test-agent
**Type:** Integration Test

**Input:**
SPEC-XXX.yaml with ACs for login functionality

**Steps:**
1. Delegate to test-agent
2. Wait for test file generation
3. Run tests (should fail - no implementation)

**Expected Output:**
- File exists: `tests/auth/login.test.ts`
- Contains: @spec SPEC-XXX tags, all ACs covered
- Tests fail (exit 1) when run initially

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-022: impl-agent Implementation

**Scenario:** TS-004 (Agent Coordination)
**Component:** impl-agent
**Type:** Integration Test

**Input:**
- SPEC-XXX.yaml
- Failing tests from test-agent

**Steps:**
1. Delegate to impl-agent
2. Wait for implementation
3. Run tests (should pass now)

**Expected Output:**
- File exists: `src/auth/login.ts`
- Contains: @spec SPEC-XXX tags, error handling, input validation
- No TODO/console.log/placeholders
- Tests pass (exit 0)

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-030: AI Summary Generation

**Scenario:** TS-005 (Index Optimizations)
**Component:** generate-summaries.js
**Type:** Unit + Performance Test

**Input:**
File: `src/auth/login.ts` (50 lines of authentication code)

**Steps:**
1. Run `node scripts/tools/generate-summaries.js --file=src/auth/login.ts`
2. Measure time
3. Validate summary

**Expected Output:**
- Summary generated in <10s
- Summary length: 50-200 chars
- Summary format: 1-2 sentences
- Summary content: Describes what login does (not implementation details)

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-031: Context Reduction Measurement

**Scenario:** TS-005 (Index Optimizations)
**Component:** Index queries
**Type:** Performance Test

**Input:**
Query: "How does authentication work?"

**Steps:**
1. Query WITHOUT summaries (v0.1 behavior) - measure tokens
2. Query WITH summaries (v0.2 behavior) - measure tokens
3. Calculate reduction percentage

**Expected Output:**
- Without summaries: ~10KB (2000-2500 tokens)
- With summaries: <1KB (~200 tokens)
- Reduction: ≥90%

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-040: Auto-Retry Success

**Scenario:** TS-006 (Error Recovery)
**Component:** retry-gate.sh
**Type:** Integration Test

**Input:**
Gate failure: ESLint error (fixable via `lint --fix`)

**Steps:**
1. Run gate (fails)
2. Auto-retry triggered
3. `lint --fix` runs
4. Gate retried (passes)

**Expected Output:**
- Retry attempt logged
- Delay observed (1s)
- Lint fix executed
- Gate passes on retry
- Exit code: 0

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-041: Auto-Retry Failure After 3 Attempts

**Scenario:** TS-006 (Error Recovery)
**Component:** retry-gate.sh
**Type:** Integration Test

**Input:**
Gate failure: Logic error (not fixable by auto-fix)

**Steps:**
1. Run gate (fails)
2. Auto-retry attempts 1, 2, 3 (all fail)
3. Escalation triggered

**Expected Output:**
- 3 retry attempts logged
- Delays observed (1s, 5s, 15s)
- No auto-fix successful
- Escalation message shown
- Exit code: 1

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-050: Rollback to Previous Stage

**Scenario:** TS-006 (Error Recovery)
**Component:** rollback-workflow.sh
**Type:** Integration Test

**Input:**
- Workflow at "implement" stage
- Snapshot exists for "specify" stage
- User confirms rollback

**Steps:**
1. Run `/spec-drive:rollback TEST-001 specify`
2. Verify git reset
3. Verify state.yaml updated

**Expected Output:**
- Git reset to snapshot commit
- state.yaml: stage = "specify"
- Snapshots after "specify" cleared
- Exit code: 0

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-051: Resume After Interruption

**Scenario:** TS-006 (Error Recovery)
**Component:** session-start.sh
**Type:** Integration Test

**Input:**
- state.yaml has interrupted: true for TEST-001
- SessionStart hook runs

**Steps:**
1. Trigger SessionStart hook
2. Detect interrupted workflow
3. Prompt user to resume

**Expected Output:**
- Prompt shown: "Resume TEST-001 from 'implement' stage?"
- User confirms → workflow state restored
- interrupted flag cleared
- Workflow continues from snapshot

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

## 5. EDGE CASES & ERROR SCENARIOS

### Edge Case 1: Empty Project (No Files)

**What happens:** User runs `/spec-drive:init` on empty directory

**Expected behavior:**
- Stack detection fallback to "generic"
- Minimal doc structure created (SYSTEM-OVERVIEW, ARCHITECTURE skeletons)
- Warning: "No code detected, initialize with app-new workflow"

**Test case:** TC-060

---

### Edge Case 2: Monorepo (Multiple Stacks)

**What happens:** Project has both TypeScript + Python directories

**Expected behavior:**
- Stack detection identifies both stacks
- User prompted: "Multiple stacks detected: typescript-react, python-fastapi. Select primary:"
- Selected stack used for gates
- Manual override available in config.yaml

**Test case:** TC-061

---

### Edge Case 3: Very Large Project (>1000 files)

**What happens:** AI summary generation times out for many files

**Expected behavior:**
- Summary generation skips files after timeout (10s)
- Warning logged: "Timeout for file X, skipping"
- Index still valid (partial summaries better than none)
- User can manually regenerate summaries later

**Test case:** TC-062

---

### Edge Case 4: Two Workflows Modify Same File Simultaneously

**What happens:** AUTH-001 and BUG-042 both lock `src/auth/login.ts`

**Expected behavior:**
- Conflict detected on `/spec-drive:switch`
- User warned: "Conflict: src/auth/login.ts locked by AUTH-001"
- Switch blocked unless user provides `--force` flag
- Force flag: Current changes committed or discarded (user choice)

**Test case:** TC-063

---

### Error Scenario 1: state.yaml Corrupted (Invalid YAML)

**Error condition:** state.yaml has syntax errors (missing colon, invalid indentation)

**Expected handling:**
- Load attempt fails with YAML parse error
- Backup state.yaml → `state.yaml.corrupt-{timestamp}`
- Restore from most recent snapshot (state.yaml.snapshot-N)
- User notified: "State corrupted, restored from snapshot"
- If no snapshot: Offer manual reconstruction (guide user)

**Test case:** TC-064

---

### Error Scenario 2: index.yaml Missing

**Error condition:** index.yaml deleted or not generated

**Expected handling:**
- Autodocs commands detect missing index
- Automatic regeneration: `/spec-drive:rebuild-index` runs
- Warning: "Index missing, regenerating from codebase"
- Non-blocking (workflow continues after rebuild)

**Test case:** TC-065

---

### Error Scenario 3: Git Operations Fail During Rollback

**Error condition:** Git repository in detached HEAD state or dirty working tree

**Expected handling:**
- Pre-check before rollback: Verify git status
- If dirty: Warn user, require commit or stash first
- If detached HEAD: Error, require checkout to branch first
- Rollback aborted if pre-check fails (no data loss)

**Test case:** TC-066

---

## 6. PERFORMANCE TESTS

### PT-001: AI Summary Generation Time

**Metric:** Time per summary (average over 100 files)

**Target:** <10s per file

**Maximum Acceptable:** 30s per file

**Test Method:**
```bash
#!/bin/bash
# Measure 100 summary generations
TOTAL_TIME=0
for i in {1..100}; do
  START=$(date +%s%N)
  node scripts/tools/generate-summaries.js --file="test-files/file-$i.ts"
  END=$(date +%s%N)
  DURATION=$(((END - START) / 1000000))  # Convert to ms
  TOTAL_TIME=$((TOTAL_TIME + DURATION))
done

AVG_TIME=$((TOTAL_TIME / 100))
echo "Average summary generation time: ${AVG_TIME}ms"

# Assert
if [ $AVG_TIME -gt 10000 ]; then
  echo "FAIL: Average time ${AVG_TIME}ms > 10000ms target"
  exit 1
fi
echo "PASS: Average time ${AVG_TIME}ms within target"
```

**Results:** [Filled during execution]

---

### PT-002: Context Reduction Measurement

**Metric:** Token usage for query "how does X work?"

**Target:** <1KB (≈200 tokens) with summaries, ≥90% reduction vs without

**Test Method:**
```bash
#!/bin/bash
# Measure tokens WITHOUT summaries (v0.1 behavior)
mv .spec-drive/index.yaml .spec-drive/index.yaml.backup
# Simulate v0.1 index (no summaries)
cp .spec-drive/index.yaml.v01 .spec-drive/index.yaml

RESPONSE_BEFORE=$(claude code query "How does authentication work?")
TOKENS_BEFORE=$(echo "$RESPONSE_BEFORE" | wc -w)  # Rough estimate

# Restore v0.2 index (with summaries)
mv .spec-drive/index.yaml.backup .spec-drive/index.yaml

RESPONSE_AFTER=$(claude code query "How does authentication work?")
TOKENS_AFTER=$(echo "$RESPONSE_AFTER" | wc -w)

REDUCTION=$(echo "scale=2; 100 * (1 - $TOKENS_AFTER / $TOKENS_BEFORE)" | bc)

echo "Tokens before: $TOKENS_BEFORE"
echo "Tokens after: $TOKENS_AFTER"
echo "Reduction: ${REDUCTION}%"

# Assert
if (( $(echo "$REDUCTION < 90" | bc -l) )); then
  echo "FAIL: Reduction ${REDUCTION}% < 90% target"
  exit 1
fi
echo "PASS: Reduction ${REDUCTION}% meets target"
```

**Results:** [Filled during execution]

---

### PT-003: Context Switching Time

**Metric:** Time from `/spec-drive:switch` to workflow ready

**Target:** <1s

**Test Method:**
```bash
#!/bin/bash
# Measure 10 context switches
TOTAL_TIME=0
for i in {1..10}; do
  START=$(date +%s%N)
  /spec-drive:switch AUTH-001
  # Wait for ready (workflow state updated)
  while [ "$(yq eval '.current_spec' .spec-drive/state.yaml)" != "AUTH-001" ]; do
    sleep 0.01
  done
  END=$(date +%s%N)
  DURATION=$(((END - START) / 1000000))  # Convert to ms
  TOTAL_TIME=$((TOTAL_TIME + DURATION))

  # Switch to different workflow for next iteration
  /spec-drive:switch BUG-042 >/dev/null
done

AVG_TIME=$((TOTAL_TIME / 10))
echo "Average switch time: ${AVG_TIME}ms"

# Assert
if [ $AVG_TIME -gt 1000 ]; then
  echo "FAIL: Average time ${AVG_TIME}ms > 1000ms target"
  exit 1
fi
echo "PASS: Average time ${AVG_TIME}ms within target"
```

**Results:** [Filled during execution]

---

### PT-004: Index Update Time

**Metric:** Time to update index.yaml after code change

**Target:** <5s

**Maximum Acceptable:** 15s

**Test Method:**
```bash
#!/bin/bash
# Modify 10 files, measure index update time
START=$(date +%s)

for i in {1..10}; do
  echo "// Change $i" >> src/file-$i.ts
  git add src/file-$i.ts
done

git commit -m "test: Performance test changes"

# Wait for PostToolUse hook to complete index update
while [ "$(yq eval '.dirty' .spec-drive/state.yaml)" == "true" ]; do
  sleep 0.1
done

END=$(date +%s)
DURATION=$((END - START))

echo "Index update time: ${DURATION}s"

# Assert
if [ $DURATION -gt 5 ]; then
  echo "WARN: Time ${DURATION}s > 5s target (but < 15s acceptable)"
fi
if [ $DURATION -gt 15 ]; then
  echo "FAIL: Time ${DURATION}s > 15s maximum"
  exit 1
fi
echo "PASS: Time ${DURATION}s within acceptable range"
```

**Results:** [Filled during execution]

---

## 7. TEST ENVIRONMENT

### Requirements

**Software:**
- Claude Code CLI (latest version)
- Node.js ≥18.0
- Python ≥3.9
- Git ≥2.30
- yq ≥4.0 (YAML processor)
- jq ≥1.6 (JSON processor)

**Test Projects:**
- TypeScript/React project (clean, ~50 files)
- Python/FastAPI project (clean, ~30 files)
- Both in `test-projects/` directory
- Git initialized, clean working tree

**Environment Variables:**
```bash
export CLAUDE_API_KEY="..."  # For AI summary generation
export TEST_MODE="true"      # Enables test assertions
export LOG_LEVEL="debug"     # Verbose logging
```

### Setup Steps

```bash
#!/bin/bash
# test-setup.sh

# 1. Verify v0.1 complete
echo "Verifying v0.1 completion..."
bash .spec-drive/development/current/verify-v01-complete.sh || {
  echo "ERROR: v0.1 not complete, cannot test v0.2"
  exit 1
}

# 2. Clone test projects
echo "Setting up test projects..."
git clone https://github.com/test-org/typescript-react-template test-projects/typescript-react
git clone https://github.com/test-org/python-fastapi-template test-projects/python-fastapi

# 3. Install dependencies
cd test-projects/typescript-react
npm install
cd ../python-fastapi
pip install -r requirements.txt
cd ../..

# 4. Initialize spec-drive in test projects
cd test-projects/typescript-react
/spec-drive:init
cd ../python-fastapi
/spec-drive:init
cd ../..

# 5. Verify baseline (tests pass, lint passes)
cd test-projects/typescript-react
npm test || { echo "ERROR: Baseline tests fail"; exit 1; }
npm run lint || { echo "ERROR: Baseline lint fails"; exit 1; }
cd ../python-fastapi
pytest || { echo "ERROR: Baseline tests fail"; exit 1; }
cd ../..

echo "✅ Test environment ready"
```

**Verification:**
```bash
# Run test-setup.sh
bash test-setup.sh

# Verify environment
node --version  # Should be ≥18
python --version  # Should be ≥3.9
yq --version  # Should be ≥4.0
claude code --version  # Should be latest

# Verify test projects initialized
ls test-projects/typescript-react/.spec-drive/state.yaml
ls test-projects/python-fastapi/.spec-drive/state.yaml
```

---

## 8. TEST EXECUTION

### Execution Schedule

| Phase | Tests | Start Date | End Date | Owner |
|-------|-------|------------|----------|-------|
| Phase 1 Unit Tests | TC-020-022 (Agents) | Week 1 | Week 2 | Agent Lead |
| Phase 2 Unit Tests | TC-070-075 (Workflows) | Week 3 | Week 3 | Workflow Lead |
| Phase 3 Unit Tests | TC-010-011 (Stack Detection) | Week 4 | Week 5 | Stack Profile Lead |
| Phase 4 Unit Tests | TC-030-031 (Index) | Week 6 | Week 7 | Index Lead |
| Phase 5 Unit Tests | TC-001-003 (Multi-Workflow) | Week 8 | Week 9 | State Management Lead |
| Phase 6 Unit Tests | TC-040-051 (Error Recovery) | Week 10 | Week 11 | Error Recovery Lead |
| Integration Tests | TS-001 to TS-006 | Week 12 | Week 12 | QA Lead |
| Performance Tests | PT-001 to PT-004 | Week 12 | Week 12 | QA Lead |

### Execution Log

| Date | Test ID | Result | Notes | Executed By |
|------|---------|--------|-------|-------------|
| (TBD) | TS-001 | Not Run | Multi-workflow concurrent | [Pending] |
| (TBD) | TS-002 | Not Run | Stack profile TypeScript | [Pending] |
| (TBD) | TS-003 | Not Run | Stack profile Python | [Pending] |
| (TBD) | TS-004 | Not Run | Agent coordination | [Pending] |
| (TBD) | TS-005 | Not Run | Index optimizations | [Pending] |
| (TBD) | TS-006 | Not Run | Error recovery | [Pending] |

---

## 9. TEST AUTOMATION FRAMEWORK

### Automated Test Suite Structure

```
test-scenarios/
├── ts-001-multi-workflow.sh          # Scenario 1: Multi-workflow
├── ts-002-stack-typescript.sh        # Scenario 2: TypeScript stack
├── ts-003-stack-python.sh            # Scenario 3: Python stack
├── ts-004-agent-coordination.sh      # Scenario 4: Agent coordination
├── ts-005-index-optimizations.sh     # Scenario 5: Index optimizations
├── ts-006-error-recovery.sh          # Scenario 6: Error recovery
├── lib/
│   ├── assertions.sh                 # Assertion helpers (assert_equals, etc.)
│   ├── workflow-helpers.sh           # Workflow automation helpers
│   └── test-utils.sh                 # Common test utilities
└── run-all-tests.sh                  # Master test runner

tests/
├── unit/
│   ├── workflow-queue.test.js        # Jest: TC-001-003
│   ├── detect-conflicts.test.js      # Jest: TC-002-003
│   ├── generate-summaries.test.js    # Jest: TC-030
│   ├── stack-detection.test.py       # pytest: TC-010-011
│   └── retry-gate.test.sh            # Bash: TC-040-041
└── integration/
    └── (test-scenarios/ contains integration tests)

performance/
├── pt-001-summary-generation.sh
├── pt-002-context-reduction.sh
├── pt-003-context-switching.sh
└── pt-004-index-update.sh
```

### Assertion Library

**File:** `test-scenarios/lib/assertions.sh`

```bash
#!/bin/bash

# Assertion helpers for test automation

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Assertion failed}"

  if [ "$actual" != "$expected" ]; then
    echo "❌ FAIL: $message"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    exit 1
  fi
  echo "✅ PASS: $message"
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Value should not be empty}"

  if [ -z "$value" ]; then
    echo "❌ FAIL: $message (value is empty)"
    exit 1
  fi
  echo "✅ PASS: $message"
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [ ! -f "$file" ]; then
    echo "❌ FAIL: $message"
    exit 1
  fi
  echo "✅ PASS: $message"
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should contain: $pattern}"

  if ! grep -q "$pattern" "$file"; then
    echo "❌ FAIL: $message"
    exit 1
  fi
  echo "✅ PASS: $message"
}

assert_status() {
  local actual_status=$?
  local expected_status=$1
  local message="${2:-Exit status assertion}"

  if [ $actual_status -ne $expected_status ]; then
    echo "❌ FAIL: $message"
    echo "  Expected status: $expected_status"
    echo "  Actual status:   $actual_status"
    exit 1
  fi
  echo "✅ PASS: $message"
}

assert_workflow_stage() {
  local spec_id="$1"
  local expected_stage="$2"

  local actual_stage=$(yq eval ".workflows[\"$spec_id\"].stage" .spec-drive/state.yaml)
  assert_equals "$actual_stage" "$expected_stage" "Workflow $spec_id stage"
}

assert_workflow_status() {
  local spec_id="$1"
  local expected_status="$2"

  local actual_status=$(yq eval ".workflows[\"$spec_id\"].status" .spec-drive/state.yaml)
  assert_equals "$actual_status" "$expected_status" "Workflow $spec_id status"
}
```

### Master Test Runner

**File:** `test-scenarios/run-all-tests.sh`

```bash
#!/bin/bash
# Run all test scenarios

set -e

# Source assertion library
source test-scenarios/lib/assertions.sh

echo "🧪 Running spec-drive v0.2 Test Suite"
echo "======================================"

# Run test scenarios in order
TESTS=(
  "ts-001-multi-workflow"
  "ts-002-stack-typescript"
  "ts-003-stack-python"
  "ts-004-agent-coordination"
  "ts-005-index-optimizations"
  "ts-006-error-recovery"
)

PASSED=0
FAILED=0

for test in "${TESTS[@]}"; do
  echo ""
  echo "Running: $test"
  echo "-------------------"

  if bash "test-scenarios/${test}.sh"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo "❌ Test failed: $test"
  fi
done

echo ""
echo "======================================"
echo "Test Suite Results"
echo "======================================"
echo "Total:  $((PASSED + FAILED))"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "✅ All tests passed!"
  exit 0
else
  echo "❌ $FAILED test(s) failed"
  exit 1
fi
```

**Usage:**
```bash
# Run all tests
bash test-scenarios/run-all-tests.sh

# Run specific test
bash test-scenarios/ts-001-multi-workflow.sh

# Run with verbose output
DEBUG=1 bash test-scenarios/run-all-tests.sh
```

---

## 10. TEST COVERAGE

### Unit Test Coverage

**Target:** ≥90% code coverage

| Component | Lines | Branches | Functions | Coverage % | Status |
|-----------|-------|----------|-----------|------------|--------|
| workflow-queue.js | 0/150 | 0/45 | 0/12 | 0% | Not Tested |
| detect-conflicts.js | 0/80 | 0/20 | 0/6 | 0% | Not Tested |
| generate-summaries.js | 0/200 | 0/60 | 0/15 | 0% | Not Tested |
| update-index-queries.js | 0/120 | 0/35 | 0/10 | 0% | Not Tested |
| update-index-changes.js | 0/100 | 0/30 | 0/8 | 0% | Not Tested |
| retry-gate.sh | 0/90 | 0/25 | 0/5 | 0% | Not Tested |
| create-snapshot.sh | 0/70 | 0/20 | 0/4 | 0% | Not Tested |
| rollback-workflow.sh | 0/110 | 0/35 | 0/7 | 0% | Not Tested |
| stack-detection.py | 0/180 | 0/50 | 0/12 | 0% | Not Tested |

**Overall Coverage:** 0% (baseline before testing)

**Note:** Coverage will be measured during Phase-specific unit testing (Weeks 1-11).

### Feature Coverage

| Feature | Test Cases | Pass | Fail | Coverage |
|---------|-----------|------|------|----------|
| Specialist Agents | 10 | 0 | 0 | 0% |
| Additional Workflows | 8 | 0 | 0 | 0% |
| Stack Profiles | 12 | 0 | 0 | 0% |
| Index Optimizations | 8 | 0 | 0 | 0% |
| Multi-Workflow State | 10 | 0 | 0 | 0% |
| Error Recovery | 5 | 0 | 0 | 0% |
| **Total** | **53** | **0** | **0** | **0%** |

---

## 11. ENTRY & EXIT CRITERIA

### Entry Criteria

Before testing can begin:
- [x] v0.1 complete and validated (PRD Section 3 checklist 100%)
- [ ] All v0.2 components implemented (20+ components from TDD)
- [ ] Test environment setup complete (test-setup.sh passes)
- [ ] Test projects initialized (TypeScript + Python)
- [ ] Automated test suite ready (all scripts in test-scenarios/)

### Exit Criteria

Testing is complete when:
- [ ] All 6 test scenarios pass (100% pass rate)
- [ ] All 53 test cases pass (100% pass rate)
- [ ] Edge cases handled gracefully (no crashes)
- [ ] Performance targets met (PT-001 to PT-004 pass)
- [ ] ≥90% code coverage achieved (unit tests)
- [ ] No critical bugs remain (all fixed or deferred with mitigation)
- [ ] Regression tests pass (v0.1 functionality preserved)

---

## 12. DEFECT TRACKING

### Defects Found

| ID | Severity | Component | Description | Status | Assigned To |
|----|----------|-----------|-------------|--------|-------------|
| - | - | - | (No defects found yet - testing not started) | - | - |

**Defect Severity Levels:**
- **Critical:** Blocks release, data loss, crashes
- **High:** Major functionality broken, workaround exists
- **Medium:** Minor functionality affected, usability issue
- **Low:** Cosmetic, documentation error

---

## 13. RISKS

| Risk | Impact | Mitigation |
|------|--------|------------|
| v0.1 incomplete/buggy | Testing blocked, results invalid | Validate v0.1 checklist 100% before starting (ENTRY CRITERION) |
| Agent responses non-deterministic | Tests flaky, hard to automate | Mock Claude API for unit tests, use real API for integration tests |
| Test environment drift | Tests pass locally, fail CI | Dockerize test environment, pin all versions |
| Performance tests variable | Results inconsistent | Run 10 times, report avg/min/max, allow ±20% variance |
| Test execution time long | Feedback loop slow | Parallelize tests, run unit tests per phase (not all at once) |

---

## 14. TEST RESULTS SUMMARY

**Execution Date:** [TBD]

**Results:**
- Total Test Cases: 53
- Passed: 0 (0%)
- Failed: 0 (0%)
- Blocked: 0 (0%)
- Not Run: 53 (100%)

**Test Scenarios:**
- TS-001 (Multi-Workflow): Not Run
- TS-002 (TypeScript Stack): Not Run
- TS-003 (Python Stack): Not Run
- TS-004 (Agent Coordination): Not Run
- TS-005 (Index Optimizations): Not Run
- TS-006 (Error Recovery): Not Run

**Defects:**
- Critical: 0
- High: 0
- Medium: 0
- Low: 0

**Recommendation:** [Pending - testing not started]

**Reason:** [Pending - awaiting Phase 1-6 implementation completion]

---

## 15. LESSONS LEARNED

(To be filled after test execution)

- [Lesson 1]
- [Lesson 2]
- [Lesson 3]

---

**Document Status:** Active (Awaiting Implementation Completion)
**Next Steps:** Begin Phase 1 implementation, start unit testing per phase

---

**Prepared By:** spec-drive Planning Team
**Reviewed By:** [Pending]
**Approved By:** [Pending]
**Date:** 2025-11-01
