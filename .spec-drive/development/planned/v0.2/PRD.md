# SPEC-DRIVE v0.2 PRODUCT REQUIREMENTS DOCUMENT

**Version:** 1.0
**Date:** 2025-11-01
**Status:** Planned

---

## 1. VISION

Building on v0.1's foundation (behavior optimization + autodocs + spec-driven development), v0.2 adds intelligent automation and stack awareness:

1. **Workflow Automation** - Specialist agents reduce manual work by 60%+
2. **Multi-Workflow Support** - Handle feature + bugfix + research simultaneously
3. **Stack Intelligence** - Adapt to TypeScript/React, Python/FastAPI, Go, Rust
4. **Enhanced Autodocs** - AI summaries, query patterns, changes feed
5. **Error Recovery** - Automatic retry, rollback, resume capabilities
6. **Expanded Workflows** - Bugfix and research workflows join feature workflow

**End State:** Developers work with intelligent agents that understand their stack, automate repetitive tasks, provide instant context via optimized docs, and gracefully recover from errors.

---

## 2. PROBLEM STATEMENT

### Problems v0.1 Solved:
- ✅ Quality gates enforce discipline
- ✅ Docs auto-update at stage boundaries
- ✅ Traceability tracked (spec → code → test → doc)
- ✅ Feature workflow guides development
- ✅ Behavior optimization prevents shortcuts

### Remaining Pain Points (v0.2 Addresses):

#### A. Manual Workflow Execution
- User manually creates specs, writes code, runs tests, updates docs
- No delegation to specialist agents
- Workflow stages require manual advancement
- Repetitive tasks not automated

**Impact:** Workflows feel like checklists, not automation

#### B. Single Workflow Limitation
- Can only work on one feature at a time
- Can't context-switch between feature + bugfix
- No workflow queue or priority management
- Blocked on one workflow = blocked entirely

**Impact:** Inflexible, doesn't match real development flow

#### C. Generic Quality Gates
- Gates don't adapt to tech stack (TypeScript vs Python vs Go)
- No stack-specific conventions enforced (React hooks rules, Python async patterns)
- Missing language-specific best practices
- Generic profile applies to all projects

**Impact:** Gates miss stack-specific issues, allow bad patterns

#### D. Context Still Heavy
- Index lacks AI summaries (still reading full files for answers)
- No pre-answered queries (repeat questions require file reads)
- No changes feed (hard to see recent updates without git log)
- 70% context reduction is good, but 90%+ is achievable

**Impact:** Slower query responses, repetitive context loading

#### E. Limited Workflow Types
- Only feature workflow available
- No bugfix workflow (investigation → fix → verify)
- No research workflow (explore → decide → ADR)
- Can't handle different work types systematically

**Impact:** Bugfixes and research ad-hoc, no structured process

#### F. No Error Recovery
- Failed gate = stuck (manual retry only)
- No automatic rollback on failures
- No workflow resume after interruption
- No checkpoints or state snapshots

**Impact:** Fragile workflows, lost progress on failures

---

## 3. v0.1 DEPENDENCY CHECKLIST

**CRITICAL:** v0.2 development CANNOT begin until ALL v0.1 deliverables are complete, tested, and verified. This checklist ensures v0.2 builds on a solid foundation.

---

### 3.1 Plugin Infrastructure

**Status:** ⬜ Not Started | 🔄 In Progress | ✅ Complete

- [ ] **Plugin Manifest** - `.claude-plugin/plugin.json` created with correct metadata, commands, hooks
- [ ] **Directory Structure** - All required directories exist:
  - [ ] `spec-drive/commands/`
  - [ ] `spec-drive/hooks/` and `spec-drive/hooks/handlers/`
  - [ ] `spec-drive/scripts/workflows/`
  - [ ] `spec-drive/scripts/gates/`
  - [ ] `spec-drive/scripts/tools/`
  - [ ] `spec-drive/templates/`
  - [ ] `spec-drive/assets/`
- [ ] **Installation** - Plugin installs successfully via Claude Code marketplace or local installation
- [ ] **Activation** - Plugin activates without errors on Claude Code startup

---

### 3.2 SYSTEM 1: Behavior Optimization

- [ ] **Behavior Agent Content** - `assets/strict-concise-behavior.md` complete with:
  - [ ] Quality gate enforcement rules
  - [ ] Extreme planning requirements (TodoWrite format)
  - [ ] Parallel delegation patterns
  - [ ] Docs-first enforcement
  - [ ] Zero shortcuts policy
  - [ ] Atomic commit requirements
- [ ] **SessionStart Hook** - `hooks/handlers/session-start.sh` working:
  - [ ] Auto-injects behavior agent on every session start
  - [ ] Follows explanatory-output-style pattern
  - [ ] Does not interfere with normal Claude Code usage
  - [ ] Can be disabled if needed
- [ ] **Behavior Verification** - Manual testing confirms:
  - [ ] TodoWrite enforced with in/do/out/check/risk/needs format
  - [ ] <95% confidence triggers clarifying questions
  - [ ] Stop-the-line on errors works correctly
  - [ ] Docs must be updated before stage completion
  - [ ] No TODO/console.log allowed in completed work

---

### 3.3 SYSTEM 2: Autodocs (Self-Updating Documentation)

#### Documentation Structure
- [ ] **12 Doc Templates** - All templates in `templates/docs/` created:
  - [ ] `00-overview/SYSTEM-OVERVIEW.md.template`
  - [ ] `00-overview/GLOSSARY.md.template`
  - [ ] `10-architecture/ARCHITECTURE.md.template`
  - [ ] `10-architecture/COMPONENT-CATALOG.md.template`
  - [ ] `10-architecture/DATA-FLOWS.md.template`
  - [ ] `10-architecture/RUNTIME-DEPLOYMENT.md.template`
  - [ ] `10-architecture/OBSERVABILITY.md.template`
  - [ ] `20-build/BUILD-RELEASE.md.template`
  - [ ] `20-build/CI-QUALITY-GATES.md.template`
  - [ ] `50-decisions/ADR-TEMPLATE.md.template`
  - [ ] `PRODUCT-BRIEF.md.template`
  - [ ] Feature page template for `60-features/`

#### Code Analysis & Indexing
- [ ] **analyze-codebase.js** - Script complete and working:
  - [ ] Scans all source files in project
  - [ ] Detects components (classes, functions, modules)
  - [ ] Maps dependencies between components
  - [ ] Identifies architecture patterns
  - [ ] Detects tech stack (TypeScript/React, Python/FastAPI, Go, Rust)
  - [ ] Returns structured component inventory
- [ ] **index-docs.js** - Script complete and working:
  - [ ] Builds/updates `.spec-drive/index.yaml`
  - [ ] Populates `components[]` from code analysis
  - [ ] Populates `specs[]` from spec files
  - [ ] Populates `docs[]` from doc files
  - [ ] Populates `code[]` with file metadata
  - [ ] Creates trace links (spec → code → tests → docs)
- [ ] **update-docs.js** - Script complete and working:
  - [ ] Regenerates docs from index.yaml
  - [ ] Updates COMPONENT-CATALOG.md
  - [ ] Creates feature pages in `docs/60-features/`
  - [ ] Generates API docs in `docs/40-api/`
  - [ ] Updates relevant ARCHITECTURE.md sections
  - [ ] Preserves manual sections (uses AUTO:BEGIN/AUTO:END markers)

#### Index Structure
- [ ] **index-template.yaml** - Template defines structure:
  - [ ] `meta` section (generated, version, project_name)
  - [ ] `components[]` (id, type, path, summary, dependencies)
  - [ ] `specs[]` (id, title, status, trace)
  - [ ] `docs[]` (path, type, summary, last_updated)
  - [ ] `code[]` (path, components, specs, summary)

#### Auto-Update Mechanism
- [ ] **PostToolUse Hook** - `hooks/handlers/post-tool-use.sh` working:
  - [ ] Sets `dirty: true` in `.spec-drive/state.yaml` after code changes
  - [ ] Triggers at appropriate times (file writes, edits)
  - [ ] Does not trigger on read-only operations
- [ ] **Stage Boundary Updates** - Auto-update works correctly:
  - [ ] Triggers when advancing stages (Implement → Verify)
  - [ ] Only runs if `dirty: true` flag set
  - [ ] Only runs if quality gate passed
  - [ ] Clears `dirty` flag after completion
  - [ ] Does not cause mid-work churn (stage boundaries only)

#### Initialization Workflows
- [ ] **Existing Project Init** - `/spec-drive:init` command works:
  - [ ] Runs code analysis (analyze-codebase.js)
  - [ ] Archives existing docs → `docs-archive-{timestamp}/`
  - [ ] Generates full doc structure from analysis
  - [ ] Creates `.spec-drive/index.yaml` with detected components/code
  - [ ] Non-destructive (all old docs preserved)
  - [ ] Works on TypeScript/React projects
  - [ ] Works on Python/FastAPI projects
  - [ ] Works on Go projects
  - [ ] Works on Rust projects
- [ ] **New Project Init** - Via `/spec-drive:app-new` workflow:
  - [ ] Guides planning (vision, goals, users, architecture, stack)
  - [ ] Generates docs from planning session
  - [ ] Creates full doc structure
  - [ ] Creates initial `.spec-drive/index.yaml`
  - [ ] Creates project spec `.spec-drive/specs/APP-001.yaml`
  - [ ] Same doc baseline as existing projects

---

### 3.4 SYSTEM 3: Spec-Driven Development

#### Workflows
- [ ] **app-new Workflow** - `/spec-drive:app-new` command complete:
  - [ ] Command: `commands/app-new.md` created
  - [ ] Orchestrator: `scripts/workflows/app-new.sh` working
  - [ ] Stage 1 (Discover): Guides planning session
  - [ ] Stage 2 (Specify): Creates APP-001.yaml spec
  - [ ] Stage 3 (Implement): Generates initial project structure + docs
  - [ ] Stage 4 (Verify): Confirms documentation complete
  - [ ] Output: Full doc baseline, project spec, ready for features
- [ ] **feature Workflow** - `/spec-drive:feature [SPEC-ID] [title]` command complete:
  - [ ] Command: `commands/feature.md` created
  - [ ] Orchestrator: `scripts/workflows/feature.sh` working
  - [ ] Stage 1 (Discover): Exploration and context gathering
  - [ ] Stage 2 (Specify): Creates SPEC-XXX.yaml with acceptance criteria
  - [ ] Stage 3 (Implement): Code + tests with @spec tags
  - [ ] Stage 4 (Verify): All gates pass, docs updated, traceability complete
  - [ ] Output: Feature spec, implementation, tests, auto-updated docs, trace

#### Quality Gates
- [ ] **Gate 1: Specify** - `scripts/gates/gate-1-specify.sh` working:
  - [ ] Validates no `[NEEDS CLARIFICATION]` markers in spec
  - [ ] Checks all acceptance criteria testable and unambiguous
  - [ ] Verifies measurable success criteria defined
  - [ ] Sets `can_advance: true` in state.yaml on success
  - [ ] Blocks stage advancement on failure
- [ ] **Gate 2: Architect** - `scripts/gates/gate-2-architect.sh` working:
  - [ ] Validates API contracts defined
  - [ ] Checks test scenarios written in spec
  - [ ] Verifies architecture documented (if new patterns)
  - [ ] Confirms dependencies identified
  - [ ] Sets `can_advance: true` on success
- [ ] **Gate 3: Implement** - `scripts/gates/gate-3-implement.sh` working:
  - [ ] Runs tests: `npm test` or equivalent (must pass)
  - [ ] Runs linter: `npm run lint` or equivalent (must pass)
  - [ ] Runs type check: `npx tsc --noEmit` or equivalent (must pass)
  - [ ] Verifies @spec tags present: `grep -r "@spec SPEC-ID"` (must find)
  - [ ] Sets `can_advance: true` on success
  - [ ] Blocks on any failures
- [ ] **Gate 4: Verify** - `scripts/gates/gate-4-verify.sh` working:
  - [ ] Validates all acceptance criteria met
  - [ ] Confirms documentation updated (autodocs ran)
  - [ ] Checks no shortcuts: `grep -r "TODO\|console\.log" src/` (empty)
  - [ ] Verifies traceability complete (index.yaml has full trace)
  - [ ] Confirms docs committed: `git status docs/` shows commits
  - [ ] Sets `can_advance: true` on success

#### Traceability System
- [ ] **@spec Tag Format** - Defined for all supported languages:
  - [ ] TypeScript/JavaScript: `/** @spec SPEC-ID */`
  - [ ] Python: `"""@spec SPEC-ID"""`
  - [ ] Go: `// @spec SPEC-ID`
  - [ ] Rust: `// @spec SPEC-ID`
- [ ] **Tag Detection** - Works without linting errors:
  - [ ] JSDoc-style comments compatible with existing linters
  - [ ] Python docstrings compatible with existing linters
  - [ ] Go comments compatible with existing linters
  - [ ] Rust comments compatible with existing linters
- [ ] **Index Tracking** - Traces stored in index.yaml:
  - [ ] `specs[].trace.code[]` - File paths with line numbers
  - [ ] `specs[].trace.tests[]` - Test file paths with line numbers
  - [ ] `specs[].trace.docs[]` - Doc file paths with line numbers
  - [ ] Bidirectional mapping (code → spec, spec → code)

#### Workflow State Management
- [ ] **state.yaml Structure** - State file format defined:
  - [ ] `current_workflow` - Current workflow type
  - [ ] `current_spec` - Active spec ID
  - [ ] `current_stage` - Current stage name
  - [ ] `can_advance` - Gate check result (true/false)
  - [ ] `dirty` - Documentation update flag (true/false)
  - [ ] `workflows{}` - History of all workflows
- [ ] **State Tracking** - State persists correctly:
  - [ ] File: `.spec-drive/state.yaml` (gitignored)
  - [ ] Updates on stage transitions
  - [ ] Updates on gate checks
  - [ ] Updates on PostToolUse hook
  - [ ] Readable by behavior agent
  - [ ] Blocks advancement when `can_advance: false`

#### Commands
- [ ] **init Command** - `/spec-drive:init` initializes existing projects
- [ ] **rebuild-index Command** - `/spec-drive:rebuild-index` regenerates index from source

#### Templates
- [ ] **spec-template.yaml** - Spec YAML structure template created:
  - [ ] Spec metadata (id, title, status)
  - [ ] User stories
  - [ ] Acceptance criteria (Given/When/Then format)
  - [ ] Non-functional requirements
  - [ ] API contracts
  - [ ] Test scenarios
  - [ ] Dependencies and constraints

#### Utilities
- [ ] **utils.sh** - Shared utility functions:
  - [ ] YAML parsing/manipulation helpers
  - [ ] State file read/write functions
  - [ ] File path utilities
  - [ ] Error handling helpers
- [ ] **detect-project.py** - Project type detection:
  - [ ] Detects web app, API, CLI, library, etc.
  - [ ] Returns project type for workflow customization
- [ ] **stack-detection.py** - Tech stack detection:
  - [ ] Detects TypeScript/React
  - [ ] Detects Python/FastAPI
  - [ ] Detects Go
  - [ ] Detects Rust
  - [ ] Returns stack profile identifier

---

### 3.5 Integration Testing

- [ ] **Test Scenario 1: New Project (TypeScript/React)**
  - [ ] Run `/spec-drive:app-new MyApp "User management system"`
  - [ ] Verify: Full doc structure created (all 12 doc types)
  - [ ] Verify: APP-001.yaml spec exists and complete
  - [ ] Verify: index.yaml populated with project metadata
  - [ ] Run `/spec-drive:feature AUTH-001 "User login"`
  - [ ] Complete all 4 stages (discover → specify → implement → verify)
  - [ ] Verify: AUTH-001.yaml spec complete and unambiguous
  - [ ] Verify: Code has @spec AUTH-001 tags, no linting errors
  - [ ] Verify: Tests pass (npm test)
  - [ ] Verify: Lint passes (npm run lint)
  - [ ] Verify: TypeScript passes (npx tsc --noEmit)
  - [ ] Verify: Docs auto-updated (COMPONENT-CATALOG, feature page, API docs)
  - [ ] Verify: index.yaml has complete trace (spec → code → tests → docs)
  - [ ] Verify: No TODO/console.log in completed code

- [ ] **Test Scenario 2: Existing TypeScript/React Project**
  - [ ] Run `/spec-drive:init` in existing repo with code
  - [ ] Verify: Code analysis completes successfully
  - [ ] Verify: Old docs archived to `docs-archive-{timestamp}/`
  - [ ] Verify: New docs/ structure created (all 12 doc types)
  - [ ] Verify: Docs populated from code analysis (components detected)
  - [ ] Verify: index.yaml has `components[]`, `code[]` from analysis
  - [ ] Run `/spec-drive:feature NEW-001 "Add new feature"`
  - [ ] Verify: Workflow works correctly in existing project
  - [ ] Verify: Docs update with new + existing components
  - [ ] Verify: No conflicts with existing code

- [ ] **Test Scenario 3: Existing Python/FastAPI Project**
  - [ ] Run `/spec-drive:init` in Python project
  - [ ] Verify: Python components detected correctly
  - [ ] Verify: Docs generated for Python project
  - [ ] Run `/spec-drive:feature PY-001 "Add endpoint"`
  - [ ] Verify: @spec tags work in Python (docstring format)
  - [ ] Verify: Gates work with pytest (tests pass check)
  - [ ] Verify: Gates work with mypy (type check)
  - [ ] Verify: Gates work with ruff/black (lint check)
  - [ ] Verify: Traceability complete in Python context

- [ ] **Test Scenario 4: All Three Systems Integration**
  - [ ] System 1 (Behavior): Quality enforced throughout workflow
  - [ ] System 2 (Autodocs): Docs auto-updated at stage boundaries
  - [ ] System 3 (Spec-Driven): Full traceability maintained
  - [ ] End-to-end: Feature development completes faster WITH workflows than without
  - [ ] Context efficiency: AI queries index first (measured token reduction ≥70%)

---

### 3.6 Documentation & Planning

- [ ] **v0.1 PRD** - Complete and accurate:
  - [ ] All systems documented
  - [ ] All components listed
  - [ ] Success criteria defined
  - [ ] Validation plan complete
- [ ] **v0.1 TDD** - Technical design documented:
  - [ ] Architecture decisions recorded
  - [ ] Component interactions defined
  - [ ] Data structures specified
  - [ ] Integration points documented
- [ ] **v0.1 TEST-PLAN** - Testing strategy complete:
  - [ ] Test scenarios defined
  - [ ] Test cases written
  - [ ] Coverage targets met (≥90%)
  - [ ] All test scenarios passed
- [ ] **v0.1 RISK-ASSESSMENT** - Risks tracked and mitigated:
  - [ ] All identified risks have mitigation plans
  - [ ] Critical risks resolved or accepted
  - [ ] No blocking risks remain
- [ ] **ADRs** - Architecture decisions recorded:
  - [ ] SessionStart hook implementation
  - [ ] Index structure design
  - [ ] Auto-update trigger mechanism
  - [ ] Quality gate enforcement approach

---

### 3.7 Non-Functional Requirements

- [ ] **Performance**
  - [ ] Code analysis completes in <30s for small projects (<100 files)
  - [ ] Code analysis completes in <2min for medium projects (100-500 files)
  - [ ] Index updates complete in <5s
  - [ ] Doc generation completes in <10s
  - [ ] No noticeable lag in Claude Code sessions (SessionStart hook <1s)
- [ ] **Reliability**
  - [ ] Index.yaml recoverable via rebuild-index command
  - [ ] State.yaml corruption doesn't lose workflow history
  - [ ] Docs archival preserves all old content
  - [ ] Gates fail gracefully with clear error messages
- [ ] **Usability**
  - [ ] Error messages explain what's wrong and how to fix
  - [ ] Workflow state always visible (user knows current stage)
  - [ ] Rollback possible (state.yaml revertable, docs recoverable)
  - [ ] Plugin can be disabled without breaking Claude Code
- [ ] **Compatibility**
  - [ ] Works on macOS, Linux, Windows (via WSL)
  - [ ] Works with Node.js projects (npm/pnpm/yarn)
  - [ ] Works with Python projects (pip/poetry/pipenv)
  - [ ] Works with Go projects (go modules)
  - [ ] Works with Rust projects (cargo)

---

### 3.8 Success Criteria (Overall v0.1 Completion)

**v0.1 is COMPLETE when ALL of the following are true:**

- ✅ All plugin infrastructure components exist and work correctly
- ✅ System 1 (Behavior Optimization) enforces quality gates in all sessions
- ✅ System 2 (Autodocs) generates and maintains documentation automatically
- ✅ System 3 (Spec-Driven Development) provides working feature + app-new workflows
- ✅ All 4 quality gates (Specify, Architect, Implement, Verify) enforce correctly
- ✅ @spec tags work without linting errors in all supported languages
- ✅ Traceability tracking complete (spec → code → tests → docs)
- ✅ All 4 integration test scenarios pass without errors
- ✅ Context efficiency ≥70% (measured via token usage before/after index)
- ✅ Developer velocity improved (features complete faster WITH workflows)
- ✅ All v0.1 planning docs complete (PRD, TDD, TEST-PLAN, RISK-ASSESSMENT)
- ✅ All non-functional requirements met (performance, reliability, usability, compatibility)
- ✅ No critical or high-priority bugs remain
- ✅ Plugin published and installable via Claude Code marketplace

**GATE:** This checklist MUST be 100% complete before v0.2 development begins. No exceptions.

---

## 4. SUCCESS METRICS

- **Workflow Automation:** ≥60% of workflow tasks delegated to specialist agents (vs 0% manual in v0.1)
- **Multi-Workflow Efficiency:** 3+ workflows active simultaneously without conflicts
- **Stack Accuracy:** 100% of quality gates adapted to detected stack (vs 0% generic in v0.1)
- **Context Reduction:** ≥90% via AI summaries + query patterns (up from 70% in v0.1)
- **Workflow Coverage:** 3 workflows operational (feature, bugfix, research vs 1 in v0.1)
- **Recovery Rate:** ≥80% of gate failures auto-retry successfully (vs 0% manual in v0.1)
- **Developer Velocity:** Features completed 40% faster with agents vs manual v0.1 workflows

---

## 5. v0.2 PHASE - SIX ENHANCEMENTS

### ENHANCEMENT 1: Specialist Agents

**What It Delivers:**

Dedicated agents for each workflow stage that automate repetitive tasks and enforce stack-specific best practices.

#### Agents

**spec-agent** - Spec Creation & Refinement
- Creates specs from user input with [NEEDS CLARIFICATION] markers for ambiguities
- Validates spec completeness before Specify → Implement transition
- Enforces Given/When/Then format for acceptance criteria
- Ensures measurable success criteria
- Checks dependencies and constraints
- Output: Complete, unambiguous SPEC-XXX.yaml

**impl-agent** - Implementation with Traceability
- Implements code following spec requirements
- Adds @spec tags automatically to all implementations
- Follows stack-specific conventions (from profiles)
- Enforces error handling and input validation
- No TODO/console.log/placeholders
- Output: Production-ready code with full traceability

**test-agent** - Test-First Development
- Writes tests BEFORE implementation (TDD)
- Covers all acceptance criteria from spec
- Adds @spec tags to test files
- Follows stack-specific test patterns
- Ensures edge cases and error paths tested
- Output: Comprehensive test suite with ≥90% coverage

#### Integration with Workflows

**Feature Workflow:**
```
Discover → Specify → Implement → Verify
            ↓         ↓
        spec-agent  impl-agent + test-agent
```

**Delegation Flow:**
1. User completes Discover stage (manual exploration)
2. Orchestrator delegates to spec-agent for Specify stage
3. spec-agent creates SPEC-XXX.yaml with ACs
4. User reviews and approves spec
5. Orchestrator delegates to test-agent + impl-agent for Implement stage
6. test-agent writes failing tests (TDD)
7. impl-agent implements to make tests pass
8. User verifies in Verify stage

#### Stack Awareness

Agents use stack profile variables:
- `{STACK_CONVENTIONS}` - Naming, file patterns, architecture
- `{STACK_QUALITY_GATES}` - Linting, type-checking, test commands
- `{STACK_PATTERNS}` - File locations, import styles, error handling

Example (TypeScript/React):
- impl-agent enforces: PascalCase components, hooks rules, prop types
- test-agent enforces: React Testing Library patterns, async utilities

Example (Python/FastAPI):
- impl-agent enforces: Pydantic models, async/await, type hints
- test-agent enforces: pytest fixtures, async test patterns

#### Components

```
spec-drive/
├── agents/
│   ├── spec-agent.md          # Spec creation subagent
│   ├── impl-agent.md          # Implementation subagent
│   └── test-agent.md          # Test creation subagent
├── scripts/tools/
│   └── validate-spec.js       # Spec validation (called by spec-agent)
```

#### Agent Templates

**spec-agent.md:**
```markdown
---
name: spec-agent
description: "Spec creation and refinement specialist"
stack_aware: true
---

# Spec Agent

You are a spec creation specialist.

## Stack Context
{STACK_CONTEXT}

## Responsibilities

1. Create spec YAML from user requirements
2. Add [NEEDS CLARIFICATION] for ambiguities
3. Validate completeness:
   - All user stories have acceptance criteria
   - All ACs in Given/When/Then format
   - Measurable success criteria defined
   - Dependencies identified
   - Risks documented

## Stack-Specific Requirements
{STACK_SPEC_REQUIREMENTS}

## Output Format

specs/SPEC-XXX.yaml with:
- User stories
- Acceptance criteria (Given/When/Then)
- Non-functional requirements
- Design constraints
- Dependencies
- Risks with mitigations
- Traceability placeholders

## Completeness Checklist

- [ ] No [NEEDS CLARIFICATION] markers remaining
- [ ] All requirements testable
- [ ] Success criteria measurable
- [ ] Stack conventions documented
```

**impl-agent.md:** (Similar structure, implementation-focused)

**test-agent.md:** (Similar structure, test-focused)

---

### ENHANCEMENT 2: Additional Workflows

**What It Delivers:**

Bugfix and research workflows join feature workflow, providing structured processes for all work types.

#### Bugfix Workflow

**Purpose:** Systematic bug investigation, fix, and verification

**Stages:**
1. **Investigate** - Root cause analysis, reproduction steps, impact assessment
2. **Specify Fix** - Create BUG-XXX.yaml with fix approach, regression test plan
3. **Fix** - Implement minimal fix with @spec tags, regression tests
4. **Verify** - All tests pass, bug not reproducible, no regressions

**Key Differences from Feature Workflow:**
- Focused on root cause (investigation stage)
- Minimal scope (fix only what's broken)
- Regression-first (failing test before fix)
- Faster gates (less planning overhead)

**Workflow YAML:**
```yaml
# workflows/bugfix.yaml
workflow: bugfix
description: "Systematic bug investigation and fix"

stages:
  investigate:
    entry_criteria:
      - "Bug symptom documented"
    exit_criteria:
      - "Root cause identified"
      - "Reproduction steps documented"
      - "Impact assessed"
    gates: []  # No formal gate, user confirmation

  specify-fix:
    entry_criteria:
      - "Root cause known"
    exit_criteria:
      - "BUG-XXX.yaml complete"
      - "Fix approach documented"
      - "Regression test plan defined"
    gates:
      - "gate-1-bugfix-specify"

  fix:
    entry_criteria:
      - "Fix approach approved"
    exit_criteria:
      - "Regression test written and failing"
      - "Fix implemented with @spec tags"
      - "All tests pass"
    gates:
      - "gate-2-bugfix-implement"

  verify:
    entry_criteria:
      - "Fix complete"
    exit_criteria:
      - "Bug not reproducible"
      - "No new regressions"
      - "Docs updated if needed"
    gates:
      - "gate-3-bugfix-verify"
```

**Command:**
```bash
/spec-drive:bugfix BUG-042 "Login fails with special characters"
```

**BUG-XXX.yaml Template:**
```yaml
---
id: BUG-042
title: "Login fails with special characters"
status: draft
type: bugfix
severity: high  # critical | high | medium | low
created: 2025-11-01
updated: 2025-11-01
owner: "Team/Person"

symptom: |
  User login fails when password contains @ or # characters.
  Error: "Invalid credentials" even with correct password.

investigation:
  root_cause: |
    Password validation regex doesn't escape special characters.
    @ and # are treated as regex meta-characters.

  reproduction:
    - "Create user with password: Pass@123#"
    - "Attempt login with correct credentials"
    - "Observe: Login fails with 'Invalid credentials'"

  impact:
    - "Users: ~500 users with special chars in passwords (5% of active users)"
    - "Severity: High - blocks legitimate users"
    - "Workaround: None (users locked out)"

fix_approach:
  description: |
    Escape special regex characters in password validation.
    Use built-in escapeRegex() utility.

  changes:
    - "src/auth/validate.ts:45 - escapeRegex(password)"

  regression_tests:
    - "Test login with @ # $ % special chars"
    - "Test edge cases: empty password, very long password"

  risks:
    - "Risk: May allow previously blocked passwords"
      mitigation: "Audit existing password hashes for changes"

trace:
  code: []
  tests: []
  docs: []
```

#### Research Workflow

**Purpose:** Timeboxed research with structured decision-making and ADR output

**Stages:**
1. **Explore** - Gather options, benchmark, audit, community feedback (timeboxed)
2. **Synthesize** - Compare options, create decision matrix, identify tradeoffs
3. **Decide** - Select option, document rationale, create ADR

**Key Differences:**
- Timeboxed exploration (user sets time limit: 30m, 1h, 2h)
- Output is ADR, not code
- No quality gates (just timebox enforcement)
- Less rigid structure (exploration encouraged)

**Workflow YAML:**
```yaml
# workflows/research.yaml
workflow: research
description: "Timeboxed research with ADR output"

stages:
  explore:
    entry_criteria:
      - "Research topic defined"
      - "Timebox set"
    exit_criteria:
      - "2-4 options identified"
      - "Each option has: description, pros, cons, cost estimate"
    gates: []

  synthesize:
    entry_criteria:
      - "Options gathered"
    exit_criteria:
      - "Decision matrix created"
      - "Tradeoffs documented"
      - "Recommendation formed"
    gates: []

  decide:
    entry_criteria:
      - "Options analyzed"
    exit_criteria:
      - "Option selected"
      - "ADR-XXXX.md created with rationale"
      - "Decision communicated"
    gates: []
```

**Command:**
```bash
/spec-drive:research "auth provider selection" 1h
```

**Output ADR:**
```markdown
---
title: ADR-0003: Auth Provider Selection
status: accepted
date: 2025-11-01
owner: Security Team
---

## Context

Need OAuth provider for user authentication.
Requirements: SAML support, 99.9% uptime, GDPR compliance, <$1k/month.

## Decision

Selected Auth0.

## Rationale

Evaluated 3 options (Auth0, Okta, Custom):

| Criteria | Auth0 | Okta | Custom |
|----------|-------|------|--------|
| SAML Support | ✅ | ✅ | ❌ (6 weeks dev) |
| Uptime SLA | 99.9% | 99.99% | Unknown |
| GDPR Compliance | ✅ Certified | ✅ Certified | ⚠️ Manual |
| Cost/month | $850 | $1,200 | $0 (+ $15k dev) |
| Time to implement | 1 week | 1 week | 8 weeks |

**Decision:** Auth0 provides best balance of features, compliance, and cost.

## Consequences

**Positive:**
- Fast implementation (1 week)
- Certified GDPR compliance
- Proven uptime

**Negative:**
- Vendor lock-in
- $850/month recurring cost

## Alternatives Considered

**Okta:** Too expensive ($1,200/month), over budget
**Custom:** High risk (compliance, uptime), long timeline (8 weeks)
```

#### Components

```
spec-drive/
├── commands/
│   ├── bugfix.md              # /spec-drive:bugfix command
│   └── research.md            # /spec-drive:research command
├── scripts/workflows/
│   ├── bugfix.sh              # Bugfix orchestrator
│   └── research.sh            # Research orchestrator
├── templates/
│   ├── BUG-TEMPLATE.yaml      # Bug spec template
│   └── ADR-TEMPLATE.md        # Already exists from v0.1
└── skills/orchestrator/workflows/
    ├── bugfix.yaml            # Bugfix workflow definition
    └── research.yaml          # Research workflow definition
```

---

### ENHANCEMENT 3: Stack Profiles

**What It Delivers:**

Stack-specific quality gates, conventions, and enforcement. Auto-detect tech stack and adapt all behaviors accordingly.

#### Built-In Profiles

**1. typescript-react.yaml**
```yaml
profile: typescript-react
description: "TypeScript + React web application"

detection:
  files:
    - package.json
    - tsconfig.json
  markers:
    - "react" in package.json dependencies

behaviors:
  quality_gates:
    - name: "ESLint passes"
      command: "npm run lint"
      expect: "exit code 0"

    - name: "TypeScript compiles"
      command: "npx tsc --noEmit"
      expect: "exit code 0"

    - name: "Tests pass"
      command: "npm test"
      expect: "exit code 0"

    - name: "No 'any' types"
      command: "grep -r ': any' src/ --include='*.ts' --include='*.tsx'"
      expect: "no matches"

  patterns:
    component_file: "src/components/**/*.tsx"
    test_file: "src/**/*.test.tsx"
    hook_file: "src/hooks/**/*.ts"

  conventions:
    - "Components use PascalCase (e.g., UserProfile.tsx)"
    - "Hooks use camelCase with 'use' prefix (e.g., useAuth.ts)"
    - "Test files co-located with source (e.g., UserProfile.test.tsx)"
    - "Props interfaces exported (export interface UserProfileProps)"

  enforcement:
    - "Enforce React hooks rules (no conditional hooks)"
    - "Enforce component prop types (no implicit any)"
    - "Enforce error boundaries for async components"
    - "Update Storybook stories when components change"

  docs_requirements:
    - "Component props documented with JSDoc"
    - "Storybook stories for UI components"
    - "README for feature modules"

  pre_commit_hooks:
    - "npm run lint"
    - "npm run typecheck"

  verification_commands:
    - "npm run build"
    - "npm test -- --coverage"
```

**2. python-fastapi.yaml**
```yaml
profile: python-fastapi
description: "Python + FastAPI backend"

detection:
  files:
    - requirements.txt
    - pyproject.toml
  markers:
    - "fastapi" in requirements.txt or pyproject.toml

behaviors:
  quality_gates:
    - name: "Pytest passes"
      command: "pytest"
      expect: "exit code 0"

    - name: "MyPy type check"
      command: "mypy src/"
      expect: "exit code 0"

    - name: "Black formatting"
      command: "black --check src/"
      expect: "exit code 0"

    - name: "Pylint passes"
      command: "pylint src/ --fail-under=9.0"
      expect: "exit code 0"

  patterns:
    router_file: "src/routers/**/*.py"
    model_file: "src/models/**/*.py"
    test_file: "tests/**/*.py"

  conventions:
    - "Routers use snake_case (e.g., user_routes.py)"
    - "Models use PascalCase (e.g., UserProfile)"
    - "Test files in tests/ directory (e.g., test_user_routes.py)"
    - "All models use Pydantic BaseModel"

  enforcement:
    - "All async handlers use async def"
    - "Error handling via HTTPException"
    - "No bare except: (must specify exception type)"
    - "Type hints on all function signatures"

  docs_requirements:
    - "Docstrings on all public functions (Google style)"
    - "OpenAPI schema auto-generated (FastAPI default)"
    - "README for routers"

  pre_commit_hooks:
    - "black src/"
    - "mypy src/"
    - "pylint src/"

  verification_commands:
    - "pytest --cov=src --cov-report=term-missing"
    - "mypy src/"
```

**3. go.yaml**
```yaml
profile: go
description: "Go application"

detection:
  files:
    - go.mod
  markers: []

behaviors:
  quality_gates:
    - name: "Go test passes"
      command: "go test ./..."
      expect: "exit code 0"

    - name: "Go vet passes"
      command: "go vet ./..."
      expect: "exit code 0"

    - name: "Go fmt check"
      command: "test -z $(gofmt -l .)"
      expect: "exit code 0"

  patterns:
    package_file: "**/*.go"
    test_file: "**/*_test.go"

  conventions:
    - "Packages use lowercase (e.g., userservice)"
    - "Structs use PascalCase (e.g., UserProfile)"
    - "Test files end with _test.go"
    - "Exported identifiers start with uppercase"

  enforcement:
    - "Error handling via return values (not exceptions)"
    - "Context passed as first parameter to functions"
    - "No global variables (use dependency injection)"

  docs_requirements:
    - "Godoc comments on all exported functions"
    - "Package-level doc.go files"

  pre_commit_hooks:
    - "go fmt ./..."
    - "go vet ./..."

  verification_commands:
    - "go build ./..."
    - "go test -race ./..."
```

**4. rust.yaml**
```yaml
profile: rust
description: "Rust application"

detection:
  files:
    - Cargo.toml
  markers: []

behaviors:
  quality_gates:
    - name: "Cargo test passes"
      command: "cargo test"
      expect: "exit code 0"

    - name: "Clippy passes"
      command: "cargo clippy -- -D warnings"
      expect: "exit code 0"

    - name: "Rustfmt check"
      command: "cargo fmt -- --check"
      expect: "exit code 0"

  patterns:
    module_file: "src/**/*.rs"
    test_file: "tests/**/*.rs"

  conventions:
    - "Modules use snake_case (e.g., user_service.rs)"
    - "Structs use PascalCase (e.g., UserProfile)"
    - "Test files in tests/ or inline with #[cfg(test)]"

  enforcement:
    - "No unwrap() in production code (use ? operator)"
    - "Error handling via Result<T, E>"
    - "All public items documented with ///"

  docs_requirements:
    - "Rustdoc comments on all public items"
    - "Examples in documentation"

  pre_commit_hooks:
    - "cargo fmt"
    - "cargo clippy"

  verification_commands:
    - "cargo build --release"
    - "cargo test"
```

#### Auto-Detection Logic

Enhanced `scripts/stack-detection.py`:

```python
def detect_tech_stack():
    """Auto-detect tech stack from project files"""

    detections = []

    # JavaScript/TypeScript
    if Path('package.json').exists():
        pkg = json.loads(Path('package.json').read_text())
        deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}

        has_ts = Path('tsconfig.json').exists()

        if 'react' in deps:
            detections.append('typescript-react' if has_ts else 'javascript-react')
        elif 'next' in deps:
            detections.append('typescript-nextjs' if has_ts else 'javascript-nextjs')
        elif 'express' in deps:
            detections.append('typescript-node' if has_ts else 'javascript-node')

    # Python
    if Path('requirements.txt').exists() or Path('pyproject.toml').exists():
        if has_dependency('fastapi'):
            detections.append('python-fastapi')
        elif has_dependency('django'):
            detections.append('python-django')
        elif has_dependency('flask'):
            detections.append('python-flask')

    # Go
    if Path('go.mod').exists():
        detections.append('go')

    # Rust
    if Path('Cargo.toml').exists():
        detections.append('rust')

    # Docker/K8s (additive, not primary)
    if Path('Dockerfile').exists():
        detections.append('docker')

    return detections if detections else ['generic']
```

#### Profile Integration with Agents

Agents use profile variables via template substitution:

**Before (v0.1 - Generic):**
```markdown
Run quality gates:
- npm test (if Node.js)
- pytest (if Python)
- go test (if Go)
```

**After (v0.2 - Stack-Aware):**
```markdown
Run quality gates:
{STACK_QUALITY_GATES}

# Substituted for TypeScript/React:
- npm run lint
- npx tsc --noEmit
- npm test
- grep -r ': any' src/ (expect no matches)

# Substituted for Python/FastAPI:
- pytest
- mypy src/
- black --check src/
- pylint src/ --fail-under=9.0
```

#### Components

```
spec-drive/
├── stack-profiles/
│   ├── typescript-react.yaml
│   ├── python-fastapi.yaml
│   ├── go.yaml
│   ├── rust.yaml
│   └── generic.yaml          # Fallback from v0.1
├── scripts/
│   └── stack-detection.py    # Enhanced detection
└── .spec-drive/config.yaml   # Stores detected profile
```

---

### ENHANCEMENT 4: Index Optimizations

**What It Delivers:**

AI-generated summaries, pre-answered query patterns, and changes feed in `docs/_index.yaml` to achieve ≥90% context reduction.

#### AI Summaries

**Problem:** v0.1 index has file paths but no summaries. Queries still require reading full files.

**Solution:** Add 1-2 sentence AI-generated summary per component/spec/doc/code file.

**Generation Method:**
- Use Task(general-purpose) with prompt: "Summarize this file in 1-2 sentences"
- Run after file changes (PostToolUse hook trigger)
- Store in index.yaml
- Regenerable (not hand-written)

**Index Schema Update:**
```yaml
components:
  auth-service:
    summary: "Handles user authentication via JWT tokens. Supports MFA, password reset, session management."  # NEW
    type: service
    apis: [POST /api/auth/login, POST /api/auth/mfa/verify]
    files: [src/auth/mfa.ts:45-120]

specs:
  AUTH-001:
    title: "MFA Login"
    summary: "Multi-factor authentication for user login. Supports TOTP and SMS fallback."  # NEW
    status: verified
    code: [src/auth/mfa.ts:45-120]

docs:
  "docs/10-architecture/ARCHITECTURE.md":
    summary: "High-level system architecture: 3-tier web app with React/Node/PostgreSQL. Includes deployment and scaling strategy."  # NEW
    tier: 2
    updated: 2025-10-28

code:
  "src/auth/mfa.ts":
    summary: "MFA verification logic. Main functions: verifyMfa(), generateTOTP(), validateSMS(). Tagged with @spec AUTH-001."  # NEW
    specs: [AUTH-001]
    components: [auth-service]
```

**Query Flow (Before vs After):**

**Before (v0.1 - 70% reduction):**
```
User: "How does MFA work?"
→ Claude reads index, finds AUTH-001
→ Claude reads specs/AUTH-001.yaml (full file)
→ Claude reads src/auth/mfa.ts (full file)
→ Answers question
Token usage: ~5KB context
```

**After (v0.2 - 90% reduction):**
```
User: "How does MFA work?"
→ Claude reads index, finds AUTH-001
→ Claude reads summary: "Multi-factor authentication for user login. Supports TOTP and SMS fallback."
→ Answers question immediately (no file reads!)
Token usage: ~0.5KB context (90% reduction)
```

#### Query Patterns

**Problem:** Common questions asked repeatedly require file reads each time.

**Solution:** Pre-answer top 10-20 FAQs in index.yaml `queries[]` section.

**Index Schema Update:**
```yaml
queries:
  "how to add an endpoint":
    answer: "See docs/20-build/CONTRIBUTING.md#adding-endpoints. Follow pattern in src/api/metrics.ts. Update OpenAPI schema in openapi.yaml."
    refs:
      - docs/20-build/CONTRIBUTING.md
      - src/api/metrics.ts:100-150
      - openapi.yaml

  "where is auth implemented":
    answer: "Auth handled by auth-service component (src/auth/*). See AUTH-001 spec for MFA, AUTH-002 for password reset. Main entry: src/auth/mfa.ts:45."
    refs:
      - docs/60-features/AUTH-001.md
      - docs/60-features/AUTH-002.md
      - src/auth/mfa.ts

  "how to run tests":
    answer: "Run 'npm test' for all tests or 'npm test -- auth' for specific suite. See docs/20-build/BUILD-&-RELEASE.md for CI pipeline."
    refs:
      - docs/20-build/BUILD-&-RELEASE.md
      - package.json
```

**Query Generation:**
- Analyze common questions from session transcripts
- Extract frequently-asked patterns
- Generate answers from docs/code
- Update quarterly or on major changes

**Query Flow:**
```
User: "How to add an endpoint?"
→ Claude checks index.queries[]
→ Finds pre-answered query
→ Returns instant answer (0 file reads!)
Token usage: ~0.2KB context (95% reduction)
```

#### Changes Feed

**Problem:** Hard to see recent updates without running `git log`.

**Solution:** Track last 20 updates in index.yaml `changes[]` section.

**Index Schema Update:**
```yaml
changes:
  - timestamp: 2025-11-01T10:30:00Z
    type: code
    file: src/auth/mfa.ts
    summary: "Added SMS fallback for TOTP verification"
    specs: [AUTH-001]
    diff_lines: "+15 -3"
    author: alice

  - timestamp: 2025-11-01T10:25:00Z
    type: doc
    file: docs/60-features/AUTH-001.md
    summary: "Auto-updated Reader page (trace added SMS functions)"
    trigger: DocUpdateAgent

  - timestamp: 2025-10-30T16:00:00Z
    type: spec
    file: specs/AUTH-002.yaml
    summary: "Spec approved: Password reset via email"
    status: approved → verified
    author: bob
```

**Update Mechanism:**
- PostToolUse hook adds entry on file changes
- Keep last 20 only (FIFO queue)
- Include: timestamp, type, file, summary, author, diff stats

**Query Flow:**
```
User: "What changed recently?"
→ Claude reads index.changes[]
→ Returns last 20 updates
→ No git log needed
Token usage: ~1KB context (instant)
```

#### Components

```
spec-drive/
├── scripts/tools/
│   ├── generate-summaries.js      # AI summary generation
│   ├── update-index-queries.js    # Query pattern updates
│   └── update-index-changes.js    # Changes feed updates
├── hooks/handlers/
│   └── post-tool-use.sh           # Updated: trigger summary/changes updates
└── .spec-drive/index.yaml         # Enhanced with summaries, queries, changes
```

#### Index.yaml Full Schema (v0.2)

```yaml
meta:
  generated: 2025-11-01T10:30:00Z
  version: "2.0"  # NEW: v0.2 schema
  project: "MyProject"

components:
  component-id:
    summary: "1-2 sentence summary"  # NEW
    type: service|component|utility
    apis: []
    files: []
    tests: []
    specs: []
    docs: []

specs:
  SPEC-ID:
    title: "..."
    summary: "1-2 sentence summary"  # NEW
    status: draft|specified|implemented|verified|done
    code: []
    tests: []
    docs: []

docs:
  "path/to/doc.md":
    summary: "1-2 sentence summary"  # NEW
    tier: 1|2|3
    updated: timestamp
    status: fresh|stale

code:
  "path/to/file.ext":
    summary: "1-2 sentence summary"  # NEW
    specs: []
    components: []
    tests: []

queries:  # NEW
  "query text":
    answer: "pre-answered response"
    refs: []

changes:  # NEW
  - timestamp: ...
    type: code|spec|doc
    file: ...
    summary: ...
```

---

### ENHANCEMENT 5: Multi-Feature State

**What It Delivers:**

Support for multiple workflows active simultaneously with context switching, priority management, and conflict detection.

#### Problem

v0.1 supports only one active workflow at a time:
```yaml
# .spec-drive/state.yaml (v0.1)
current_workflow: feature
current_spec: AUTH-001
current_stage: implement
```

If user wants to:
- Switch to bugfix while feature in progress → Must complete or abandon feature
- Work on multiple features → Blocked by single-workflow limitation
- Prioritize urgent bugfix → No priority system

#### Solution

Multi-workflow queue with active/paused states, priority ordering, and conflict detection.

#### State Schema (v0.2)

```yaml
# .spec-drive/state.yaml (v0.2)
current_workflow: AUTH-001  # Currently active
dirty: false

workflows:
  AUTH-001:
    type: feature
    spec: AUTH-001
    stage: implement
    status: active  # active | paused | blocked | done
    started: 2025-11-01T10:00:00Z
    priority: 1  # 0=highest, 9=lowest
    files_locked:  # NEW: track file modifications
      - src/auth/mfa.ts
      - tests/auth/mfa.test.ts
    snapshots:  # NEW: state checkpoints
      - stage: specify
        timestamp: 2025-11-01T09:30:00Z
      - stage: implement
        timestamp: 2025-11-01T10:00:00Z

  METRICS-001:
    type: feature
    spec: METRICS-001
    stage: specify
    status: paused  # User switched away
    started: 2025-11-01T09:00:00Z
    priority: 2
    files_locked:
      - src/api/metrics.ts
    snapshots:
      - stage: discover
        timestamp: 2025-11-01T09:00:00Z

  BUG-042:
    type: bugfix
    spec: BUG-042
    stage: investigate
    status: paused
    started: 2025-11-01T11:00:00Z
    priority: 0  # Highest priority (urgent)
    files_locked: []
    snapshots: []

history:  # NEW: completed workflows
  - workflow: AUTH-002
    type: feature
    completed: 2025-10-30T16:00:00Z
    duration: "4h 30m"
```

#### Context Switching

**Command:**
```bash
/spec-drive:switch SPEC-ID
```

**Flow:**
1. Check if SPEC-ID workflow exists
2. Pause current workflow (save snapshot)
3. Activate target workflow (restore snapshot if exists)
4. Update `current_workflow` in state.yaml
5. Display workflow context (stage, files locked, next steps)

**Conflict Detection:**
```yaml
# If switching to workflow that modifies same files:
User: /spec-drive:switch METRICS-001

Claude checks:
  - Current workflow (AUTH-001) locks: [src/auth/mfa.ts, tests/auth/mfa.test.ts]
  - Target workflow (METRICS-001) locks: [src/api/metrics.ts]
  - No overlap → Safe to switch

Claude: "✅ Switched to METRICS-001 (Specify stage)"

# If conflict:
User: /spec-drive:switch CONFLICT-SPEC

Claude checks:
  - Current locks: [src/auth/mfa.ts]
  - Target locks: [src/auth/mfa.ts]  # CONFLICT!

Claude: "⚠️ File conflict detected: src/auth/mfa.ts
  Active in AUTH-001 (implement stage)
  Targeted by CONFLICT-SPEC (specify stage)

  Options:
  (A) Commit AUTH-001 changes first (recommended)
  (B) Force switch (uncommitted changes may conflict)
  (C) Cancel

  Recommend: (A)"
```

#### Priority Management

**Auto-Priority:**
- Bugfix: priority 0 (highest) - urgent fixes
- Feature: priority 1-5 - based on order started
- Research: priority 6-9 (lowest) - background tasks

**Manual Override:**
```bash
/spec-drive:prioritize SPEC-ID 0  # Set to highest priority
```

**Priority Display:**
```bash
/spec-drive:status

Active Workflows (by priority):
  🔴 [0] BUG-042 (Bugfix: Login fails) - Investigate
  🟡 [1] AUTH-001 (Feature: MFA Login) - Implement ← Current
  🟢 [2] METRICS-001 (Feature: Usage metrics) - Specify (paused)
```

#### Workflow Queue Management

**List all workflows:**
```bash
/spec-drive:status --all

Active: AUTH-001 (implement)
Paused: METRICS-001 (specify), BUG-042 (investigate)
Done: AUTH-002 (4h 30m ago)
```

**Abandon workflow:**
```bash
/spec-drive:abandon SPEC-ID
# Removes from queue, cleans up state
```

**Resume workflow:**
```bash
/spec-drive:switch SPEC-ID
# Restores from last snapshot
```

#### Components

```
spec-drive/
├── commands/
│   ├── switch.md              # /spec-drive:switch command
│   ├── prioritize.md          # /spec-drive:prioritize command
│   └── abandon.md             # /spec-drive:abandon command
├── scripts/tools/
│   ├── workflow-queue.js      # Queue management logic
│   ├── detect-conflicts.js    # File lock conflict detection
│   └── manage-snapshots.js    # State snapshot management
└── .spec-drive/state.yaml     # Enhanced with multi-workflow support
```

---

### ENHANCEMENT 6: Error Recovery

**What It Delivers:**

Automatic retry, rollback, and resume capabilities for robust workflow execution.

#### Problem

v0.1 workflows are fragile:
- Gate failure → stuck, manual retry only
- Implementation error → no rollback, start over
- Interrupted workflow (crash, close session) → lost progress

#### Solution

Three recovery mechanisms: auto-retry, rollback, resume.

#### Auto-Retry

**Trigger:** Gate failure (tests fail, linting errors, type-check errors)

**Flow:**
1. Gate check fails
2. Log error details
3. Attempt fix (if simple):
   - Linting errors → run auto-formatter
   - Import errors → suggest imports
   - Simple test failures → show error, suggest fix
4. Retry gate check (max 3 attempts)
5. If all retries fail → escalate to user

**Example:**
```
Gate 3 (Implement → Verify) FAILED:
  ❌ ESLint errors:
     src/auth/mfa.ts:45 - Missing semicolon
     src/auth/mfa.ts:67 - Unused variable 'temp'

Auto-fix attempt 1/3:
  Running: npm run lint -- --fix
  ✅ Fixed: 2 errors

Retry gate 3:
  ✅ ESLint passes
  ✅ TypeScript compiles
  ✅ Tests pass

Gate 3 PASSED (retry 1/3)
```

**Retry State:**
```yaml
# state.yaml
workflows:
  AUTH-001:
    stage: implement
    retry_count: 1
    retry_history:
      - attempt: 1
        error: "ESLint errors"
        fix: "npm run lint --fix"
        result: "success"
```

#### Rollback

**Trigger:** Critical failure (cannot auto-fix, user requests rollback)

**Flow:**
1. Critical failure detected
2. Prompt user: "Rollback to previous stage?"
3. If yes:
   - Restore previous snapshot
   - Revert uncommitted changes (git reset)
   - Set stage to previous stage
   - Clear can_advance flag
4. User can retry or take different approach

**Example:**
```
Gate 3 (Implement → Verify) FAILED:
  ❌ Tests fail with segfault (100% failure rate)
  ❌ Cannot auto-fix (critical error)

Retry attempts: 3/3 exhausted

Options:
  (A) Rollback to Specify stage (recommended)
  (B) Debug manually (stay in Implement)
  (C) Abandon workflow

Recommend: (A) Rollback and rethink implementation approach

User: A

Rolling back AUTH-001:
  ✅ Restored snapshot: Specify stage (2025-11-01T10:00:00Z)
  ✅ Reverted uncommitted changes: src/auth/mfa.ts, tests/auth/mfa.test.ts
  ✅ Stage: Implement → Specify

You can now:
  - Review spec: specs/AUTH-001.yaml
  - Adjust approach
  - Try implementation again with different strategy
```

#### Resume

**Trigger:** Workflow interrupted (session ended, crash, disconnect)

**Detection:** On SessionStart, check for active workflows with dirty flag

**Flow:**
1. SessionStart hook detects interrupted workflow
2. Load last snapshot
3. Prompt user: "Resume AUTH-001 (Implement stage)?"
4. If yes:
   - Set as current_workflow
   - Display context (stage, files modified, next steps)
   - Continue from where left off

**Example:**
```
SessionStart detected interrupted workflow:

  AUTH-001 (Feature: MFA Login)
    Stage: Implement
    Last activity: 2 hours ago
    Files modified: src/auth/mfa.ts (uncommitted)

  Resume? (y/n)

User: y

Resumed AUTH-001:
  Current stage: Implement
  Files locked: src/auth/mfa.ts, tests/auth/mfa.test.ts
  Next: Complete implementation, run gate 3

  Recent changes (uncommitted):
    src/auth/mfa.ts: +45 lines (verifyMfa function)

  To proceed:
    - Finish implementation
    - Run tests: npm test
    - Advance to Verify: (automatic after gate passes)
```

#### State Snapshots

**When created:**
- At each stage transition (after gate passes)
- Before major operations (rollback checkpoint)
- On user request (`/spec-drive:snapshot`)

**What's saved:**
```yaml
snapshots:
  - stage: specify
    timestamp: 2025-11-01T09:30:00Z
    spec_file: specs/AUTH-001.yaml
    git_commit: abc123  # If committed
    files_modified: []

  - stage: implement
    timestamp: 2025-11-01T10:00:00Z
    spec_file: specs/AUTH-001.yaml
    git_commit: def456
    files_modified:
      - src/auth/mfa.ts
      - tests/auth/mfa.test.ts
```

**Restore snapshot:**
```bash
/spec-drive:rollback AUTH-001 specify
# Restores to Specify stage snapshot
```

#### Retry Strategies

**Strategy 1: Simple Auto-Fix**
- Linting errors → run linter with --fix
- Formatting errors → run formatter
- Import errors → suggest missing imports

**Strategy 2: Incremental Retry**
- Test failures → run failing test in isolation, show error
- Type errors → show type mismatch, suggest fix
- Build errors → show build log, highlight error

**Strategy 3: Escalation**
- After 3 failed attempts → escalate to user
- Show error history
- Suggest: rollback, manual fix, or abandon

#### Components

```
spec-drive/
├── scripts/tools/
│   ├── retry-gate.sh          # Gate retry logic
│   ├── rollback-workflow.sh   # Rollback mechanism
│   ├── create-snapshot.sh     # Snapshot creation
│   └── restore-snapshot.sh    # Snapshot restoration
├── hooks/handlers/
│   └── session-start.sh       # Updated: detect interrupted workflows
└── .spec-drive/state.yaml     # Enhanced with retry, snapshot tracking
```

#### State Schema Updates

```yaml
workflows:
  SPEC-ID:
    # ... existing fields ...
    retry_count: 0
    retry_history: []
    snapshots: []
    interrupted: false  # Set true if session ends mid-workflow
    last_activity: timestamp
```

---

## 6. SUCCESS CRITERIA FOR v0.2

### Enhancement 1: Specialist Agents
- ✅ spec-agent creates valid SPEC-XXX.yaml with completeness checks
- ✅ impl-agent writes code with @spec tags, follows stack conventions
- ✅ test-agent writes tests before implementation (TDD pattern)
- ✅ Feature workflow delegates to all 3 agents successfully
- ✅ Agents adapt to detected stack profile (TypeScript vs Python tested)
- ✅ Manual workflow tasks reduced by ≥60%

### Enhancement 2: Additional Workflows
- ✅ Bugfix workflow completes end-to-end (investigate → fix → verify)
- ✅ BUG-XXX.yaml template works for real bugs
- ✅ Research workflow produces ADR-XXXX.md with decision rationale
- ✅ All 3 workflows (feature, bugfix, research) operational
- ✅ Can create bugfix while feature workflow paused

### Enhancement 3: Stack Profiles
- ✅ 4 stack profiles implemented (TypeScript/React, Python/FastAPI, Go, Rust)
- ✅ Auto-detection works on real TypeScript and Python projects
- ✅ Stack-specific gates enforce correctly:
  - TypeScript: ESLint, tsc, no 'any' types
  - Python: pytest, mypy, black, pylint
- ✅ Agent templates use profile variables correctly
- ✅ Generic profile still works for unknown stacks

### Enhancement 4: Index Optimizations
- ✅ AI summaries generated for all components/specs/docs/code
- ✅ Summaries are 1-2 sentences, accurate
- ✅ Query patterns answer top 10 FAQs instantly (no file reads)
- ✅ Changes feed tracks last 20 updates accurately
- ✅ Context reduction ≥90% measured (query "how does X work?" uses <1KB)

### Enhancement 5: Multi-Feature State
- ✅ 3+ workflows active simultaneously without conflicts
- ✅ Context switching works (`/spec-drive:switch SPEC-ID`)
- ✅ Workflow queue displays with priority ordering
- ✅ File conflict detection prevents simultaneous edits
- ✅ Priority management works (bugfix auto-priority 0)
- ✅ Abandoned workflows clean up properly

### Enhancement 6: Error Recovery
- ✅ Failed gates auto-retry (max 3 attempts)
- ✅ Simple errors auto-fix (linting, formatting)
- ✅ Rollback restores previous stage successfully
- ✅ Resume works after session interruption
- ✅ Snapshots created at each stage transition
- ✅ Recovery rate ≥80% (80% of failures recover without manual intervention)

### Integration
- ✅ All 6 enhancements work together seamlessly
- ✅ Developer can:
  - Start feature workflow with agents (automated)
  - Switch to bugfix workflow (multi-workflow)
  - Stack-specific gates enforce (stack profiles)
  - Query index for instant answers (index optimizations)
  - Resume after interruption (error recovery)
- ✅ Developer velocity: Features completed 40% faster vs v0.1 manual workflows

---

## 7. NON-NEGOTIABLES

### Quality
(Inherited from v0.1, plus:)
- Specialist agents must be stack-aware (not generic)
- Multi-workflow state must prevent file conflicts
- Error recovery must preserve data (no silent failures)
- AI summaries must be regenerable (not hand-written)
- Retry attempts must be bounded (max 3, no infinite loops)

### User Experience
(Inherited from v0.1, plus:)
- Context switching must be instant (<1s)
- Conflict detection must warn before data loss
- Resume prompt must show context (what was I doing?)
- Rollback must be safe (no uncommitted work lost)

### Technical
(Inherited from v0.1, plus:)
- Stack profiles must be extensible (user can add custom profiles)
- State.yaml must handle concurrent access (atomic updates)
- Snapshots must be lightweight (no large file copies)
- AI summaries must timeout (max 10s per summary)

---

## 8. OUT OF SCOPE FOR v0.2

### Deferred to v0.3:
- Lead agents (feature-lead, bugfix-lead, research-lead, general-lead)
- SessionStart hook auto-injection of lead agents
- Stack-aware lead agent templates
- Custom lead agents (deploy-lead, refactor-lead)

### Deferred to v0.4:
- Advanced traceability (automatic @spec tag injection)
- Bidirectional navigation (click spec → jump to code)
- Trace visualization (spec → code → test → doc graph)

### Deferred to v0.5+:
- DocReviewAgent (drift detection with proactive alerts)
- Context optimization (AI summary generation at write-time)
- Workflow customization (user-defined workflows)
- Team features (multi-user state, assignments)
- CI/CD integration (run workflows in CI)
- Metrics dashboards (workflow analytics)

### Never Planned:
- Multi-user collaboration (concurrent editing)
- Cloud sync of state/config
- IDE plugins or extensions
- Runtime performance monitoring
- Automated PR creation

---

## 9. RISKS & MITIGATIONS

### Risk 1: Specialist Agents Too Generic
**Likelihood:** Medium
**Impact:** High (agents don't provide value)

**Mitigation:**
- Agents use stack profile variables for all enforcement
- Test agents on real TypeScript and Python projects
- Collect feedback, tune agent behaviors per stack
- Allow user override of agent suggestions

### Risk 2: Multi-Workflow File Conflicts
**Likelihood:** High (common in real development)
**Impact:** Medium (data loss if not handled)

**Mitigation:**
- Track file locks per workflow
- Warn on conflict before switching
- Require commit or force flag for conflict switch
- Show which workflow has lock

### Risk 3: AI Summaries Inaccurate
**Likelihood:** Medium (LLM hallucination risk)
**Impact:** Low (context reduction benefit > accuracy risk)

**Mitigation:**
- Summaries regenerable (not permanent)
- Show last-updated timestamp
- Allow manual override (edit index.yaml)
- Validate summaries against file content (length check)

### Risk 4: Auto-Retry Infinite Loops
**Likelihood:** Low (if unbounded)
**Impact:** High (stuck workflow)

**Mitigation:**
- Hard limit: max 3 retries
- Exponential backoff (1s, 5s, 15s delays)
- Escalate to user after 3 failures
- Track retry history in state.yaml

### Risk 5: State Corruption with Multiple Workflows
**Likelihood:** Medium (concurrent access risk)
**Impact:** High (workflow data lost)

**Mitigation:**
- Atomic state updates (read-modify-write)
- Snapshots as backup (restore if corruption detected)
- Validation on state.yaml load (schema check)
- Warn user if state.yaml modified externally

### Risk 6: Stack Profile Auto-Detection Failures
**Likelihood:** Medium (edge cases, monorepos)
**Impact:** Low (falls back to generic)

**Mitigation:**
- Robust detection heuristics (multiple indicators)
- Fallback to generic profile (always works)
- Allow manual override in config.yaml
- Support multiple profiles (monorepo support)

---

## 10. VALIDATION PLAN

### Pre-Release Testing

**Test Scenario 1: Multi-Workflow Concurrent Development**
1. Init TypeScript/React project
2. Start feature workflow: AUTH-001 (MFA Login)
3. Progress to Implement stage with impl-agent
4. Switch to bugfix: BUG-042 (Login fails special chars)
5. Complete bugfix workflow (investigate → fix → verify)
6. Switch back to AUTH-001, resume Implement
7. Switch to research: "auth provider selection" (1h timebox)
8. Complete research, create ADR-0003
9. Switch back to AUTH-001, complete to Done
10. Verify: All 3 workflows complete, no conflicts, all traces complete

**Success Criteria:**
- ✅ 3 workflows active simultaneously
- ✅ Context switching works without data loss
- ✅ Priority ordering respected (bugfix auto-priority 0)
- ✅ File conflicts detected and prevented
- ✅ All workflow outputs valid (spec, code, tests, docs, ADR)

---

**Test Scenario 2: Stack Profile Enforcement (TypeScript/React)**
1. Init TypeScript/React project
2. Verify: Auto-detected typescript-react profile
3. Run feature workflow with spec-agent
4. spec-agent creates SPEC-001.yaml
5. Delegate to impl-agent + test-agent
6. impl-agent creates component: UserProfile.tsx
7. Verify: Component uses PascalCase, props interface exported
8. test-agent creates UserProfile.test.tsx
9. Verify: Test uses React Testing Library patterns
10. Run Gate 3:
    - ESLint passes
    - TypeScript compiles
    - No 'any' types detected
    - Tests pass
11. Verify: All stack-specific gates enforced

**Success Criteria:**
- ✅ Auto-detection works (package.json + tsconfig.json + react dep)
- ✅ impl-agent follows TypeScript/React conventions
- ✅ test-agent uses React Testing Library
- ✅ Stack-specific gates run (ESLint, tsc, grep 'any')
- ✅ No generic fallback behaviors

---

**Test Scenario 3: Stack Profile Enforcement (Python/FastAPI)**
1. Init Python/FastAPI project
2. Verify: Auto-detected python-fastapi profile
3. Run feature workflow
4. impl-agent creates router: user_routes.py
5. Verify: Uses async def, Pydantic models, HTTPException
6. test-agent creates test_user_routes.py
7. Verify: Uses pytest fixtures, async test patterns
8. Run Gate 3:
    - pytest passes
    - mypy type check passes
    - black formatting passes
    - pylint passes (≥9.0 score)
9. Verify: All stack-specific gates enforced

**Success Criteria:**
- ✅ Auto-detection works (requirements.txt + fastapi dep)
- ✅ impl-agent follows Python/FastAPI conventions
- ✅ test-agent uses pytest patterns
- ✅ Stack-specific gates run (pytest, mypy, black, pylint)
- ✅ Type hints enforced

---

**Test Scenario 4: Specialist Agent Coordination**
1. Start feature workflow: METRICS-001 (Usage metrics export)
2. Complete Discover stage (manual)
3. Delegate to spec-agent for Specify stage
4. spec-agent creates specs/METRICS-001.yaml:
   - User stories present
   - ACs in Given/When/Then format
   - Success criteria measurable
   - No [NEEDS CLARIFICATION] markers
5. Approve spec, advance to Implement
6. Delegate to test-agent
7. test-agent creates tests (TDD):
   - tests/api/metrics.test.ts
   - All ACs have test coverage
   - @spec METRICS-001 tags present
8. Tests fail (no implementation yet)
9. Delegate to impl-agent
10. impl-agent implements:
    - src/api/metrics.ts
    - Follows TypeScript conventions
    - @spec METRICS-001 tags present
    - Error handling complete
11. Run tests: All pass
12. Verify Gate 3: All checks pass

**Success Criteria:**
- ✅ spec-agent creates complete, valid spec
- ✅ test-agent writes tests before implementation (TDD)
- ✅ impl-agent implements to spec
- ✅ All agents add @spec tags
- ✅ Code follows stack conventions
- ✅ Tests pass after implementation

---

**Test Scenario 5: Index Optimizations**
1. Complete AUTH-001 feature workflow
2. Verify: Index has AI summaries for:
   - components.auth-service.summary
   - specs.AUTH-001.summary
   - docs["docs/60-features/AUTH-001.md"].summary
   - code["src/auth/mfa.ts"].summary
3. Query: "How does MFA work?"
4. Measure context usage (should be <1KB)
5. Verify: Answer from summary only (no file reads)
6. Query: "How to add an endpoint?"
7. Verify: Pre-answered query used (index.queries[])
8. Make code change: Add SMS fallback to mfa.ts
9. Verify: Changes feed updated (index.changes[0])
10. Query recent changes
11. Verify: Shows last change with diff stats

**Success Criteria:**
- ✅ AI summaries generated (1-2 sentences)
- ✅ Query "how does X work" uses <1KB context (90% reduction)
- ✅ Pre-answered queries work (instant answers)
- ✅ Changes feed tracks updates (last 20 entries)
- ✅ Summaries accurate and helpful

---

**Test Scenario 6: Error Recovery**
1. Start feature workflow: TEST-001
2. Implement with intentional linting error:
   ```typescript
   // Missing semicolon, unused variable
   const temp = 5
   console.log("hello")
   ```
3. Run Gate 3
4. Verify: Fails with ESLint errors
5. Verify: Auto-retry triggered
6. Verify: npm run lint --fix runs
7. Verify: Errors fixed automatically
8. Verify: Gate 3 retried and passes
9. Introduce critical error (segfault in tests)
10. Run Gate 3
11. Verify: Auto-retry fails 3 times
12. Verify: Prompt to rollback
13. User selects rollback
14. Verify: Stage restored to Specify
15. Close session mid-workflow
16. Reopen session
17. Verify: Resume prompt shows
18. User resumes
19. Verify: Workflow continues from last snapshot

**Success Criteria:**
- ✅ Auto-retry fixes simple errors (linting, formatting)
- ✅ Max 3 retries enforced
- ✅ Rollback restores previous stage
- ✅ Resume works after interruption
- ✅ State snapshots preserve progress
- ✅ ≥80% of failures recover automatically

---

## 11. FUTURE ROADMAP

### v0.3: Lead Agents & Drift Detection (Estimated 2-3 months post-v0.2)

**Goal:** Add workflow-specific lead agents that enforce stack-aware behaviors via SessionStart hook.

**Features:**
- Lead agents (feature-lead, bugfix-lead, research-lead, general-lead)
- SessionStart hook injects lead agent based on active workflow
- Lead agents use stack profile variables (stack-aware enforcement)
- DocReviewAgent proactive drift detection
- Advanced traceability (automatic tag injection)

**Benefits:**
- Consistent behavior enforcement across all sessions
- Stack-aware planning and delegation
- Reduced manual quality checks

---

### v0.4: Advanced Traceability (Estimated 3-4 months post-v0.2)

**Goal:** Automatic @spec tag management and bidirectional navigation.

**Features:**
- Automatic @spec tag injection (agents add tags, no manual tagging)
- Bidirectional navigation (click spec → jump to code, code → spec)
- Trace visualization (graph view: spec → code → test → doc)
- Tag validation (detect orphaned tags, missing tags)

**Benefits:**
- Zero-effort traceability maintenance
- Visual trace inspection
- Automatic gap detection

---

### v0.5: Full Autodocs Agents (Estimated 4-5 months post-v0.2)

**Goal:** Complete autodocs system with all specialist doc agents.

**Features:**
- Split DocUpdateAgent → 5 specialists (DocAPIAgent, DocArchAgent, DocBuildAgent, DocFeatureAgent, DocProductAgent)
- docs/30-operations/ (RUNBOOKS.md, SLOs.md)
- DocOpsAgent
- Category commands (/docs-refresh-arch, /docs-refresh-build)

**Benefits:**
- Granular control over doc updates
- Operations docs maintained
- Category-specific regeneration

---

### v1.0: Production Ready (Estimated 4-6 months post-v0.2)

**Goal:** Stable, production-ready plugin used on multiple real projects.

**Criteria:**
- All workflows stable and tested
- Used on 5+ real projects successfully
- Performance optimized (<1s response times)
- Comprehensive error handling (all edge cases covered)
- Full documentation (guides, tutorials, examples)
- Public marketplace release

**Features:**
- Workflow customization (user-defined workflows)
- Team features (multi-user state, assignments)
- CI/CD integration (run workflows in CI)
- Metrics dashboards (workflow analytics)

---

## 12. PLANNING DOCUMENT STRUCTURE

### Planning Documents Organization

This PRD is part of a comprehensive planning documentation set located in:
```
.spec-drive/development/planned/v0.2/
├── PRD.md                        # This document
├── TDD.md                        # Technical Design Document (to be created)
├── IMPLEMENTATION-PLAN.md        # High-level implementation phases (to be created)
├── TEST-PLAN.md                  # Testing strategy and scenarios (to be created)
├── RISK-ASSESSMENT.md            # Risk identification and mitigation (to be created)
├── STATUS.md                     # Project status tracking (to be created)
├── tasks/                        # Individual task files (detailed, to be created)
│   ├── phase-1-specialist-agents/
│   │   ├── task-001-spec-agent.md
│   │   ├── task-002-impl-agent.md
│   │   └── task-003-test-agent.md
│   ├── phase-2-workflows/
│   │   ├── task-010-bugfix-workflow.md
│   │   └── task-011-research-workflow.md
│   ├── phase-3-stack-profiles/
│   │   ├── task-020-python-fastapi-profile.md
│   │   ├── task-021-go-profile.md
│   │   └── task-022-rust-profile.md
│   ├── phase-4-index-optimizations/
│   │   ├── task-030-ai-summaries.md
│   │   ├── task-031-query-patterns.md
│   │   └── task-032-changes-feed.md
│   ├── phase-5-multi-workflow/
│   │   ├── task-040-workflow-queue.md
│   │   ├── task-041-context-switching.md
│   │   └── task-042-conflict-detection.md
│   └── phase-6-error-recovery/
│       ├── task-050-auto-retry.md
│       ├── task-051-rollback.md
│       └── task-052-resume.md
└── adr/                          # Architecture Decision Records (to be created)
```

### Task-Based Implementation

Rather than a single monolithic IMPLEMENTATION-PLAN.md (which becomes too long to read), implementation is broken into individual task files in the `tasks/` directory.

**Each task file (`task-XXX-name.md`) contains:**
- Task ID and title
- Status (not-started, in-progress, blocked, completed)
- Dependencies (what tasks must complete first)
- Acceptance criteria (testable conditions)
- Implementation details (steps, files, code snippets)
- Testing approach (how to verify)
- Risks and mitigations
- Completion checklist

**Benefits:**
- **Readable:** Each task is self-contained and focused
- **Trackable:** Clear status per task
- **Parallelizable:** Independent tasks can be worked concurrently
- **Reviewable:** Easy to review individual tasks
- **AI-friendly:** Claude can read one task file at a time

**Estimated Task Count:**
- Phase 1 (Specialist Agents): ~5 tasks
- Phase 2 (Workflows): ~4 tasks
- Phase 3 (Stack Profiles): ~5 tasks
- Phase 4 (Index Optimizations): ~6 tasks
- Phase 5 (Multi-Workflow): ~7 tasks
- Phase 6 (Error Recovery): ~6 tasks
- **Total:** ~33 tasks

### Planning Templates

Templates for all planning documents are available in:
```
.spec-drive/templates/planning/
├── PRD-TEMPLATE.md
├── TDD-TEMPLATE.md
├── TEST-PLAN-TEMPLATE.md
├── RISK-ASSESSMENT-TEMPLATE.md
├── STATUS-TEMPLATE.md
└── TASK-TEMPLATE.md
```

These templates ensure consistent structure across all planning documents and can be used to create the remaining v0.2 planning documents.

---

## 13. APPENDIX: TECHNICAL SPECIFICATIONS

### A. Component Inventory

#### New Commands (6)
```
spec-drive/commands/
├── bugfix.md                  # /spec-drive:bugfix [BUG-ID] [symptom]
├── research.md                # /spec-drive:research [topic] [timebox]
├── switch.md                  # /spec-drive:switch [SPEC-ID]
├── prioritize.md              # /spec-drive:prioritize [SPEC-ID] [priority]
├── abandon.md                 # /spec-drive:abandon [SPEC-ID]
└── rollback.md                # /spec-drive:rollback [SPEC-ID] [stage]
```

#### New Agents (3)
```
spec-drive/agents/
├── spec-agent.md              # Spec creation specialist
├── impl-agent.md              # Implementation specialist
└── test-agent.md              # Test creation specialist
```

#### New Scripts (12)
```
spec-drive/scripts/
├── workflows/
│   ├── bugfix.sh              # Bugfix workflow orchestrator
│   └── research.sh            # Research workflow orchestrator
├── tools/
│   ├── generate-summaries.js      # AI summary generation
│   ├── update-index-queries.js    # Query pattern updates
│   ├── update-index-changes.js    # Changes feed updates
│   ├── validate-spec.js           # Spec validation
│   ├── workflow-queue.js          # Multi-workflow queue
│   ├── detect-conflicts.js        # File conflict detection
│   ├── retry-gate.sh              # Auto-retry logic
│   ├── rollback-workflow.sh       # Rollback mechanism
│   ├── create-snapshot.sh         # Snapshot creation
│   └── restore-snapshot.sh        # Snapshot restoration
└── stack-detection.py         # Enhanced (v0.2)
```

#### New Templates (1)
```
spec-drive/templates/
└── BUG-TEMPLATE.yaml          # Bug spec template
```

#### New Stack Profiles (3)
```
spec-drive/stack-profiles/
├── python-fastapi.yaml        # Python/FastAPI profile
├── go.yaml                    # Go profile
└── rust.yaml                  # Rust profile
# generic.yaml and typescript-react.yaml from v0.1
```

#### Updated Files (3)
```
spec-drive/
├── hooks/handlers/
│   ├── post-tool-use.sh       # Enhanced: trigger summaries/changes
│   └── session-start.sh       # Enhanced: detect interrupted workflows
└── .spec-drive/
    ├── index.yaml             # Enhanced: summaries, queries, changes
    └── state.yaml             # Enhanced: multi-workflow support
```

---

### B. State Schema (v0.2)

```yaml
# .spec-drive/state.yaml
current_workflow: SPEC-ID  # Currently active workflow
dirty: boolean             # Files modified since last doc update

workflows:
  SPEC-ID:
    type: feature|bugfix|research
    spec: SPEC-ID
    stage: discover|specify|implement|verify
    status: active|paused|blocked|done
    started: timestamp
    priority: 0-9  # 0=highest
    files_locked: [paths]
    retry_count: 0
    retry_history:
      - attempt: 1
        error: "error description"
        fix: "fix applied"
        result: "success|failure"
    snapshots:
      - stage: stage_name
        timestamp: timestamp
        spec_file: path
        git_commit: hash
        files_modified: [paths]
    interrupted: boolean
    last_activity: timestamp

history:
  - workflow: SPEC-ID
    type: feature|bugfix|research
    completed: timestamp
    duration: "Xh Ym"
```

---

### C. Index Schema (v0.2)

```yaml
# .spec-drive/index.yaml
meta:
  generated: timestamp
  version: "2.0"
  project: string

components:
  component-id:
    summary: "1-2 sentence summary"  # NEW
    type: service|component|utility
    apis: [endpoints]
    files: [file:line]
    tests: [file:line]
    specs: [SPEC-ID]
    docs: [doc-path]
    owner: string
    status: production|beta|deprecated

specs:
  SPEC-ID:
    title: string
    summary: "1-2 sentence summary"  # NEW
    status: draft|specified|implemented|verified|done
    owner: string
    acs: number
    code: [file:line]
    tests: [file:line]
    docs: [doc-path]
    arch: [doc-path]
    observability:
      metrics: [metric-name]
      logs: [log-name]
    updated: timestamp

docs:
  "doc-path":
    summary: "1-2 sentence summary"  # NEW
    tags: [tag]
    tier: 1|2|3
    owner: string
    updated: timestamp
    ttl: Nd
    status: fresh|stale

code:
  "file-path":
    summary: "1-2 sentence summary"  # NEW
    specs: [SPEC-ID]
    components: [component-id]
    tests: [file-path]
    apis: [endpoint]
    docs: [doc-path]
    updated: timestamp
    loc: number
    coverage: percentage

queries:  # NEW
  "query-text":
    answer: string
    refs: [file-path]

changes:  # NEW
  - timestamp: timestamp
    type: code|spec|doc|arch
    file: path
    summary: string
    specs: [SPEC-ID]
    diff_lines: "+X -Y"
    author: string
    trigger: manual|DocUpdateAgent|user
```

---

### D. BUG-XXX.yaml Schema

```yaml
---
id: BUG-XXX
title: string
status: draft|investigating|fixing|verifying|done
type: bugfix
severity: critical|high|medium|low
created: date
updated: date
owner: string

symptom: |
  Multi-line description of bug symptom

investigation:
  root_cause: |
    Multi-line root cause analysis

  reproduction:
    - step 1
    - step 2
    - step 3

  impact:
    - "Users: affected user count/percentage"
    - "Severity: impact description"
    - "Workaround: workaround if any"

fix_approach:
  description: |
    Multi-line fix approach

  changes:
    - "file:line - change description"

  regression_tests:
    - "test case 1"
    - "test case 2"

  risks:
    - "Risk: risk description"
      mitigation: "mitigation approach"

trace:
  code: []       # Populated by impl-agent
  tests: []      # Populated by test-agent
  docs: []       # Populated by doc-agents
```

---

### E. Stack Profile Schema

```yaml
profile: string  # typescript-react, python-fastapi, etc.
description: string

detection:
  files: [file-path]
  markers: [dependency-checks]

behaviors:
  quality_gates:
    - name: string
      command: string
      expect: string

  patterns:
    pattern_name: glob-pattern

  conventions: [convention-description]

  enforcement: [enforcement-rule]

  docs_requirements: [requirement-description]

  pre_commit_hooks: [command]

  verification_commands: [command]
```

---

**Document Status:** Complete
**Next Steps:** Implementation planning, agent design, stack profile creation

---

**Approved By:** [Pending]
**Date:** [Pending]
