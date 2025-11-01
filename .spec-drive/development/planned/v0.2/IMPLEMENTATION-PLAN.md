# SPEC-DRIVE v0.2 IMPLEMENTATION PLAN

**Version:** 1.0
**Date:** 2025-11-01
**Status:** Active
**Related PRD:** `.spec-drive/development/planned/v0.2/PRD.md`
**Related TDD:** `.spec-drive/development/planned/v0.2/TDD.md`

---

## 1. EXECUTIVE SUMMARY

### Overview

This implementation plan defines the phased rollout of spec-drive v0.2, which adds 6 major enhancements to the v0.1 foundation:

1. **Specialist Agents** (spec-agent, impl-agent, test-agent)
2. **Additional Workflows** (Bugfix, Research)
3. **Stack Profiles** (Python/FastAPI, Go, Rust)
4. **Index Optimizations** (AI summaries, queries, changes)
5. **Multi-Workflow State** (Concurrent workflows with conflict detection)
6. **Error Recovery** (Auto-retry, rollback, resume)

### Timeline

**Total Duration:** 7 weeks (conservative, sequential phases)

| Phase | Duration | Start | End | Status |
|-------|----------|-------|-----|--------|
| Pre-Phase: v0.1 Validation | 1 week | Week 0 | Week 0 | Not Started |
| Phase 1: Specialist Agents | 2 weeks | Week 1 | Week 2 | Not Started |
| Phase 2: Additional Workflows | 1 week | Week 3 | Week 3 | Not Started |
| Phase 3: Stack Profiles | 2 weeks | Week 4 | Week 5 | Not Started |
| Phase 4: Index Optimizations | 2 weeks | Week 6 | Week 7 | Not Started |
| Phase 5: Multi-Workflow State | 2 weeks | Week 8 | Week 9 | Not Started |
| Phase 6: Error Recovery | 2 weeks | Week 10 | Week 11 | Not Started |
| Integration Testing | 1 week | Week 12 | Week 12 | Not Started |

**Note:** Timeline assumes sequential execution per user preference (conservative approach). Phases 1-3 could run partially in parallel for 5-6 week timeline if resources allow.

### Success Criteria

- ✅ All 33 tasks completed
- ✅ All 6 test scenarios pass (100% pass rate)
- ✅ Performance targets met (90% context reduction, <10s summaries, <1s switching)
- ✅ ≥80% auto-retry success rate
- ✅ ≥90% code coverage
- ✅ No critical or high-priority bugs

---

## 2. PHASE OVERVIEW

### Phase Dependency Diagram

```
                  PRE-PHASE: v0.1 Validation (Week 0)
                               ↓ (HARD BLOCKER)
                  ┌─────────────────────────┐
                  │  Phase 1: Specialist    │
                  │  Agents (Weeks 1-2)     │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Phase 2: Additional    │
                  │  Workflows (Week 3)     │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Phase 3: Stack         │
                  │  Profiles (Weeks 4-5)   │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Phase 4: Index         │
                  │  Optimizations (Weeks   │
                  │  6-7)                   │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Phase 5: Multi-Workflow│
                  │  State (Weeks 8-9)      │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Phase 6: Error         │
                  │  Recovery (Weeks 10-11) │
                  └─────────────┬───────────┘
                                ↓
                  ┌─────────────────────────┐
                  │  Integration Testing    │
                  │  (Week 12)              │
                  └─────────────────────────┘
```

**Critical Path:** Pre-Phase → Phase 1 → Phase 2 → Phase 5 → Phase 6 → Integration
- Phases 3 and 4 can partially overlap with earlier phases if resources allow, but kept sequential for conservative timeline

---

## 3. PRE-PHASE: v0.1 VALIDATION

### Duration: 1 week (Week 0)

### Objective

**CRITICAL:** Validate v0.1 is 100% complete, tested, and verified before ANY v0.2 work begins. This is a HARD BLOCKER per RISK-001.

### Tasks

1. **Complete v0.1 Dependency Checklist** (PRD Section 3)
   - Verify all 150+ checklist items complete
   - Run all v0.1 integration test scenarios (4 scenarios)
   - Validate all 14 v0.1 success criteria met

2. **Run v0.1 Regression Suite**
   - Feature workflow (TypeScript/React project)
   - Feature workflow (Python/FastAPI project)
   - App-new workflow (new project)
   - All 4 quality gates enforce correctly

3. **Performance Baseline**
   - Measure context usage (baseline for 90% reduction target)
   - Measure workflow completion time (baseline for velocity improvement)

4. **Bug Triage**
   - Close all critical and high-priority v0.1 bugs
   - Document known minor bugs (mitigation plans)

### Entry Criteria

- v0.1 implementation claims to be complete

### Exit Criteria

- ✅ v0.1 checklist 100% complete (PRD Section 3.8)
- ✅ All 4 v0.1 integration test scenarios pass
- ✅ No critical or high-priority v0.1 bugs remain
- ✅ Performance baseline measured and documented

### Deliverables

- **v0.1 Validation Report** (pass/fail for each checklist item)
- **Baseline Metrics Document** (context usage, workflow time)
- **v0.1 Bug Triage Summary** (closed bugs, known issues)

### Risk

**If Exit Criteria Not Met:**
- **STOP v0.2 development immediately**
- Prioritize v0.1 completion (finish outstanding tasks)
- Re-validate after fixes
- Accept timeline delay (Week 0 extends until v0.1 complete)

---

## 4. PHASE 1: SPECIALIST AGENTS

### Duration: 2 weeks (Weeks 1-2)

### Objective

Implement 3 specialist agents (spec-agent, impl-agent, test-agent) that automate 60%+ of workflow tasks.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-001 | Create spec-agent.md | 6 hours | v0.1 complete | Agent Lead |
| TASK-002 | Create impl-agent.md | 8 hours | TASK-001 | Agent Lead |
| TASK-003 | Create test-agent.md | 8 hours | TASK-001 | Agent Lead |
| TASK-004 | Implement validate-spec.js | 4 hours | TASK-001 | Tools Lead |
| TASK-005 | Integrate agents into feature workflow | 12 hours | TASK-001,002,003 | Workflow Lead |

**Total Estimated Effort:** 38 hours (~5 days with buffer)

### Implementation Details

**Week 1:**
- Days 1-2: Create spec-agent.md
  - Define agent prompt template
  - Include stack profile variable placeholders
  - Specify validation rules (no [NEEDS CLARIFICATION])
  - Test on sample requirements

- Days 3-4: Create impl-agent.md + test-agent.md
  - impl-agent: Stack-aware code generation
  - test-agent: TDD-first test creation
  - Both: @spec tag injection

- Day 5: Implement validate-spec.js
  - YAML parsing
  - Validation rules (ACs format, no ambiguities)
  - Exit codes for pass/fail

**Week 2:**
- Days 1-3: Integrate agents into feature workflow
  - Modify feature.sh orchestrator
  - Add agent delegation at stage boundaries
  - Test end-to-end with TypeScript project

- Days 4-5: Testing and refinement
  - Run TS-004 (Agent Coordination scenario)
  - Measure automation percentage (target: 60%+)
  - Tune agent prompts based on output quality

### Entry Criteria

- v0.1 validation complete (Pre-Phase exit criteria met)
- Agent markdown template structure defined
- Claude Code Task tool available for subagent delegation

### Exit Criteria

- ✅ All 3 agent .md files created and tested
- ✅ validate-spec.js validates specs correctly
- ✅ feature.sh delegates to agents successfully
- ✅ TS-004 test scenario passes
- ✅ Automation ≥60% measured (user provides requirements + approval only)
- ✅ Unit tests pass (≥90% coverage for validate-spec.js)

### Deliverables

- `spec-drive/agents/spec-agent.md`
- `spec-drive/agents/impl-agent.md`
- `spec-drive/agents/test-agent.md`
- `spec-drive/scripts/tools/validate-spec.js`
- `spec-drive/scripts/workflows/feature.sh` (enhanced)
- Unit tests: `tests/unit/validate-spec.test.js`

### Risks

- **Agent outputs low quality:** Mitigation: Iterate on prompts, collect feedback
- **60% automation not achieved:** Mitigation: Lower expectations to 40%, defer improvement to v0.3
- **Integration complexity:** Mitigation: Prototype delegation early (Day 1)

---

## 5. PHASE 2: ADDITIONAL WORKFLOWS

### Duration: 1 week (Week 3)

### Objective

Implement bugfix and research workflows to expand workflow coverage from 1 (feature) to 3 types.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-010 | Create BUG-TEMPLATE.yaml | 2 hours | Phase 1 complete | Workflow Lead |
| TASK-011 | Implement bugfix workflow | 16 hours | TASK-010 | Workflow Lead |
| TASK-012 | Implement research workflow | 12 hours | None | Workflow Lead |
| TASK-013 | Create bugfix quality gates | 10 hours | TASK-011 | QA Lead |

**Total Estimated Effort:** 40 hours (~5 days with buffer)

### Implementation Details

**Days 1-2: Bugfix Workflow**
- Create BUG-TEMPLATE.yaml (symptom, investigation, fix_approach, trace)
- Implement bugfix.sh orchestrator (4 stages: investigate → specify-fix → fix → verify)
- Create bugfix command: `/spec-drive:bugfix BUG-ID "symptom"`
- Test on real bug (expired token scenario from TEST-PLAN)

**Days 3-4: Research Workflow**
- Implement research.sh orchestrator (3 stages: explore → synthesize → decide)
- Add timebox enforcement (warn at 80%, stop at 100%)
- Create research command: `/spec-drive:research "topic" "timebox"`
- Test with "auth provider selection" research
- Verify ADR-XXXX.md generated

**Day 5: Quality Gates**
- Create gate-1-bugfix-specify.sh (lighter than feature gates)
- Create gate-2-bugfix-implement.sh (regression test mandatory)
- Create gate-3-bugfix-verify.sh (verify fix + no side effects)
- Test gates with bugfix workflow

### Entry Criteria

- Phase 1 complete (agents available)
- ADR template exists (from v0.1)

### Exit Criteria

- ✅ Bugfix workflow completes end-to-end (TS-001 partial test)
- ✅ Research workflow produces ADR
- ✅ Bugfix quality gates enforce correctly
- ✅ Priority auto-set: bugfix=0, research=7
- ✅ Unit tests pass (workflow orchestrators)

### Deliverables

- `spec-drive/templates/BUG-TEMPLATE.yaml`
- `spec-drive/commands/bugfix.md`
- `spec-drive/commands/research.md`
- `spec-drive/scripts/workflows/bugfix.sh`
- `spec-drive/scripts/workflows/research.sh`
- `spec-drive/skills/orchestrator/workflows/bugfix.yaml`
- `spec-drive/skills/orchestrator/workflows/research.yaml`
- `spec-drive/scripts/gates/gate-*-bugfix-*.sh` (3 gates)

### Risks

- **Bugfix workflow too similar to feature:** Mitigation: Emphasize speed (lighter gates)
- **Research timebox not enforced:** Mitigation: Add strict timer, force-stop at 100%

---

## 6. PHASE 3: STACK PROFILES

### Duration: 2 weeks (Weeks 4-5)

### Objective

Add 3 new stack profiles (Python/FastAPI, Go, Rust) and enhance TypeScript/React profile with stack-specific quality gates and conventions.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-020 | Create python-fastapi.yaml profile | 8 hours | None | Stack Lead |
| TASK-021 | Create go.yaml profile | 8 hours | None | Stack Lead |
| TASK-022 | Create rust.yaml profile | 8 hours | None | Stack Lead |
| TASK-023 | Enhance stack-detection.py | 12 hours | TASK-020,021,022 | Stack Lead |
| TASK-024 | Integrate profiles with quality gates | 16 hours | TASK-020,021,022,023 | QA Lead |

**Total Estimated Effort:** 52 hours (~7 days with buffer)

### Implementation Details

**Week 1: Profile Creation**
- Days 1-2: Create python-fastapi.yaml
  - Detection: requirements.txt + fastapi dependency
  - Quality gates: pytest, mypy, black, pylint
  - Patterns: async def, Pydantic models, HTTPException
  - Conventions: snake_case, type hints
  - Examples: Endpoint, test

- Days 3-4: Create go.yaml + rust.yaml
  - Go: go.mod, go test, go vet, go fmt
  - Rust: Cargo.toml, cargo test, clippy, rustfmt
  - Patterns and conventions per stack

- Day 5: Enhance stack-detection.py
  - Add detection heuristics for 3 new stacks
  - Multiple indicators (files + content patterns)
  - Confidence scoring
  - Monorepo support (detect multiple stacks)

**Week 2: Integration**
- Days 1-3: Integrate profiles with quality gates
  - Modify gate-*.sh scripts
  - Replace hardcoded commands with {STACK_QUALITY_GATES} variables
  - Load profile, inject variables (envsubst)
  - Test on TypeScript, Python, Go, Rust projects

- Days 4-5: Testing
  - Run TS-002 (TypeScript stack profile)
  - Run TS-003 (Python stack profile)
  - Verify fallback to generic profile works
  - Verify stack-specific conventions enforced

### Entry Criteria

- v0.1 stack-detection.py exists (basic TypeScript detection)
- Test projects available (Python, Go, Rust)

### Exit Criteria

- ✅ 4 stack profiles complete (TypeScript, Python, Go, Rust)
- ✅ Auto-detection works for all 4 stacks (≥90% accuracy)
- ✅ Stack-specific gates enforce correctly
- ✅ Fallback to generic profile works
- ✅ TS-002 and TS-003 test scenarios pass
- ✅ Unit tests pass (stack-detection.py ≥90% coverage)

### Deliverables

- `spec-drive/stack-profiles/python-fastapi.yaml`
- `spec-drive/stack-profiles/go.yaml`
- `spec-drive/stack-profiles/rust.yaml`
- `spec-drive/stack-profiles/typescript-react.yaml` (enhanced from v0.1)
- `spec-drive/scripts/stack-detection.py` (enhanced)
- `spec-drive/scripts/gates/gate-*.sh` (stack-aware)
- Unit tests: `tests/unit/stack-detection.test.py`

### Risks

- **Detection accuracy <90%:** Mitigation: Tune heuristics, add manual override
- **Profile variable injection complex:** Mitigation: Use simple envsubst, no template engine

---

## 7. PHASE 4: INDEX OPTIMIZATIONS

### Duration: 2 weeks (Weeks 6-7)

### Objective

Enhance index.yaml v2.0 with AI summaries, pre-answered queries, and changes feed to achieve ≥90% context reduction.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-030 | Implement generate-summaries.js | 12 hours | None | Index Lead |
| TASK-031 | Update index.yaml schema to v2.0 | 6 hours | None | Index Lead |
| TASK-032 | Implement update-index-queries.js | 10 hours | TASK-031 | Index Lead |
| TASK-033 | Implement update-index-changes.js | 8 hours | TASK-031 | Index Lead |
| TASK-034 | Enhance post-tool-use.sh hook | 8 hours | TASK-030,033 | Hooks Lead |
| TASK-035 | Performance test index optimizations | 12 hours | TASK-030-034 | QA Lead |

**Total Estimated Effort:** 56 hours (~8 days with buffer)

### Implementation Details

**Week 1: Core Implementation**
- Days 1-3: Implement generate-summaries.js
  - Claude API integration (via Task tool, Haiku model)
  - Summary generation (1-2 sentences, max 200 chars)
  - Timeout handling (10s per summary, skip on timeout)
  - Batch processing (10 files at a time)

- Day 4: Update index.yaml schema to v2.0
  - Add summary field to components[], specs[], docs[], code[]
  - Add queries{} section
  - Add changes[] array (FIFO, max 20)
  - Update index-template.yaml

- Day 5: Implement update-index-queries.js
  - Define 10-20 common queries (hardcoded initially)
  - Generate pre-answered responses from index data
  - Update index.yaml queries{} section

**Week 2: Integration and Testing**
- Days 1-2: Implement update-index-changes.js
  - Parse git log (last 20 commits)
  - Extract: timestamp, commit_hash, message, files, diff stats, spec_id
  - Update index.yaml changes[] array (FIFO)

- Days 3-4: Enhance post-tool-use.sh hook
  - Trigger generate-summaries.js on file writes (if dirty flag)
  - Trigger update-index-changes.js on git commits
  - Async execution (non-blocking)

- Day 5: Performance testing
  - Run PT-001 (Summary generation time <10s)
  - Run PT-002 (Context reduction ≥90%)
  - Run TS-005 (Index optimizations scenario)
  - Tune performance if targets not met

### Entry Criteria

- v0.1 index.yaml exists (basic structure)
- Claude Code Task tool available (for AI summaries)

### Exit Criteria

- ✅ AI summaries generated for all index entries
- ✅ Context reduction ≥90% measured (PT-002)
- ✅ Summary generation <10s per file (PT-001)
- ✅ Pre-answered queries work (instant responses)
- ✅ Changes feed tracks updates (last 20)
- ✅ TS-005 test scenario passes
- ✅ Unit tests pass (all 4 tools ≥90% coverage)

### Deliverables

- `spec-drive/scripts/tools/generate-summaries.js`
- `spec-drive/scripts/tools/update-index-queries.js`
- `spec-drive/scripts/tools/update-index-changes.js`
- `spec-drive/templates/index-template.yaml` (v2.0)
- `spec-drive/hooks/handlers/post-tool-use.sh` (enhanced)
- Unit tests: `tests/unit/generate-summaries.test.js`, etc.

### Risks

- **Summary generation too slow:** Mitigation: Use Haiku, batch processing, async execution
- **Context reduction <90%:** Mitigation: Accept 80%, defer improvement to v0.3
- **Summary accuracy low:** Mitigation: Allow manual override, regeneration

---

## 8. PHASE 5: MULTI-WORKFLOW STATE

### Duration: 2 weeks (Weeks 8-9)

### Objective

Enable 3+ concurrent workflows with priority management, file lock tracking, and conflict detection.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-040 | Update state.yaml schema to v2.0 | 6 hours | Phase 1-2 complete | State Lead |
| TASK-041 | Implement workflow-queue.js | 12 hours | TASK-040 | State Lead |
| TASK-042 | Implement detect-conflicts.js | 10 hours | TASK-040 | State Lead |
| TASK-043 | Implement /spec-drive:switch command | 12 hours | TASK-041,042 | Command Lead |
| TASK-044 | Implement /spec-drive:prioritize command | 4 hours | TASK-041 | Command Lead |
| TASK-045 | Implement /spec-drive:abandon command | 6 hours | TASK-041 | Command Lead |
| TASK-046 | Integration test multi-workflow | 14 hours | TASK-040-045 | QA Lead |

**Total Estimated Effort:** 64 hours (~9 days with buffer)

### Implementation Details

**Week 1: Core Implementation**
- Days 1-2: Update state.yaml schema to v2.0
  - Add workflows{} map (id → workflow object)
  - Add priority, files_locked[], snapshots[], retry_history[]
  - Maintain backward compatibility (current_* fields)

- Days 3-4: Implement workflow-queue.js
  - CRUD operations on workflows{} (add, list, remove, prioritize)
  - Priority sorting (0=highest, 9=lowest)
  - Atomic updates (file locking)
  - Max 10 workflows validation

- Day 5: Implement detect-conflicts.js
  - Compare files_locked[] arrays
  - Return conflict status + conflicting files
  - O(n*m) algorithm (acceptable for small arrays)

**Week 2: Commands and Testing**
- Days 1-2: Implement /spec-drive:switch command
  - Detect conflicts before switch
  - Warn user if conflicts exist
  - Require commit or --force flag for conflict switch
  - Update current_spec in state.yaml

- Days 3-4: Implement /spec-drive:prioritize and /spec-drive:abandon
  - prioritize: Update priority field
  - abandon: Move workflow to history, cleanup state

- Day 5: Integration testing
  - Run TS-001 (Multi-workflow concurrent development)
  - Test 3+ workflows simultaneously
  - Verify conflict detection works
  - Verify no state corruption

### Entry Criteria

- Phases 1-2 complete (workflows available to manage)
- state.yaml v1.0 exists (from v0.1)

### Exit Criteria

- ✅ state.yaml v2.0 supports multi-workflow
- ✅ 3+ workflows active simultaneously (TS-001)
- ✅ Conflict detection works (no false positives/negatives)
- ✅ Priority ordering correct (bugfix=0 always highest)
- ✅ Switch, prioritize, abandon commands work
- ✅ No state corruption (atomic updates)
- ✅ Unit tests pass (all tools ≥90% coverage)

### Deliverables

- `spec-drive/scripts/tools/workflow-queue.js`
- `spec-drive/scripts/tools/detect-conflicts.js`
- `spec-drive/commands/switch.md`
- `spec-drive/commands/prioritize.md`
- `spec-drive/commands/abandon.md`
- Unit tests: `tests/unit/workflow-queue.test.js`, `detect-conflicts.test.js`

### Risks

- **State corruption frequent:** Mitigation: Atomic updates, snapshots, validation on load
- **Conflict detection false positives:** Mitigation: Tune algorithm, user override

---

## 9. PHASE 6: ERROR RECOVERY

### Duration: 2 weeks (Weeks 10-11)

### Objective

Implement auto-retry (with exponential backoff), rollback, and resume mechanisms to achieve ≥80% automatic recovery rate.

### Tasks

| Task ID | Task Name | Duration | Dependencies | Owner |
|---------|-----------|----------|--------------|-------|
| TASK-050 | Implement retry-gate.sh | 10 hours | Phase 5 complete | Recovery Lead |
| TASK-051 | Implement create-snapshot.sh | 8 hours | Phase 5 (state v2.0) | Recovery Lead |
| TASK-052 | Implement restore-snapshot.sh | 8 hours | TASK-051 | Recovery Lead |
| TASK-053 | Implement rollback-workflow.sh | 12 hours | TASK-052 | Recovery Lead |
| TASK-054 | Implement /spec-drive:rollback command | 4 hours | TASK-053 | Command Lead |
| TASK-055 | Enhance session-start.sh for resume | 10 hours | TASK-051 | Hooks Lead |
| TASK-056 | Integration test error recovery | 16 hours | TASK-050-055 | QA Lead |

**Total Estimated Effort:** 68 hours (~10 days with buffer)

### Implementation Details

**Week 1: Retry and Snapshots**
- Days 1-2: Implement retry-gate.sh
  - Max 3 retries with exponential backoff (1s, 5s, 15s)
  - Apply auto-fixes (lint --fix, format)
  - Only retry recoverable errors
  - Track retry history in state.yaml

- Days 3-4: Implement create-snapshot.sh + restore-snapshot.sh
  - Create snapshot at stage boundaries
  - Capture: stage, timestamp, files_modified, git_commit
  - Store in state.yaml (nested, max 5 per workflow, FIFO)
  - Restore: Load snapshot, revert git changes

- Day 5: Implement rollback-workflow.sh
  - Load snapshot for target stage
  - git reset --hard to snapshot commit
  - Update state.yaml (stage, clear future snapshots)
  - User confirmation required (destructive operation)

**Week 2: Resume and Testing**
- Days 1-2: Implement /spec-drive:rollback command
  - Wrapper around rollback-workflow.sh
  - Usage: `/spec-drive:rollback SPEC-ID STAGE`

- Days 3-4: Enhance session-start.sh for resume
  - Detect interrupted workflows (interrupted: true)
  - Prompt user: "Resume SPEC-ID from 'stage'? (y/N)"
  - Restore workflow state from snapshot
  - Clear interrupted flag

- Day 5: Integration testing
  - Run TS-006 (Error recovery scenario)
  - Test auto-retry (linting errors → auto-fix → pass)
  - Test rollback (critical failure → rollback to previous stage)
  - Test resume (interrupted workflow → resume on next session)
  - Measure recovery rate (target: ≥80%)

### Entry Criteria

- Phase 5 complete (state.yaml v2.0 with snapshots support)
- Git operations available (reset, revert)

### Exit Criteria

- ✅ Auto-retry fixes simple errors (≥80% success rate)
- ✅ Max 3 retries enforced (no infinite loops)
- ✅ Rollback restores previous stage successfully
- ✅ Resume works after interruption
- ✅ TS-006 test scenario passes
- ✅ Recovery rate ≥80% measured
- ✅ Unit tests pass (all scripts ≥90% coverage)

### Deliverables

- `spec-drive/scripts/tools/retry-gate.sh`
- `spec-drive/scripts/tools/create-snapshot.sh`
- `spec-drive/scripts/tools/restore-snapshot.sh`
- `spec-drive/scripts/tools/rollback-workflow.sh`
- `spec-drive/commands/rollback.md`
- `spec-drive/hooks/handlers/session-start.sh` (enhanced)
- Unit tests: `tests/unit/retry-gate.test.sh`, etc.

### Risks

- **Retry success rate <80%:** Mitigation: Tune auto-fix logic, identify more recoverable errors
- **Rollback data loss:** Mitigation: User confirmation, warn about uncommitted changes

---

## 10. INTEGRATION TESTING

### Duration: 1 week (Week 12)

### Objective

Run all 6 test scenarios end-to-end, validate performance targets, ensure no regressions.

### Tasks

1. **Run All Test Scenarios** (Days 1-3)
   - TS-001: Multi-Workflow Concurrent Development
   - TS-002: Stack Profile Enforcement (TypeScript/React)
   - TS-003: Stack Profile Enforcement (Python/FastAPI)
   - TS-004: Specialist Agent Coordination
   - TS-005: Index Optimizations
   - TS-006: Error Recovery

2. **Run Performance Tests** (Day 4)
   - PT-001: AI Summary Generation Time (<10s)
   - PT-002: Context Reduction (≥90%)
   - PT-003: Context Switching Time (<1s)
   - PT-004: Index Update Time (<5s)

3. **Regression Testing** (Day 5)
   - Run v0.1 test scenarios (ensure backward compatibility)
   - Verify v0.1 functionality preserved
   - No critical bugs introduced

4. **Bug Triage and Fixes** (Throughout week)
   - Log all defects found
   - Prioritize: Critical → High → Medium → Low
   - Fix critical and high bugs before release
   - Defer medium/low bugs (document in known issues)

### Entry Criteria

- All 6 phases complete (Phases 1-6)
- Automated test suite ready (test-scenarios/*.sh)
- Test environment setup complete

### Exit Criteria

- ✅ All 6 test scenarios pass (100% pass rate)
- ✅ All 4 performance tests meet targets
- ✅ v0.1 regression tests pass (backward compatibility)
- ✅ No critical or high-priority bugs remain
- ✅ Code coverage ≥90% (unit tests)
- ✅ Test results documented in TEST-PLAN.md

### Deliverables

- **Test Results Report** (all scenarios pass/fail)
- **Performance Metrics Report** (PT-001 to PT-004 results)
- **Bug Triage Summary** (critical/high fixed, medium/low deferred)
- **Release Readiness Assessment** (go/no-go decision)

---

## 11. MILESTONES

| Milestone | Target Date | Description | Success Criteria |
|-----------|-------------|-------------|------------------|
| M0: v0.1 Validated | End of Week 0 | v0.1 complete and tested | v0.1 checklist 100%, all tests pass |
| M1: Agents Working | End of Week 2 | Specialist agents automate 60%+ tasks | TS-004 passes, automation ≥60% |
| M2: 3 Workflows Operational | End of Week 3 | Feature, bugfix, research workflows | All 3 workflows complete end-to-end |
| M3: 4 Stacks Supported | End of Week 5 | Stack profiles enforce conventions | TS-002, TS-003 pass, 4 profiles work |
| M4: 90% Context Reduction | End of Week 7 | Index optimizations achieve target | PT-002 passes, context <1KB |
| M5: Multi-Workflow Tested | End of Week 9 | 3+ workflows concurrent, no conflicts | TS-001 passes, conflict detection works |
| M6: Error Recovery Working | End of Week 11 | 80%+ auto-retry success rate | TS-006 passes, recovery ≥80% |
| M7: Integration Complete | End of Week 12 | All tests pass, no critical bugs | All 6 scenarios pass, performance targets met |
| M8: v0.2 Released | Week 13 | v0.2 published to marketplace | Plugin available, docs published |

---

## 12. RESOURCE REQUIREMENTS

### Phase 1: Specialist Agents

**Team:**
- 1 Agent Lead (full-time, 2 weeks)
- 1 Tools Lead (part-time, 1 day)
- 1 Workflow Lead (part-time, 3 days)

**Infrastructure:**
- Claude Code CLI (latest version)
- Test TypeScript/React project
- Claude API access (for testing agents)

---

### Phase 2: Additional Workflows

**Team:**
- 1 Workflow Lead (full-time, 1 week)
- 1 QA Lead (part-time, 1 day)

**Infrastructure:**
- Git repository
- Test projects (TypeScript, Python)

---

### Phase 3: Stack Profiles

**Team:**
- 1 Stack Lead (full-time, 2 weeks)
- 1 QA Lead (part-time, 2 days)

**Infrastructure:**
- Test projects: Python/FastAPI, Go, Rust
- Python ≥3.9, Go ≥1.19, Rust ≥1.70

---

### Phase 4: Index Optimizations

**Team:**
- 1 Index Lead (full-time, 2 weeks)
- 1 Hooks Lead (part-time, 1 day)
- 1 QA Lead (part-time, 1 day)

**Infrastructure:**
- Claude API access (for AI summaries)
- Test projects with code to summarize

---

### Phase 5: Multi-Workflow State

**Team:**
- 1 State Management Lead (full-time, 2 weeks)
- 1 Command Lead (part-time, 2 days)
- 1 QA Lead (part-time, 1 day)

**Infrastructure:**
- Git repository
- Multiple test workflows

---

### Phase 6: Error Recovery

**Team:**
- 1 Error Recovery Lead (full-time, 2 weeks)
- 1 Command Lead (part-time, 1 day)
- 1 Hooks Lead (part-time, 1 day)
- 1 QA Lead (part-time, 1 day)

**Infrastructure:**
- Git repository (for rollback testing)
- Test scenarios with intentional errors

---

### Integration Testing

**Team:**
- 1 QA Lead (full-time, 1 week)
- 1 Developer (on-call for bug fixes)

**Infrastructure:**
- CI/CD environment (for automated tests)
- Clean test projects

---

## 13. DEPENDENCIES & BLOCKERS

### External Dependencies

| Dependency | Impact if Unavailable | Mitigation |
|------------|---------------------|------------|
| Claude Code CLI | Cannot test plugin | Pin version, test before each phase |
| Claude API (for summaries) | Index optimizations blocked | Use Haiku (cheaper), cache aggressively |
| Git | Rollback/changes feed blocked | Required tool, verify installation |
| Node.js ≥18 | JavaScript tools fail | Document requirement, check on init |
| Python ≥3.9 | Stack detection fails | Fallback to generic profile |

### Internal Dependencies

| Component | Depends On | Risk | Mitigation |
|-----------|------------|------|------------|
| Phases 1-6 | v0.1 complete (Pre-Phase) | v0.1 incomplete blocks ALL work | HARD BLOCKER, validate first (Week 0) |
| Phase 2 | Phase 1 (agents) | Workflows can use agents | Agents optional, workflows work without |
| Phase 5 | Phases 1-2 (workflows) | Need workflows to manage | Critical dependency, enforce |
| Phase 6 | Phase 5 (state v2.0) | Snapshots need v2.0 structure | Critical dependency, enforce |
| Integration Testing | Phases 1-6 | All features needed for tests | Critical dependency, enforce |

---

## 14. RISK MANAGEMENT

### Top 5 Risks

1. **v0.1 Incomplete (RISK-001):** CRITICAL
   - Mitigation: Pre-Phase validation (Week 0)
   - Contingency: Stop v0.2, complete v0.1 first

2. **Timeline Delay:** HIGH
   - Mitigation: Conservative estimates (7 weeks vs 5)
   - Contingency: Defer non-critical features to v0.3

3. **Agent Quality Low (RISK-002):** CRITICAL
   - Mitigation: Iterate on prompts, collect feedback (Phase 1)
   - Contingency: Reduce automation expectations (40% vs 60%)

4. **State Corruption (RISK-003):** CRITICAL
   - Mitigation: Atomic updates, snapshots (Phase 5)
   - Contingency: Rollback feature limits damage

5. **Performance Targets Missed:** MEDIUM
   - Mitigation: Tune throughout development, performance testing (Week 12)
   - Contingency: Accept 80% context reduction (vs 90%)

**Risk Monitoring:** Review weekly in STATUS.md updates

---

## 15. CHANGE MANAGEMENT

### Scope Change Process

1. **Proposal:** Change requested (feature addition, scope reduction)
2. **Impact Analysis:** Estimate effort, timeline impact, dependencies
3. **Decision:** Approve/reject (must meet success criteria)
4. **Documentation:** Update IMPLEMENTATION-PLAN.md, STATUS.md
5. **Communication:** Notify team, adjust tasks

### Approved Changes

| Date | Change | Reason | Impact | Approved By |
|------|--------|--------|--------|-------------|
| - | - | - | - | (No changes yet - planning phase) |

---

## 16. QUALITY GATES

### Phase Completion Gates

**Each phase must pass quality gate before next phase begins:**

- ✅ All tasks complete (STATUS.md shows 100%)
- ✅ Unit tests pass (≥90% coverage)
- ✅ Integration tests pass (relevant test scenarios)
- ✅ No critical bugs remain
- ✅ Deliverables committed to repo
- ✅ Documentation updated (TDD, TEST-PLAN if needed)

**Phase-Specific Gates:**
- Phase 1: TS-004 passes, automation ≥60%
- Phase 2: Bugfix + research workflows complete end-to-end
- Phase 3: TS-002, TS-003 pass, 4 stacks work
- Phase 4: PT-001, PT-002 pass, context ≥90% reduction
- Phase 5: TS-001 passes, 3+ workflows concurrent
- Phase 6: TS-006 passes, recovery ≥80%

---

## 17. COMMUNICATION PLAN

### Weekly Status Updates

**Format:** Update STATUS.md weekly with:
- Tasks completed this week
- Tasks in progress
- Tasks blocked
- Risks/issues
- Next week plan

**Distribution:** Commit STATUS.md to repo (visible to all)

### Milestone Reviews

**Trigger:** Each milestone completion (M1-M8)

**Agenda:**
- Review milestone success criteria (met/not met)
- Demo working features
- Discuss blockers
- Adjust timeline if needed

### Daily Standups (Optional)

**If team >1 person:**
- Yesterday: What tasks completed
- Today: What working on
- Blockers: Any issues

---

## 18. ROLLOUT STRATEGY

### Phased Deployment

**Per-Phase Rollback:**
- Each phase independent (can rollback without affecting others)
- Rollback: Revert commits for that phase, restore v0.1 or previous phase behavior

**Emergency Rollback:**
- Critical bug discovered: Revert entire v0.2 plugin
- Preserve user data: Export state.yaml, specs
- Restore v0.1 plugin
- Fix bug, re-deploy v0.2

### Feature Flags (Future v0.3)

**Not in v0.2, but planned:**
- Enable/disable enhancements per project
- Allow gradual rollout (enable agents for some users, not all)

---

## 19. SUCCESS METRICS

### Definition of Done (v0.2 Release)

- ✅ All 33 tasks completed (100%)
- ✅ All 6 test scenarios pass (100% pass rate)
- ✅ All 4 performance tests meet targets
- ✅ Code coverage ≥90% (unit tests)
- ✅ No critical or high-priority bugs
- ✅ v0.1 backward compatibility preserved (regression tests pass)
- ✅ Documentation complete (TDD, TEST-PLAN, RISK-ASSESSMENT, STATUS, 6 ADRs)
- ✅ Plugin published to Claude Code marketplace

### Post-Release Metrics (Week 13+)

**Track for 1 month post-release:**
- User adoption rate (downloads, active users)
- Workflow completion rate (% started → done)
- Agent automation percentage (measured via telemetry)
- Context reduction achieved (user feedback)
- Auto-retry success rate (telemetry)
- Bug reports (categorize: critical, high, medium, low)

---

**Document Status:** Active (Ready for Implementation)
**Next Steps:** Begin Pre-Phase v0.1 Validation (Week 0)

---

**Prepared By:** spec-drive Planning Team
**Reviewed By:** [Pending]
**Approved By:** [Pending]
**Date:** 2025-11-01
