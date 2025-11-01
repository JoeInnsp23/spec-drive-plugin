# SPEC-DRIVE v0.2 TECHNICAL DESIGN DOCUMENT

**Version:** 1.0
**Date:** 2025-11-01
**Status:** Draft
**Related PRD:** `.spec-drive/development/planned/v0.2/PRD.md`

---

## 1. OVERVIEW

### Purpose

This TDD defines the technical architecture and implementation design for spec-drive v0.2, which adds 6 major enhancements to the v0.1 foundation:

1. **Specialist Agents** - spec-agent, impl-agent, test-agent for workflow automation
2. **Additional Workflows** - Bugfix and Research workflows
3. **Stack Profiles** - TypeScript/React, Python/FastAPI, Go, Rust
4. **Index Optimizations** - AI summaries, query patterns, changes feed
5. **Multi-Workflow State** - Concurrent workflow support with conflict detection
6. **Error Recovery** - Auto-retry, rollback, resume capabilities

### Scope

**In Scope:**
- 6 new commands (/spec-drive:bugfix, research, switch, prioritize, abandon, rollback)
- 3 specialist agents (Claude Code subagents via Task tool)
- 2 new workflows (bugfix, research) + enhanced feature workflow
- 4 stack profiles (Python/FastAPI, Go, Rust) + enhanced TypeScript/React
- Index v2.0 (AI summaries, queries, changes)
- state.yaml v2.0 (multi-workflow support)
- 12 new scripts (workflows, tools, gates)
- Error recovery mechanisms (retry, rollback, resume)

**Out of Scope:**
- Lead agents (v0.3+)
- Automatic @spec tag injection (v0.4+)
- Drift detection with DocReviewAgent (v0.5+)
- Team collaboration features (v1.0+)
- CI/CD integration (v1.0+)

### Goals

1. **60% Automation:** Reduce manual workflow tasks via specialist agents
2. **Multi-Workflow Support:** 3+ concurrent workflows without conflicts
3. **Stack Awareness:** 100% quality gates adapted to detected stack
4. **90% Context Reduction:** Via AI summaries + query patterns
5. **80% Recovery Rate:** Auto-retry successfully resolves gate failures
6. **40% Velocity Increase:** Features complete faster with agents vs manual

---

## 2. ARCHITECTURE

### High-Level Architecture

```
┌─────────────────── Claude Code Session ───────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ SessionStart Hook                                   │  │
│  │ • Injects strict-concise behavior agent (v0.1)      │  │
│  │ • Detects interrupted workflows → prompt resume     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ User Commands                                       │  │
│  │ • /spec-drive:feature  (enhanced with agents)       │  │
│  │ • /spec-drive:bugfix   (NEW - 4 stages)             │  │
│  │ • /spec-drive:research (NEW - 3 stages)             │  │
│  │ • /spec-drive:switch   (NEW - workflow switching)   │  │
│  │ • /spec-drive:rollback (NEW - error recovery)       │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Workflow Orchestrators                               │  │
│  │ • feature.sh  (delegates to agents)                 │  │
│  │ • bugfix.sh   (NEW - investigate→fix→verify)        │  │
│  │ • research.sh (NEW - explore→decide→ADR)            │  │
│  └─────────────────────────────────────────────────────┘  │
│         ↓                 ↓                 ↓              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ spec-agent  │  │ impl-agent  │  │ test-agent  │      │
│  │ (Subagent)  │  │ (Subagent)  │  │ (Subagent)  │      │
│  │ Creates     │  │ Writes code │  │ Writes tests│      │
│  │ specs       │  │ w/ @spec    │  │ TDD-first   │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
│         ↓                 ↓                 ↓              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Stack Profiles (NEW)                                │  │
│  │ • typescript-react.yaml                             │  │
│  │ • python-fastapi.yaml                               │  │
│  │ • go.yaml                                           │  │
│  │ • rust.yaml                                         │  │
│  │ Provides: {STACK_QUALITY_GATES}, {STACK_PATTERNS}  │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Quality Gates (Stack-Aware)                         │  │
│  │ • Gate 1-4 (enhanced with profile variables)        │  │
│  │ • Auto-retry on failure (NEW - max 3 attempts)      │  │
│  │ • Rollback on critical failure (NEW)                │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ PostToolUse Hook                                    │  │
│  │ • Sets dirty flag (v0.1)                            │  │
│  │ • Triggers AI summary generation (NEW)              │  │
│  │ • Updates changes feed (NEW)                        │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ State Management (Enhanced)                         │  │
│  │ • state.yaml v2.0 (multi-workflow support)          │  │
│  │ • Workflow queue with priority                      │  │
│  │ • File lock tracking                                │  │
│  │ • Snapshots for rollback                            │  │
│  │ • Retry history                                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Index Management (Enhanced)                         │  │
│  │ • index.yaml v2.0 (NEW: summaries, queries, changes)│  │
│  │ • AI summary generation (Claude via Task tool)      │  │
│  │ • Pre-answered query patterns                       │  │
│  │ • Changes feed (last 20 updates)                    │  │
│  └─────────────────────────────────────────────────────┘  │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Documentation (Auto-Updated - v0.1)                 │  │
│  │ • docs/ structure (COMPONENT-CATALOG, features, API)│  │
│  │ • ADRs for v0.2 decisions                           │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Component Overview

| Component | Type | Responsibility | Dependencies |
|-----------|------|----------------|--------------|
| spec-agent | Subagent | Create SPEC-XXX.yaml with ACs | Stack profile, validate-spec.js |
| impl-agent | Subagent | Write code with @spec tags | Stack profile, spec file |
| test-agent | Subagent | Write tests TDD-first | Stack profile, spec file |
| bugfix.sh | Orchestrator | Run bugfix workflow stages | BUG-XXX.yaml template, gates |
| research.sh | Orchestrator | Run research workflow stages | ADR template |
| workflow-queue.js | Tool | Manage multi-workflow state | state.yaml v2.0 |
| detect-conflicts.js | Tool | Detect file lock conflicts | state.yaml v2.0 |
| generate-summaries.js | Tool | AI summarize components/code | Claude via Task tool, index.yaml |
| retry-gate.sh | Tool | Auto-retry failed gates | Quality gates, state.yaml |
| rollback-workflow.sh | Tool | Rollback to previous stage | Snapshots, git |
| Stack profiles (4) | Config | Stack-specific gates/patterns | stack-detection.py |
| state.yaml v2.0 | Data | Multi-workflow state | Workflows, gates |
| index.yaml v2.0 | Data | AI-optimized index | Auto-docs, summaries |

---

## 3. COMPONENT DESIGN

### 3.1 Specialist Agents

#### Agent 1: spec-agent

**Purpose:** Automate spec creation with completeness validation

**Location:** `spec-drive/agents/spec-agent.md`

**Type:** Claude Code Subagent (invoked via Task tool with subagent_type="general-purpose")

**Responsibilities:**
- Create `.spec-drive/specs/SPEC-XXX.yaml` from user requirements
- Add `[NEEDS CLARIFICATION]` markers for ambiguous requirements
- Validate no ambiguities remain before Specify → Implement
- Ensure all acceptance criteria in Given/When/Then format
- Define measurable success criteria
- Identify dependencies and constraints

**Interface:**
```bash
# Invoked by feature.sh orchestrator
Task(
  subagent_type="general-purpose",
  prompt="Create SPEC-${SPEC_ID}.yaml from requirements: ${REQUIREMENTS}.

  Stack: ${STACK_PROFILE}

  Requirements:
  - User stories clear and unambiguous
  - All ACs in Given/When/Then format
  - Measurable success criteria
  - Mark ambiguities with [NEEDS CLARIFICATION]

  Template: ${SPEC_TEMPLATE}

  Deliverable: Complete SPEC-${SPEC_ID}.yaml file"
)
```

**Dependencies:**
- Stack profile (for stack-specific conventions in examples)
- spec-template.yaml
- validate-spec.js (for post-creation validation)

**Data Flow:**
```
User Requirements → spec-agent → SPEC-XXX.yaml (draft) → validate-spec.js → Pass/Fail → User Review
```

**Implementation Notes:**
- Agent prompt must include stack profile variables (e.g., {STACK_EXAMPLE_TEST_FORMAT})
- Validation runs automatically after spec creation
- User must approve spec before proceeding to Implement stage
- Agent can iterate on spec if validation fails

---

#### Agent 2: impl-agent

**Purpose:** Implement code following spec requirements with traceability

**Location:** `spec-drive/agents/impl-agent.md`

**Type:** Claude Code Subagent (invoked via Task tool with subagent_type="general-purpose")

**Responsibilities:**
- Implement code to satisfy spec acceptance criteria
- Add `@spec SPEC-ID` tags to all implementations
- Follow stack-specific conventions (from profile)
- Enforce error handling and input validation
- No TODO/console.log/placeholders allowed
- Ensure code passes linting and type checks

**Interface:**
```bash
# Invoked by feature.sh orchestrator
Task(
  subagent_type="general-purpose",
  prompt="Implement SPEC-${SPEC_ID}.yaml requirements.

  Spec file: ${SPEC_FILE_PATH}
  Stack: ${STACK_PROFILE}

  Requirements:
  - Add @spec ${SPEC_ID} tag to all implementations
  - Follow stack conventions: ${STACK_CONVENTIONS}
  - Complete error handling (no silent failures)
  - Input validation for all public APIs
  - No TODO/console.log/placeholders

  Acceptance:
  - All spec ACs satisfied
  - Code passes: ${STACK_QUALITY_GATES}
  - @spec tags present

  Deliverable: Production-ready code with full traceability"
)
```

**Dependencies:**
- Stack profile (conventions, patterns, quality gates)
- SPEC-XXX.yaml file
- Test suite (from test-agent, TDD pattern)

**Data Flow:**
```
SPEC-XXX.yaml + Stack Profile → impl-agent → Code with @spec tags → Gate 3 (tests/lint/type-check) → Pass/Fail
```

**Implementation Notes:**
- impl-agent runs AFTER test-agent (TDD: tests first, then implementation)
- Stack profile variables injected: {STACK_CONVENTIONS}, {STACK_PATTERNS}
- Agent uses existing codebase patterns (via code analysis)
- Auto-retry via retry-gate.sh if linting/formatting failures

---

#### Agent 3: test-agent

**Purpose:** Write tests BEFORE implementation (TDD pattern)

**Location:** `spec-drive/agents/test-agent.md`

**Type:** Claude Code Subagent (invoked via Task tool with subagent_type="general-purpose")

**Responsibilities:**
- Write failing tests BEFORE implementation
- Cover all acceptance criteria from spec
- Add `@spec SPEC-ID` tags to test files
- Follow stack-specific test patterns
- Ensure edge cases and error paths tested
- Target ≥90% coverage

**Interface:**
```bash
# Invoked by feature.sh orchestrator (BEFORE impl-agent)
Task(
  subagent_type="general-purpose",
  prompt="Write tests for SPEC-${SPEC_ID}.yaml (TDD: tests first).

  Spec file: ${SPEC_FILE_PATH}
  Stack: ${STACK_PROFILE}

  Requirements:
  - Add @spec ${SPEC_ID} tag to all test files
  - Follow test patterns: ${STACK_TEST_PATTERNS}
  - Cover ALL acceptance criteria
  - Test edge cases and error paths
  - Tests should FAIL initially (TDD)

  Patterns: ${STACK_TEST_FRAMEWORK}
  Examples: ${STACK_TEST_EXAMPLES}

  Deliverable: Comprehensive test suite (initially failing)"
)
```

**Dependencies:**
- Stack profile (test framework, patterns, examples)
- SPEC-XXX.yaml file (acceptance criteria)

**Data Flow:**
```
SPEC-XXX.yaml + Stack Profile → test-agent → Failing Tests → impl-agent → Passing Tests
```

**Implementation Notes:**
- test-agent runs BEFORE impl-agent (strict TDD)
- Stack profile variables: {STACK_TEST_FRAMEWORK}, {STACK_TEST_PATTERNS}
- Tests must initially fail (validates TDD process)
- Coverage target: ≥90% (verified at Gate 3)

---

### 3.2 Workflow Orchestrators

#### Orchestrator 1: bugfix.sh

**Purpose:** Orchestrate bugfix workflow (investigate → specify-fix → fix → verify)

**Location:** `spec-drive/scripts/workflows/bugfix.sh`

**Type:** Bash Script

**Responsibilities:**
- Initialize bugfix workflow state
- Guide investigation stage (symptom analysis, reproduction)
- Create BUG-XXX.yaml spec
- Delegate fix implementation
- Run bugfix-specific quality gates
- Update index and docs
- Mark bugfix complete

**Interface:**
```bash
# Command: /spec-drive:bugfix BUG-042 "Auth fails with expired token"
./scripts/workflows/bugfix.sh <BUG-ID> <SYMPTOM>

# Creates state entry:
workflows:
  BUG-042:
    workflow: bugfix
    status: in_progress
    stage: investigate
    priority: 0  # Bugfixes always priority 0 (highest)
```

**Stages:**
1. **Investigate**
   - Entry: BUG-ID and symptom provided
   - Actions: Explore codebase, reproduce bug, identify root cause
   - Exit: Root cause documented, reproduction steps clear

2. **Specify Fix**
   - Entry: Root cause known
   - Actions: Create BUG-XXX.yaml with fix_approach, affected_components
   - Exit: Fix spec validated (no ambiguities)

3. **Fix**
   - Entry: Fix spec complete
   - Actions: Implement fix, write regression test, add @spec tags
   - Exit: Fix passes tests, no regressions

4. **Verify**
   - Entry: Fix implemented
   - Actions: Validate ACs met, docs updated, traceability complete
   - Exit: Bug marked resolved, workflow status: done

**Dependencies:**
- BUG-TEMPLATE.yaml (bugfix spec template)
- Bugfix quality gates (gate-1-bugfix-specify.sh, gate-2-bugfix-implement.sh, gate-3-bugfix-verify.sh)
- state.yaml v2.0 (multi-workflow support)

**Data Flow:**
```
User Command → bugfix.sh → State (investigate) → BUG-XXX.yaml → Gate 1 →
State (fix) → impl-agent (optional) → Gate 2 → State (verify) → Gate 3 → Done
```

**Implementation Notes:**
- Bugfix workflow lighter than feature (no spec-agent, faster gates)
- Priority always 0 (highest) to encourage quick fixes
- Can run concurrently with feature workflows
- Regression test mandatory (prevents re-introduction)

---

#### Orchestrator 2: research.sh

**Purpose:** Orchestrate research workflow (explore → synthesize → decide)

**Location:** `spec-drive/scripts/workflows/research.sh`

**Type:** Bash Script

**Responsibilities:**
- Initialize research workflow state
- Guide exploration with timebox
- Synthesize findings (options, trade-offs)
- Facilitate decision-making
- Generate ADR-XXXX.md (Architecture Decision Record)
- Update docs and index

**Interface:**
```bash
# Command: /spec-drive:research "API versioning strategy" "2 hours"
./scripts/workflows/research.sh <TOPIC> <TIMEBOX>

# Creates state entry:
workflows:
  RES-001:
    workflow: research
    status: in_progress
    stage: explore
    priority: 7  # Lower priority (research not urgent)
    timebox: "2 hours"
```

**Stages:**
1. **Explore**
   - Entry: Topic and timebox defined
   - Actions: Research topic (web search, read docs, explore code), collect options
   - Exit: 2-4 options identified with pros/cons

2. **Synthesize**
   - Entry: Options collected
   - Actions: Document trade-offs, rank options, assess risks
   - Exit: Clear recommendation with rationale

3. **Decide**
   - Entry: Recommendation ready
   - Actions: User approves decision, create ADR-XXXX.md
   - Exit: ADR committed, research workflow complete

**Dependencies:**
- ADR-TEMPLATE.md (architecture decision template)
- WebSearch or WebFetch tools (research context)
- Timebox enforcement (warn at 80%, stop at 100%)

**Data Flow:**
```
User Command → research.sh → State (explore) → Findings (2-4 options) →
State (synthesize) → Recommendation → State (decide) → ADR-XXXX.md → Done
```

**Implementation Notes:**
- Timebox strict (prevents research rabbit holes)
- Can run concurrently with feature/bugfix workflows
- ADR required output (documents decision rationale)
- No quality gates (research is exploratory)

---

### 3.3 Multi-Workflow Management Tools

#### Tool 1: workflow-queue.js

**Purpose:** Manage multi-workflow queue and priority ordering

**Location:** `spec-drive/scripts/tools/workflow-queue.js`

**Type:** Node.js Script

**Responsibilities:**
- Add workflows to queue (CRUD operations on state.yaml)
- Sort workflows by priority (0=highest, 9=lowest)
- List active workflows
- Mark workflows complete or abandoned
- Move completed workflows to history

**Interface:**
```javascript
// CLI usage
node workflow-queue.js add <SPEC-ID> <WORKFLOW-TYPE> <PRIORITY>
node workflow-queue.js list
node workflow-queue.js remove <SPEC-ID>
node workflow-queue.js prioritize <SPEC-ID> <NEW-PRIORITY>

// Programmatic usage (from orchestrators)
const queue = require('./workflow-queue.js');
queue.add('AUTH-001', 'feature', 3);
queue.list(); // Returns sorted array
queue.prioritize('AUTH-001', 1); // Increase priority
```

**Dependencies:**
- state.yaml v2.0 (workflows{} structure)
- YAML parser (read/write state.yaml)

**Data Flow:**
```
Orchestrator → workflow-queue.js → state.yaml (atomic read-modify-write) → Success/Failure
```

**Implementation Notes:**
- Atomic updates (file locking to prevent corruption)
- Priority sorting: 0 (bugfix) → 1-5 (features) → 6-9 (research, low-priority)
- Validation: Max 10 concurrent workflows (prevent state bloat)
- History tracking: Completed workflows moved to history[] array

---

#### Tool 2: detect-conflicts.js

**Purpose:** Detect file lock conflicts between workflows

**Location:** `spec-drive/scripts/tools/detect-conflicts.js`

**Type:** Node.js Script

**Responsibilities:**
- Compare files_locked[] arrays between workflows
- Detect overlapping file locks
- Return conflict status + conflicting files
- Used by /spec-drive:switch command

**Interface:**
```javascript
// CLI usage
node detect-conflicts.js <CURRENT-SPEC-ID> <TARGET-SPEC-ID>

// Output (JSON):
{
  "conflict": true,
  "conflicting_files": [
    "src/auth/login.ts",
    "tests/auth/login.test.ts"
  ],
  "current_workflow": "AUTH-001",
  "target_workflow": "BUG-042"
}

// Programmatic usage
const conflicts = require('./detect-conflicts.js');
const result = conflicts.detect('AUTH-001', 'BUG-042');
if (result.conflict) {
  console.warn(`Conflict detected: ${result.conflicting_files.join(', ')}`);
}
```

**Algorithm:**
```javascript
function detectConflicts(currentSpecId, targetSpecId) {
  const state = readState();
  const currentFiles = state.workflows[currentSpecId].files_locked || [];
  const targetFiles = state.workflows[targetSpecId].files_locked || [];

  const conflicts = currentFiles.filter(file => targetFiles.includes(file));

  return {
    conflict: conflicts.length > 0,
    conflicting_files: conflicts,
    current_workflow: currentSpecId,
    target_workflow: targetSpecId
  };
}
```

**Dependencies:**
- state.yaml v2.0 (files_locked[] per workflow)

**Data Flow:**
```
/spec-drive:switch → detect-conflicts.js → state.yaml (read-only) → Conflict status → Warn user or Allow switch
```

**Implementation Notes:**
- Read-only operation (no state modification)
- O(n*m) complexity where n=current locks, m=target locks (acceptable for small lock arrays)
- Used pre-switch (prevent data loss)
- Exit codes: 0 (no conflict), 1 (conflict detected)

---

### 3.4 Index Optimization Tools

#### Tool 3: generate-summaries.js

**Purpose:** Generate AI summaries for components/specs/docs/code

**Location:** `spec-drive/scripts/tools/generate-summaries.js`

**Type:** Node.js Script

**Responsibilities:**
- Scan index.yaml for entries without summaries
- Call Claude via Task tool to generate 1-2 sentence summaries
- Update index.yaml with summaries
- Handle timeouts and failures gracefully
- Log summary generation events

**Interface:**
```javascript
// CLI usage
node generate-summaries.js [--type=<components|specs|docs|code>] [--file=<path>]

// Examples:
node generate-summaries.js --type=components  # Summarize all components
node generate-summaries.js --file=src/auth/login.ts  # Summarize one file

// Programmatic usage
const summaries = require('./generate-summaries.js');
await summaries.generate('components'); // Async, returns promise
```

**Algorithm:**
```javascript
async function generateSummaries(type) {
  const index = readIndex();
  const entries = index[type].filter(entry => !entry.summary);

  for (const entry of entries) {
    try {
      const content = readFile(entry.path);
      const summary = await callClaudeForSummary(content); // Via Task tool
      entry.summary = summary;
      entry.last_updated = new Date().toISOString();
    } catch (error) {
      if (error.timeout) {
        console.warn(`Timeout for ${entry.path}, skipping`);
        continue; // Skip this entry, don't block
      }
      throw error;
    }
  }

  writeIndex(index);
}

async function callClaudeForSummary(content) {
  // Use Task tool with general-purpose subagent
  return await Task({
    subagent_type: "general-purpose",
    model: "haiku", // Fast model for summaries
    prompt: `Summarize this code/component in 1-2 sentences (max 200 chars):

    ${content}

    Focus on: What it does, key responsibilities, NOT implementation details.`
  });
}
```

**Dependencies:**
- Claude API (via Task tool with subagent_type="general-purpose")
- index.yaml v2.0
- File system access (read source files)

**Data Flow:**
```
PostToolUse Hook → generate-summaries.js → Read File → Claude (summarize) → index.yaml (update) → Complete
```

**Implementation Notes:**
- Timeout: 10s per summary (configurable)
- Model: Haiku (fast, cost-effective)
- Retry: None (timeout = skip, regenerable later)
- Batching: Process 10 files at a time (reduce API overhead)
- Cache: Summaries regenerate only on file change (dirty flag)

**Performance Targets:**
- <10s per summary (average: 3-5s)
- <5% timeout rate
- ≥95% summary quality (subjective, user feedback)

---

#### Tool 4: update-index-queries.js

**Purpose:** Populate pre-answered query patterns in index.yaml

**Location:** `spec-drive/scripts/tools/update-index-queries.js`

**Type:** Node.js Script

**Responsibilities:**
- Define common developer queries (10-20 FAQs)
- Generate pre-answered responses from index data
- Update index.yaml queries{} section
- Enable instant query responses (<1KB context)

**Interface:**
```javascript
// CLI usage
node update-index-queries.js

// No parameters, updates all queries
```

**Query Patterns (Hardcoded Initially):**
```yaml
queries:
  "how does authentication work":
    answer: "Authentication handled by comp-auth-login (src/auth/login.ts:15). Uses JWT tokens, validates via validateToken(). Trace: AUTH-001."
    sources: ["comp-auth-login", "AUTH-001"]
    last_updated: "2025-11-01T10:30:00Z"

  "what are the main components":
    answer: "14 components: comp-auth-login, comp-user-service, comp-api-router, ... See COMPONENT-CATALOG.md for full list."
    sources: ["index.yaml/components"]
    last_updated: "2025-11-01T10:30:00Z"

  "how do I add a new feature":
    answer: "Run /spec-drive:feature SPEC-ID 'description'. Workflow: discover → specify → implement → verify. See docs/PRODUCT-BRIEF.md."
    sources: ["docs/PRODUCT-BRIEF.md"]
    last_updated: "2025-11-01T10:30:00Z"
```

**Algorithm:**
```javascript
function updateQueries() {
  const index = readIndex();
  const queries = {};

  // Query 1: How does X work?
  queries["how does authentication work"] = generateComponentQuery(index, "auth");
  queries["how does routing work"] = generateComponentQuery(index, "router");

  // Query 2: What components exist?
  queries["what are the main components"] = generateComponentListQuery(index);

  // Query 3: Recent changes
  queries["what changed recently"] = generateChangesQuery(index);

  // Query 4: Feature workflow
  queries["how do I add a new feature"] = generateWorkflowQuery("feature");

  index.queries = queries;
  writeIndex(index);
}

function generateComponentQuery(index, keyword) {
  const components = index.components.filter(c => c.id.includes(keyword));
  if (components.length === 0) return null;

  const comp = components[0];
  return {
    answer: `${comp.summary} Location: ${comp.path}. Trace: ${comp.specs.join(', ')}.`,
    sources: [comp.id],
    last_updated: new Date().toISOString()
  };
}
```

**Dependencies:**
- index.yaml v2.0 (components, specs, docs with summaries)

**Data Flow:**
```
Cron/Manual Trigger → update-index-queries.js → index.yaml (read) → Generate queries → index.yaml (update queries{}) → Complete
```

**Implementation Notes:**
- Queries hardcoded initially (manual expansion)
- Future: Learn from user queries (transcript analysis)
- Update frequency: Daily or on major changes
- Target: 10-20 common queries (covers 80% of questions)

---

#### Tool 5: update-index-changes.js

**Purpose:** Track last 20 changes in FIFO queue

**Location:** `spec-drive/scripts/tools/update-index-changes.js`

**Type:** Node.js Script

**Responsibilities:**
- Parse git log for recent changes
- Extract change summaries (commit messages)
- Add to index.yaml changes[] array (FIFO, max 20)
- Include: timestamp, files changed, diff stats, spec ID

**Interface:**
```javascript
// CLI usage (auto-triggered by PostToolUse hook)
node update-index-changes.js

// No parameters, reads git log
```

**Algorithm:**
```javascript
function updateChanges() {
  const index = readIndex();
  const gitLog = execSync('git log --oneline --stat -20').toString();
  const commits = parseGitLog(gitLog);

  index.changes = commits.map(commit => ({
    timestamp: commit.date,
    commit_hash: commit.hash,
    message: commit.message,
    files_changed: commit.files,
    insertions: commit.insertions,
    deletions: commit.deletions,
    spec_id: extractSpecId(commit.message) // From commit message pattern
  })).slice(0, 20); // FIFO: Keep last 20 only

  writeIndex(index);
}

function extractSpecId(message) {
  // Pattern: "feat(AUTH-001): Add login endpoint"
  const match = message.match(/\(([A-Z]+-\d+)\)/);
  return match ? match[1] : null;
}
```

**Dependencies:**
- Git (git log command)
- index.yaml v2.0 (changes[] array)

**Data Flow:**
```
PostToolUse Hook (file save) → update-index-changes.js → git log → Parse commits → index.yaml (changes[]) → Complete
```

**Implementation Notes:**
- FIFO queue (oldest changes drop off after 20)
- Git log parsed (commit hash, message, stats)
- Spec ID extraction (from conventional commit messages)
- Update frequency: On every file save (via PostToolUse hook)

---

### 3.5 Error Recovery Tools

#### Tool 6: retry-gate.sh

**Purpose:** Auto-retry failed quality gates with exponential backoff

**Location:** `spec-drive/scripts/tools/retry-gate.sh`

**Type:** Bash Script

**Responsibilities:**
- Detect recoverable gate failures (linting, formatting)
- Retry gate check (max 3 attempts)
- Exponential backoff delays (1s, 5s, 15s)
- Track retry history in state.yaml
- Escalate to user after 3 failures

**Interface:**
```bash
# Usage (called by quality gates)
./retry-gate.sh <GATE-SCRIPT> <SPEC-ID> <STAGE>

# Example:
./retry-gate.sh ./scripts/gates/gate-3-implement.sh AUTH-001 implement

# Exit codes:
# 0 = Gate passed (after retry or first attempt)
# 1 = Gate failed after 3 retries (escalate)
```

**Algorithm:**
```bash
function retry_gate() {
  local gate_script=$1
  local spec_id=$2
  local stage=$3
  local max_retries=3
  local delays=(1 5 15)  # Exponential backoff (seconds)

  for attempt in $(seq 1 $max_retries); do
    echo "Attempt $attempt/$max_retries..."

    if $gate_script; then
      echo "Gate passed on attempt $attempt"
      log_retry_success $spec_id $stage $attempt
      return 0
    fi

    if [ $attempt -lt $max_retries ]; then
      local delay=${delays[$((attempt-1))]}
      echo "Gate failed, retrying in ${delay}s..."
      sleep $delay

      # Apply simple fixes (linting, formatting)
      apply_auto_fixes $gate_script
    fi

    log_retry_attempt $spec_id $stage $attempt
  done

  echo "Gate failed after $max_retries retries, escalating to user"
  log_retry_failure $spec_id $stage
  return 1
}

function apply_auto_fixes() {
  # Only for recoverable errors
  if [[ $gate_script == *"gate-3-implement"* ]]; then
    npm run lint:fix 2>/dev/null || true
    npm run format 2>/dev/null || true
  fi
}
```

**Dependencies:**
- Quality gates (gate-*.sh scripts)
- state.yaml v2.0 (retry_history[])
- Stack-specific lint/format commands

**Data Flow:**
```
Gate Failure → retry-gate.sh → Apply Auto-Fixes → Retry Gate → Pass (return 0) OR Fail 3x (return 1, escalate)
```

**Implementation Notes:**
- Only retry recoverable errors (linting, formatting, NOT logic errors)
- Exponential backoff prevents rapid loops (total: ~21s worst case)
- Retry history logged (for analysis)
- User escalation clear (shows all 3 attempts + errors)

---

#### Tool 7: create-snapshot.sh

**Purpose:** Create state snapshot at stage boundaries

**Location:** `spec-drive/scripts/tools/create-snapshot.sh`

**Type:** Bash Script

**Responsibilities:**
- Capture current workflow stage
- Record files modified since last snapshot
- Store git commit hash (for rollback)
- Save snapshot in state.yaml (nested structure)
- Limit to 5 snapshots per workflow (FIFO)

**Interface:**
```bash
# Usage (called by orchestrators at stage boundaries)
./create-snapshot.sh <SPEC-ID> <STAGE>

# Example:
./create-snapshot.sh AUTH-001 implement

# Creates snapshot in state.yaml:
workflows:
  AUTH-001:
    snapshots:
      - stage: "implement"
        timestamp: "2025-11-01T14:30:00Z"
        files_modified: ["src/auth/login.ts", "tests/auth/login.test.ts"]
        git_commit: "a3f5c7e"
```

**Algorithm:**
```bash
function create_snapshot() {
  local spec_id=$1
  local stage=$2

  # Get files modified since last snapshot
  local last_snapshot_time=$(get_last_snapshot_time $spec_id)
  local files_modified=$(git diff --name-only $last_snapshot_time HEAD)
  local git_commit=$(git rev-parse HEAD)

  # Create snapshot object
  local snapshot=$(cat <<EOF
{
  "stage": "$stage",
  "timestamp": "$(date -Iseconds)",
  "files_modified": [$(echo "$files_modified" | jq -R -s -c 'split("\n") | map(select(length > 0))')],
  "git_commit": "$git_commit"
}
EOF
)

  # Add to state.yaml (FIFO, max 5)
  add_snapshot_to_state $spec_id "$snapshot"
}

function add_snapshot_to_state() {
  local spec_id=$1
  local snapshot=$2

  # Read state, add snapshot, limit to 5 (FIFO)
  yq eval ".workflows[\"$spec_id\"].snapshots += [$snapshot] | .workflows[\"$spec_id\"].snapshots = .workflows[\"$spec_id\"].snapshots[-5:]" -i .spec-drive/state.yaml
}
```

**Dependencies:**
- Git (git diff, git rev-parse)
- state.yaml v2.0 (snapshots[] array)
- yq (YAML processing)

**Data Flow:**
```
Stage Boundary → create-snapshot.sh → git diff (files modified) → state.yaml (add snapshot) → Complete
```

**Implementation Notes:**
- Snapshots lightweight (metadata only, no file copies)
- FIFO limit (5 snapshots max per workflow, oldest dropped)
- Stored in state.yaml (no separate files)
- Timestamps for rollback selection

---

#### Tool 8: rollback-workflow.sh

**Purpose:** Rollback workflow to previous stage from snapshot

**Location:** `spec-drive/scripts/tools/rollback-workflow.sh`

**Type:** Bash Script

**Responsibilities:**
- Load snapshot for target stage
- Revert git changes (git reset to snapshot commit)
- Update state.yaml (restore stage, clear snapshots after target)
- Warn user of uncommitted changes lost

**Interface:**
```bash
# Usage
./rollback-workflow.sh <SPEC-ID> <TARGET-STAGE>

# Example:
./rollback-workflow.sh AUTH-001 specify

# Reverts to "specify" stage, discards "implement" and "verify" work
```

**Algorithm:**
```bash
function rollback_workflow() {
  local spec_id=$1
  local target_stage=$2

  # Find snapshot for target stage
  local snapshot=$(get_snapshot_for_stage $spec_id $target_stage)
  if [ -z "$snapshot" ]; then
    echo "ERROR: No snapshot found for stage $target_stage"
    return 1
  fi

  local git_commit=$(echo "$snapshot" | jq -r '.git_commit')
  local files_modified=$(echo "$snapshot" | jq -r '.files_modified[]')

  # Warn user about data loss
  echo "WARNING: Rollback will discard uncommitted changes to:"
  echo "$files_modified"
  read -p "Continue? (y/N) " confirm
  if [ "$confirm" != "y" ]; then
    echo "Rollback cancelled"
    return 1
  fi

  # Revert git changes
  git reset --hard $git_commit

  # Update state.yaml
  update_state_after_rollback $spec_id $target_stage

  echo "Rolled back to stage: $target_stage (commit: $git_commit)"
}

function update_state_after_rollback() {
  local spec_id=$1
  local target_stage=$2

  # Update current stage
  yq eval ".workflows[\"$spec_id\"].stage = \"$target_stage\"" -i .spec-drive/state.yaml

  # Clear snapshots after target (future stages)
  yq eval ".workflows[\"$spec_id\"].snapshots = .workflows[\"$spec_id\"].snapshots | map(select(.stage == \"$target_stage\" or .stage == \"discover\" or .stage == \"specify\"))" -i .spec-drive/state.yaml
}
```

**Dependencies:**
- Git (git reset --hard)
- state.yaml v2.0 (snapshots[] array)
- yq (YAML processing)

**Data Flow:**
```
/spec-drive:rollback → rollback-workflow.sh → Load snapshot → git reset → state.yaml (update stage) → Complete
```

**Implementation Notes:**
- DESTRUCTIVE operation (warns user, requires confirmation)
- Only rolls back to previous snapshots (cannot roll forward)
- Uncommitted changes lost (user must commit or stash first)
- Snapshots after target cleared (prevents confusion)

---

### 3.6 Stack Profiles

#### Profile Structure

**Location:** `spec-drive/stack-profiles/<stack>.yaml`

**Format:** YAML configuration

**Purpose:** Define stack-specific behaviors (quality gates, patterns, conventions, enforcement)

**Schema:**
```yaml
# stack-profiles/python-fastapi.yaml example
stack_id: "python-fastapi"
display_name: "Python + FastAPI"

detection:
  required_files:
    - "requirements.txt"
    - "main.py"
  optional_files:
    - "Pipfile"
    - "pyproject.toml"
  content_patterns:
    - "from fastapi import FastAPI"
    - "app = FastAPI()"

behaviors:
  quality_gates:
    test: "pytest"
    lint: "pylint src/"
    format: "black src/"
    type_check: "mypy src/"

  patterns:
    async_functions: "Use async def for all endpoints"
    error_handling: "Raise HTTPException for API errors"
    models: "Use Pydantic BaseModel for request/response schemas"

  conventions:
    file_naming: "snake_case for files and functions"
    class_naming: "PascalCase for classes"
    test_naming: "test_<function_name> pattern"

  enforcement:
    - "No print() statements (use logger)"
    - "All endpoints must have type hints"
    - "All endpoints must have docstrings"

examples:
  endpoint: |
    @app.get("/users/{user_id}")
    async def get_user(user_id: int) -> User:
        """Retrieve user by ID."""
        user = await db.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user

  test: |
    @pytest.mark.asyncio
    async def test_get_user():
        response = await client.get("/users/1")
        assert response.status_code == 200
        assert response.json()["id"] == 1
```

**Profiles to Create:**
1. `python-fastapi.yaml` (NEW)
2. `go.yaml` (NEW)
3. `rust.yaml` (NEW)
4. `typescript-react.yaml` (enhanced from v0.1 generic)

**Implementation Notes:**
- Variables injected into agent prompts: `{STACK_QUALITY_GATES}`, `{STACK_PATTERNS}`, `{STACK_CONVENTIONS}`
- Detection heuristics (multiple indicators, fallback to generic)
- Stack-specific gate scripts (use profile variables)

---

## 4. DATA STRUCTURES

### 4.1 state.yaml v2.0 (Multi-Workflow Enhanced)

**Purpose:** Track multi-workflow state with priority, locks, snapshots, retry history

**Location:** `.spec-drive/state.yaml` (gitignored)

**Schema:**
```yaml
# Current active workflow (for backward compatibility)
current_workflow: feature | bugfix | research
current_spec: SPEC-ID
current_stage: discover | specify | implement | verify
can_advance: boolean
dirty: boolean

# Multi-workflow support (NEW in v0.2)
workflows:
  AUTH-001:
    workflow: feature
    status: in_progress | completed | abandoned
    stage: implement
    priority: 3                    # 0-9 scale (0=highest)
    started: "2025-11-01T09:00:00Z"
    last_activity: "2025-11-01T14:30:00Z"
    files_locked:                  # File locking for conflict detection
      - "src/auth/login.ts"
      - "tests/auth/login.test.ts"
    snapshots:                     # Stage snapshots for rollback (max 5)
      - stage: "specify"
        timestamp: "2025-11-01T10:00:00Z"
        files_modified: []
        git_commit: "abc123"
      - stage: "implement"
        timestamp: "2025-11-01T14:00:00Z"
        files_modified: ["src/auth/login.ts"]
        git_commit: "def456"
    retry_history:                 # Auto-retry tracking
      - gate: "gate-3-implement"
        attempts: 2
        success: true
        timestamp: "2025-11-01T13:45:00Z"
    interrupted: false             # Set true if session ends mid-workflow

  BUG-042:
    workflow: bugfix
    status: in_progress
    stage: fix
    priority: 0                    # Bugfixes always priority 0 (highest)
    started: "2025-11-01T11:00:00Z"
    files_locked:
      - "src/auth/token.ts"
    snapshots: []
    retry_history: []
    interrupted: false

# Workflow history (completed/abandoned workflows)
history:
  - spec_id: USER-001
    workflow: feature
    status: completed
    completed: "2025-10-31T18:00:00Z"
    duration: "8 hours"
```

**Validation Rules:**
- priority: Must be 0-9
- status: Must be in_progress, completed, or abandoned
- snapshots: Max 5 per workflow (FIFO)
- files_locked: Must be valid file paths (exist in repo)

**Implementation Notes:**
- Atomic updates (file locking during read-modify-write)
- Validation on load (schema check, detect corruption)
- Backward compatible (current_* fields preserved for v0.1 workflows)

---

### 4.2 index.yaml v2.0 (AI Summaries + Queries + Changes)

**Purpose:** AI-optimized index with summaries, pre-answered queries, changes feed

**Location:** `.spec-drive/index.yaml` (gitignored, regenerable)

**Schema:**
```yaml
meta:
  generated: "2025-11-01T15:00:00Z"
  version: "2.0"
  project_name: "my-app"

components:
  - id: comp-auth-login
    type: function
    path: src/auth/login.ts:15
    summary: "Authenticates user with credentials, returns JWT token, handles errors with HTTPException"  # NEW in v0.2
    dependencies: [comp-auth-validate-token, comp-db-users]

specs:
  - id: AUTH-001
    title: "User Login"
    status: done
    summary: "Allows users to log in with email/password, returns access token, handles invalid credentials"  # NEW in v0.2
    trace:
      code: [src/auth/login.ts:15, src/auth/session.ts:22]
      tests: [tests/auth/login.test.ts:8]
      docs: [docs/60-features/AUTH-001.md]

docs:
  - path: docs/10-architecture/ARCHITECTURE.md
    type: architecture
    summary: "Describes 3-tier architecture (presentation, business logic, data), explains separation of concerns, lists main components"  # NEW in v0.2
    last_updated: "2025-11-01T10:00:00Z"

code:
  - path: src/auth/login.ts
    components: [comp-auth-login]
    specs: [AUTH-001]
    summary: "Implements user authentication via email/password, JWT generation, error handling"  # NEW in v0.2

# NEW in v0.2: Pre-answered queries (FAQs)
queries:
  "how does authentication work":
    answer: "Authentication handled by comp-auth-login (src/auth/login.ts:15). Uses JWT tokens, validates via validateToken(). Trace: AUTH-001."
    sources: [comp-auth-login, AUTH-001]
    last_updated: "2025-11-01T15:00:00Z"

  "what are the main components":
    answer: "14 components: comp-auth-login, comp-user-service, comp-api-router, ... See COMPONENT-CATALOG.md for full list."
    sources: [index.yaml/components]
    last_updated: "2025-11-01T15:00:00Z"

# NEW in v0.2: Changes feed (last 20 updates, FIFO)
changes:
  - timestamp: "2025-11-01T14:30:00Z"
    commit_hash: "a3f5c7e"
    message: "feat(AUTH-001): Add login endpoint"
    files_changed: ["src/auth/login.ts", "tests/auth/login.test.ts"]
    insertions: 45
    deletions: 2
    spec_id: AUTH-001

  - timestamp: "2025-11-01T13:00:00Z"
    commit_hash: "b2e4d6f"
    message: "fix(BUG-042): Handle expired token edge case"
    files_changed: ["src/auth/token.ts"]
    insertions: 8
    deletions: 3
    spec_id: BUG-042
```

**Validation Rules:**
- summary: 1-2 sentences, max 200 chars
- queries: Max 20 entries (prevent bloat)
- changes: Max 20 entries (FIFO queue)

**Implementation Notes:**
- Summaries regenerate on file change (dirty flag)
- Queries update daily or on demand
- Changes update on every git commit (via PostToolUse hook)

---

### 4.3 BUG-XXX.yaml (Bugfix Spec Template)

**Purpose:** Document bug symptoms, investigation, fix approach, trace

**Location:** `.spec-drive/specs/BUG-XXX.yaml`

**Template Location:** `spec-drive/templates/BUG-TEMPLATE.yaml`

**Schema:**
```yaml
id: BUG-042
title: "Auth fails with expired token"
type: bug
status: draft | specified | implemented | verified | done
priority: critical | high | medium | low

symptom:
  description: "Users see 500 error when token expires instead of 401 Unauthorized"
  reproduction:
    - "Log in to get valid token"
    - "Wait for token to expire (10 minutes)"
    - "Make authenticated request"
    - "Observe: 500 error instead of 401"

  observed_behavior: "500 Internal Server Error"
  expected_behavior: "401 Unauthorized with clear error message"

  affected_users: "All users with expired tokens"
  frequency: "Common (happens every 10 minutes per user)"

investigation:
  root_cause: "Token validation throws uncaught exception on expired token"
  affected_components:
    - src/auth/validate-token.ts:25
    - src/middleware/auth-middleware.ts:15

  analysis: |
    validate-token.ts raises exception when token expired, but auth-middleware.ts
    doesn't catch it. Exception bubbles to Express error handler → 500.

    Fix: Catch TokenExpiredException in middleware, return 401 with message.

fix_approach:
  summary: "Add try-catch in auth-middleware, return 401 for expired tokens"
  changes:
    - file: src/middleware/auth-middleware.ts
      action: "Add try-catch around validateToken(), handle TokenExpiredException"
    - file: tests/middleware/auth-middleware.test.ts
      action: "Add regression test for expired token scenario"

  acceptance_criteria:
    - "Given expired token, When authenticated request, Then 401 Unauthorized returned"
    - "Given expired token, When authenticated request, Then error message clear ('Token expired')"
    - "Given valid token, When authenticated request, Then request succeeds (no regression)"

regression_prevention:
  - "Add test: test_expired_token_returns_401()"
  - "Add test: test_expired_token_clear_message()"
  - "Document token expiration handling in ARCHITECTURE.md"

trace:
  code: [src/middleware/auth-middleware.ts:15]
  tests: [tests/middleware/auth-middleware.test.ts:42]
  docs: [docs/10-architecture/ARCHITECTURE.md:150]

metadata:
  created: "2025-11-01T11:00:00Z"
  updated: "2025-11-01T14:00:00Z"
  resolved: null  # Set when status: done
```

**Validation Rules:**
- symptom.reproduction: Must have 3+ steps (clear reproduction)
- fix_approach.acceptance_criteria: Must have 2+ ACs
- regression_prevention: Must have ≥1 test

**Implementation Notes:**
- Lighter than SPEC-XXX.yaml (faster bugfix cycle)
- Emphasis on root cause + regression prevention
- Mandatory regression test (prevent re-introduction)

---

## 5. WORKFLOWS

### 5.1 Feature Workflow (Enhanced with Agents)

**Trigger:** `/spec-drive:feature SPEC-ID "description"`

**Stages:** discover → specify → implement → verify

**Enhancements in v0.2:**
- **Specify stage:** Delegates to spec-agent (automates spec creation)
- **Implement stage:** Delegates to test-agent + impl-agent (TDD automation)
- **All stages:** Stack-aware (uses profile variables)

**State Diagram:**
```
[discover]
    ↓ (Manual: User explores context)
[Gate 1: Specify]
    ↓ (PASS: User confirms understanding)
[specify]
    ↓ (spec-agent: Creates SPEC-XXX.yaml)
    ↓ (validate-spec.js: Validates no [NEEDS CLARIFICATION])
[Gate 2: Architect]
    ↓ (PASS: API contracts defined, test scenarios written)
[implement]
    ↓ (test-agent: Writes failing tests)
    ↓ (impl-agent: Implements to make tests pass)
    ↓ (Gate 3: Tests + lint + type-check)
[Gate 3: Implement]
    ↓ (PASS: All tests pass, @spec tags present, no linting errors)
    ↓ (Auto-retry on failure: max 3 attempts)
[verify]
    ↓ (User: Validates ACs met)
    ↓ (Autodocs: Updates index, docs)
[Gate 4: Verify]
    ↓ (PASS: All ACs met, docs updated, traceability complete)
[done]
```

**Agent Delegation Points:**
- **Specify stage:** spec-agent creates SPEC-XXX.yaml
- **Implement stage:** test-agent writes tests → impl-agent implements

**Recovery Points:**
- **Gate 3 failure:** Auto-retry (retry-gate.sh, max 3 attempts)
- **Critical failure:** Rollback to previous stage (rollback-workflow.sh)
- **Session interruption:** Resume on next session (SessionStart hook)

---

### 5.2 Bugfix Workflow (NEW)

**Trigger:** `/spec-drive:bugfix BUG-ID "symptom"`

**Stages:** investigate → specify-fix → fix → verify

**State Diagram:**
```
[investigate]
    ↓ (Manual: User reproduces bug, identifies root cause)
[Gate 1-Bugfix: Specify Fix]
    ↓ (PASS: Root cause documented, fix approach clear)
[specify-fix]
    ↓ (Manual or spec-agent: Creates BUG-XXX.yaml)
[Gate 2-Bugfix: Implement Fix]
    ↓ (PASS: Fix spec validated)
[fix]
    ↓ (impl-agent: Implements fix)
    ↓ (test-agent: Writes regression test)
[Gate 3-Bugfix: Verify Fix]
    ↓ (PASS: Regression test passes, fix verified)
[verify]
    ↓ (User: Confirms bug resolved, no side effects)
[done]
```

**Differences from Feature Workflow:**
- Lighter gates (faster cycle)
- Mandatory regression test (prevents re-introduction)
- Priority always 0 (highest, encourages quick fixes)
- Can run concurrently with feature workflows

---

### 5.3 Research Workflow (NEW)

**Trigger:** `/spec-drive:research "topic" "timebox"`

**Stages:** explore → synthesize → decide

**State Diagram:**
```
[explore]
    ↓ (Manual: Research topic, collect 2-4 options)
    ↓ (Timebox enforced: Warn at 80%, stop at 100%)
[synthesize]
    ↓ (Manual: Document trade-offs, rank options)
    ↓ (Recommend best option with rationale)
[decide]
    ↓ (User: Approves decision)
    ↓ (Create ADR-XXXX.md)
[done]
```

**No Quality Gates:**
- Research is exploratory (no pass/fail criteria)
- Timebox enforcement prevents rabbit holes
- ADR required output (documents decision)

---

## 6. INTEGRATION POINTS

### 6.1 Agents ↔ Orchestrator

**Direction:** Bidirectional (orchestrator delegates, agent returns deliverable)

**Method:** Task tool with subagent_type="general-purpose"

**Data Passed:**
- **To Agent:** Spec file, stack profile variables, requirements
- **From Agent:** Deliverable (SPEC-XXX.yaml, code files, test files)

**Example:**
```bash
# In feature.sh orchestrator
if [ "$stage" == "specify" ]; then
  # Delegate to spec-agent
  claude code task \
    --subagent-type="general-purpose" \
    --prompt="$(cat spec-drive/agents/spec-agent.md | envsubst)" \
    --output=".spec-drive/specs/$SPEC_ID.yaml"
fi
```

**Stack Profile Injection:**
```bash
# Load stack profile
STACK_PROFILE=$(cat spec-drive/stack-profiles/$DETECTED_STACK.yaml)

# Extract variables
STACK_QUALITY_GATES=$(yq eval '.behaviors.quality_gates' <<< "$STACK_PROFILE")
STACK_PATTERNS=$(yq eval '.behaviors.patterns' <<< "$STACK_PROFILE")

# Inject into agent prompt via envsubst
export STACK_QUALITY_GATES STACK_PATTERNS
agent_prompt=$(cat spec-drive/agents/impl-agent.md | envsubst)
```

---

### 6.2 Stack Profiles ↔ Quality Gates

**Direction:** Profile → Gates (one-way)

**Method:** Variable substitution in gate scripts

**Data Passed:** {STACK_QUALITY_GATES} commands

**Example:**
```bash
# gate-3-implement.sh (enhanced for stack awareness)
STACK_PROFILE=$(cat spec-drive/stack-profiles/$DETECTED_STACK.yaml)
TEST_COMMAND=$(yq eval '.behaviors.quality_gates.test' <<< "$STACK_PROFILE")
LINT_COMMAND=$(yq eval '.behaviors.quality_gates.lint' <<< "$STACK_PROFILE")

# Run stack-specific commands
if ! $TEST_COMMAND; then
  echo "Tests failed"
  exit 1
fi

if ! $LINT_COMMAND; then
  echo "Linting failed"
  exit 1
fi
```

---

### 6.3 PostToolUse Hook ↔ Index Updates

**Direction:** Hook → Index scripts (one-way trigger)

**Method:** Script execution on file write events

**Data Passed:** Changed files list

**Flow:**
```
File Write Event → PostToolUse Hook → Set dirty flag →
Stage Boundary → generate-summaries.js → update-index-changes.js → index.yaml updated
```

**Implementation:**
```bash
# hooks/handlers/post-tool-use.sh (enhanced)
tool_name=$1
if [ "$tool_name" == "Edit" ] || [ "$tool_name" == "Write" ]; then
  # Set dirty flag
  yq eval '.dirty = true' -i .spec-drive/state.yaml

  # If at stage boundary (can_advance: true), trigger index updates
  if [ "$(yq eval '.can_advance' .spec-drive/state.yaml)" == "true" ]; then
    node scripts/tools/generate-summaries.js --type=code
    node scripts/tools/update-index-changes.js
  fi
fi
```

---

### 6.4 Multi-Workflow Queue ↔ File Locks

**Direction:** Bidirectional (queue reads locks, workflows update locks)

**Method:** State file read/write

**Data Passed:** files_locked[] arrays

**Flow:**
```
Workflow Start → Lock files (add to files_locked[]) → Workflow Switch Request →
detect-conflicts.js → Compare locks → Conflict? → Warn user OR Allow switch
```

**Conflict Detection Algorithm:**
```javascript
// detect-conflicts.js
function detectConflicts(currentSpecId, targetSpecId) {
  const state = readState();
  const currentLocks = state.workflows[currentSpecId].files_locked || [];
  const targetLocks = state.workflows[targetSpecId].files_locked || [];

  const conflicts = currentLocks.filter(file => targetLocks.includes(file));

  return {
    conflict: conflicts.length > 0,
    conflicting_files: conflicts
  };
}
```

---

## 7. ALGORITHMS & LOGIC

### 7.1 Stack Detection Algorithm

**Input:** Project root directory

**Output:** Stack profile ID (e.g., "python-fastapi", "typescript-react", "go", "rust", "generic")

**Pseudocode:**
```python
def detect_stack(project_root):
    # Check for required files (strong indicators)
    for profile in ALL_PROFILES:
        required_files = profile['detection']['required_files']
        if all(file_exists(project_root, file) for file in required_files):
            # Validate with content patterns (confirm detection)
            if check_content_patterns(project_root, profile['detection']['content_patterns']):
                return profile['stack_id']

    # Fallback to generic profile
    return "generic"

def check_content_patterns(project_root, patterns):
    # Read key files, search for patterns
    for pattern in patterns:
        if not grep_recursive(project_root, pattern):
            return False  # Pattern not found, detection uncertain
    return True
```

**Complexity:** O(n) where n = files scanned (limited to required + optional files, ~10 max)

**Enhancements in v0.2:**
- Multiple indicators (files + content patterns)
- Confidence scoring (future: warn if <80%)
- Monorepo support (detect multiple stacks)

---

### 7.2 Conflict Detection Algorithm

**Input:** current_spec_id, target_spec_id

**Output:** { conflict: bool, conflicting_files: string[] }

**Pseudocode:**
```javascript
function detectConflicts(currentSpecId, targetSpecId) {
  const state = readState();

  const currentLocks = state.workflows[currentSpecId].files_locked || [];
  const targetLocks = state.workflows[targetSpecId].files_locked || [];

  const conflicts = [];
  for (const file of currentLocks) {
    if (targetLocks.includes(file)) {
      conflicts.push(file);
    }
  }

  return {
    conflict: conflicts.length > 0,
    conflicting_files: conflicts,
    current_workflow: currentSpecId,
    target_workflow: targetSpecId
  };
}
```

**Complexity:** O(n*m) where n=current locks, m=target locks
- Acceptable for small lock arrays (typically <20 files per workflow)

---

### 7.3 Auto-Retry Logic with Exponential Backoff

**Input:** gate_script, spec_id, stage

**Output:** Pass (exit 0) or Fail after 3 retries (exit 1)

**Pseudocode:**
```bash
function retry_gate() {
  max_retries=3
  delays=(1 5 15)  # Exponential backoff (seconds)

  for attempt in 1..max_retries:
    run gate_script
    if success:
      log_success(spec_id, stage, attempt)
      return 0

    if attempt < max_retries:
      delay = delays[attempt - 1]
      sleep delay
      apply_auto_fixes()  # Linting, formatting

    log_attempt(spec_id, stage, attempt)

  # All retries failed
  log_failure(spec_id, stage)
  escalate_to_user()
  return 1
}
```

**Backoff Strategy:**
- Attempt 1: Immediate
- Attempt 2: Wait 1s
- Attempt 3: Wait 5s
- Attempt 4: Wait 15s (if max_retries=4)

**Total worst-case time:** ~21s (1s + 5s + 15s delays)

---

### 7.4 Rollback Algorithm

**Input:** spec_id, target_stage

**Output:** Workflow state reverted to target_stage

**Pseudocode:**
```bash
function rollback_workflow(spec_id, target_stage) {
  # Load snapshot for target stage
  snapshot = get_snapshot_for_stage(spec_id, target_stage)
  if not snapshot:
    error "No snapshot found for stage $target_stage"
    return 1

  git_commit = snapshot['git_commit']
  files_modified = snapshot['files_modified']

  # Warn user about data loss
  confirm "Rollback will discard changes to: $files_modified. Continue? (y/N)"
  if not confirmed:
    return 1

  # Revert git changes
  git reset --hard $git_commit

  # Update state.yaml
  update_state_stage(spec_id, target_stage)
  clear_future_snapshots(spec_id, target_stage)

  log "Rolled back to stage: $target_stage (commit: $git_commit)"
  return 0
}
```

**Safety Checks:**
- Snapshot exists (error if not)
- User confirmation (prevent accidental rollback)
- Git commit valid (error if corrupted)

---

### 7.5 AI Summary Generation

**Input:** file_path, file_content

**Output:** summary (1-2 sentences, max 200 chars)

**Pseudocode:**
```javascript
async function generateSummary(filePath, content) {
  const prompt = `Summarize this code/component in 1-2 sentences (max 200 chars):

  ${content}

  Focus on: What it does, key responsibilities, NOT implementation details.`;

  try {
    const summary = await callClaude(prompt, { timeout: 10000, model: 'haiku' });

    // Validate length
    if (summary.length > 200) {
      return summary.substring(0, 197) + '...';
    }

    return summary;
  } catch (error) {
    if (error.timeout) {
      console.warn(`Timeout for ${filePath}, skipping`);
      return null;  // Skip, regenerable later
    }
    throw error;
  }
}

async function callClaude(prompt, options) {
  // Use Task tool with general-purpose subagent
  return await Task({
    subagent_type: "general-purpose",
    model: options.model || "sonnet",
    prompt: prompt,
    timeout: options.timeout
  });
}
```

**Model Selection:**
- Haiku: Fast, cost-effective (recommended for summaries)
- Sonnet: Higher quality (use if Haiku summaries poor)

**Timeout Handling:**
- 10s timeout (configurable)
- Skip on timeout (don't block index updates)
- Regenerable later (summaries not critical)

---

### 7.6 Priority Sorting Algorithm

**Input:** workflows{} object

**Output:** Sorted array of workflow IDs (priority 0 → 9)

**Pseudocode:**
```javascript
function sortWorkflowsByPriority(workflows) {
  const workflowArray = Object.entries(workflows).map(([id, workflow]) => ({
    id,
    priority: workflow.priority,
    status: workflow.status
  }));

  // Filter active workflows only
  const active = workflowArray.filter(w => w.status === 'in_progress');

  // Sort by priority (0 = highest)
  active.sort((a, b) => a.priority - b.priority);

  return active.map(w => w.id);
}
```

**Priority Scale:**
- 0: Bugfixes (critical, always highest)
- 1-5: Features (by urgency)
- 6-9: Research, low-priority tasks

**Usage:**
- /spec-drive:status command (show workflows in priority order)
- Multi-workflow queue management

---

## 8. ERROR HANDLING

### 8.1 Error Categories

**Recoverable Errors (Auto-Retry):**
- Linting failures (fixable via lint:fix)
- Formatting issues (fixable via formatter)
- Type errors (sometimes fixable via type inference)

**Non-Recoverable Errors (Escalate):**
- Logic errors (tests fail due to incorrect implementation)
- Missing dependencies (require manual installation)
- Git conflicts (require manual resolution)
- State corruption (require snapshot restore)

### 8.2 Error Recovery Flow

```
Gate Failure → Classify Error → Recoverable?
    ↓ YES                    ↓ NO
Auto-Retry (max 3)       Escalate to User
    ↓ SUCCESS  ↓ FAIL          ↓
  Continue   Escalate     Manual Fix → Retry Gate
```

### 8.3 State Corruption Handling

```
Load state.yaml → Schema Validation → Valid?
    ↓ YES              ↓ NO
Use state        Detect Corruption → Restore from Snapshot → Valid?
                                          ↓ YES     ↓ NO
                                        Use state  Manual Recovery (show error, offer reconstruction)
```

---

## 9. PERFORMANCE CONSIDERATIONS

### 9.1 Performance Targets

| Operation | Target | Maximum Acceptable | Measurement |
|-----------|--------|-------------------|-------------|
| AI Summary Generation | <10s | 30s | Time per summary |
| Context Switching | <1s | 3s | Time from /switch to ready |
| Index Update | <5s | 15s | Time from dirty flag to index updated |
| State File Update | <100ms | 500ms | Time for atomic write |
| Stack Detection | <2s | 5s | Time on project init |
| Conflict Detection | <100ms | 500ms | Time to compare locks |

### 9.2 Optimization Strategies

**AI Summary Generation:**
- Use Haiku model (faster, cheaper)
- Batch summarize (10 files at a time, reduce API overhead)
- Cache aggressively (only regenerate on file change)
- Timeout skip (don't block on slow summaries)

**State File Updates:**
- Atomic operations (file locking)
- Minimal reads (cache in memory during session)
- YAML streaming (for large state files)

**Index Updates:**
- Incremental (only update changed sections)
- Async (don't block user workflow)
- Dirty flag (avoid unnecessary updates)

---

## 10. SECURITY CONSIDERATIONS

### 10.1 Security Risks

**Sensitive Data in Summaries:**
- AI summaries might expose secrets (API keys, passwords in code comments)
- Mitigation: Validate summaries don't contain secret patterns (regex check)

**State File Exposure:**
- state.yaml contains workflow metadata (might reveal internal architecture)
- Mitigation: Gitignore state.yaml (already in v0.1)

**Arbitrary Code Execution:**
- Stack profile quality gates run user-defined commands
- Mitigation: Validate profile YAML schema, warn on untrusted profiles

### 10.2 Security Best Practices

- Never commit state.yaml or index.yaml (gitignored)
- Validate all YAML inputs (state, index, profiles, specs)
- Sanitize file paths (prevent directory traversal)
- Limit agent prompts to trusted sources (no user-injected prompts)

---

## 11. TESTING STRATEGY

### 11.1 Testing Levels

**Unit Tests:**
- All 21 new scripts/tools (workflow-queue.js, detect-conflicts.js, generate-summaries.js, etc.)
- Stack detection logic
- Conflict detection algorithm
- Retry logic
- Target: ≥90% code coverage

**Integration Tests:**
- Agent delegation (orchestrator → agent → deliverable)
- Multi-workflow state management (add, switch, prioritize, abandon)
- Auto-retry + rollback flows
- Stack profile integration with gates

**End-to-End Tests:**
- 6 test scenarios from TEST-PLAN (multi-workflow, stack profiles, agents, index, recovery)
- Full workflow completions (feature, bugfix, research)

### 11.2 Test Automation

**Fully Automated Test Suite (per user preference):**
- Bash scripts for workflow testing
- Jest/Mocha for JavaScript tools
- pytest for Python scripts (stack-detection.py)
- Automated regression suite (run on every commit)

---

## 12. DEPLOYMENT STRATEGY

### 12.1 Rollout Plan

**Phase 1 (Weeks 1-2):** Specialist Agents
- Deploy: spec-agent, impl-agent, test-agent
- Test: Agent delegation in feature workflow
- Rollback: Remove agent prompts, revert to manual (v0.1 behavior)

**Phase 2 (Week 3):** Additional Workflows
- Deploy: bugfix.sh, research.sh, BUG-TEMPLATE.yaml
- Test: Bugfix + research workflows end-to-end
- Rollback: Remove commands, revert to feature-only

**Phase 3 (Weeks 4-5):** Stack Profiles
- Deploy: 3 new profiles (Python/FastAPI, Go, Rust), enhanced TypeScript
- Test: Stack detection + profile-based gates
- Rollback: Fallback to generic profile (v0.1 behavior)

**Phase 4 (Weeks 6-7):** Index Optimizations
- Deploy: AI summaries, query patterns, changes feed
- Test: Context reduction measurement
- Rollback: Disable summaries, use v0.1 index

**Phase 5 (Weeks 8-9):** Multi-Workflow State
- Deploy: state.yaml v2.0, workflow queue, conflict detection
- Test: 3+ concurrent workflows
- Rollback: Limit to 1 workflow (v0.1 behavior)

**Phase 6 (Weeks 10-11):** Error Recovery
- Deploy: Auto-retry, rollback, resume
- Test: Error recovery scenarios
- Rollback: Manual retry only (v0.1 behavior)

**Integration Testing (Week 12):** All 6 test scenarios

### 12.2 Rollback Strategy

**Per-Phase Rollback:**
- Each phase independent (can rollback one without affecting others)
- Feature flags (enable/disable enhancements)
- State migration scripts (downgrade state.yaml v2.0 → v1.0 if needed)

**Emergency Rollback:**
- Restore v0.1 plugin entirely
- Preserve user data (specs, workflows in state.yaml exported)

---

## 13. MONITORING & OBSERVABILITY

### 13.1 Metrics to Track

**Workflow Metrics:**
- Workflow completion rate (% started → done)
- Average workflow duration (by type: feature, bugfix, research)
- Agent delegation success rate (% agent outputs accepted)
- Auto-retry success rate (% failures recovered)

**Performance Metrics:**
- AI summary generation time (avg, p95, p99)
- Context reduction achieved (% token usage reduction)
- Index update time (avg)
- State file update time (avg)

**Quality Metrics:**
- Gate failure rate (% workflows blocked at each gate)
- Conflict detection accuracy (false positive rate)
- Rollback frequency (indicator of workflow issues)

### 13.2 Logging

**Log Locations:**
- `.spec-drive/logs/workflows.log` - Workflow events
- `.spec-drive/logs/gates.log` - Gate pass/fail
- `.spec-drive/logs/retry.log` - Auto-retry events
- `.spec-drive/logs/summaries.log` - AI summary generation

**Log Format:**
```
[2025-11-01T14:30:00Z] [INFO] [feature.sh] Stage: implement, Spec: AUTH-001, Action: Delegate to impl-agent
[2025-11-01T14:35:00Z] [WARN] [gate-3-implement.sh] Gate failed: Linting errors detected
[2025-11-01T14:35:01Z] [INFO] [retry-gate.sh] Auto-retry attempt 1/3
[2025-11-01T14:35:06Z] [INFO] [retry-gate.sh] Auto-retry attempt 2/3
[2025-11-01T14:35:11Z] [SUCCESS] [retry-gate.sh] Gate passed on attempt 2
```

---

## 14. OPEN QUESTIONS & DECISIONS NEEDED

### 14.1 Open Questions (Require User Input or ADRs)

1. **Agent Prompt Format:** Should agent prompts be markdown files or embedded in orchestrator scripts?
   - **Recommendation:** Markdown files (easier to edit, version, audit)
   - **ADR:** ADR-001

2. **Stack Profile Variable Injection:** String replacement or template engine?
   - **Recommendation:** String replacement (envsubst, simpler)
   - **ADR:** ADR-002

3. **Conflict Detection Timing:** On switch or on file write?
   - **Recommendation:** On switch (matches user intent, less overhead)
   - **ADR:** ADR-003

4. **AI Summary LLM:** Claude Haiku or Sonnet?
   - **Recommendation:** Haiku (faster, cheaper, sufficient quality)
   - **ADR:** ADR-004

5. **State Snapshot Storage:** Nested in state.yaml or separate files?
   - **Recommendation:** Nested (simpler, atomic updates)
   - **ADR:** ADR-005

6. **Auto-Retry Backoff:** Fixed or exponential?
   - **Recommendation:** Exponential (1s, 5s, 15s - prevents rapid loops)
   - **ADR:** ADR-006

### 14.2 Decisions to Document

**All 6 decisions above require ADRs** (per user preference: create all 6 ADRs)

---

## 15. APPENDIX

### 15.1 Technology Stack

**Languages:**
- Bash (orchestrators, gates, hooks)
- JavaScript/Node.js (tools: workflow-queue, detect-conflicts, summaries, queries, changes)
- Python (stack-detection.py enhancement)
- YAML (state, index, profiles, specs)
- Markdown (agents, commands, docs, ADRs)

**Dependencies:**
- Claude Code CLI (subagent delegation via Task tool)
- Git (rollback, changes feed)
- yq (YAML processing in bash)
- jq (JSON processing in bash)
- Node.js ≥18 (JavaScript tools)
- Python ≥3.9 (stack detection)

**External APIs:**
- Claude API (via Task tool for AI summaries)

### 15.2 File Structure

```
spec-drive/
├── commands/
│   ├── bugfix.md                  # NEW: /spec-drive:bugfix
│   ├── research.md                # NEW: /spec-drive:research
│   ├── switch.md                  # NEW: /spec-drive:switch
│   ├── prioritize.md              # NEW: /spec-drive:prioritize
│   ├── abandon.md                 # NEW: /spec-drive:abandon
│   └── rollback.md                # NEW: /spec-drive:rollback
├── agents/
│   ├── spec-agent.md              # NEW: Spec creation agent
│   ├── impl-agent.md              # NEW: Implementation agent
│   └── test-agent.md              # NEW: Test creation agent
├── scripts/
│   ├── workflows/
│   │   ├── bugfix.sh              # NEW: Bugfix orchestrator
│   │   ├── research.sh            # NEW: Research orchestrator
│   │   └── feature.sh             # ENHANCED: Delegate to agents
│   ├── gates/
│   │   ├── gate-1-bugfix-specify.sh    # NEW: Bugfix gate 1
│   │   ├── gate-2-bugfix-implement.sh  # NEW: Bugfix gate 2
│   │   ├── gate-3-bugfix-verify.sh     # NEW: Bugfix gate 3
│   │   └── gate-*.sh              # ENHANCED: Stack-aware
│   ├── tools/
│   │   ├── workflow-queue.js      # NEW: Multi-workflow management
│   │   ├── detect-conflicts.js    # NEW: File lock conflicts
│   │   ├── generate-summaries.js  # NEW: AI summaries
│   │   ├── update-index-queries.js # NEW: Query patterns
│   │   ├── update-index-changes.js # NEW: Changes feed
│   │   ├── validate-spec.js       # NEW: Spec validation
│   │   ├── retry-gate.sh          # NEW: Auto-retry
│   │   ├── create-snapshot.sh     # NEW: Stage snapshots
│   │   └── rollback-workflow.sh   # NEW: Rollback
│   └── stack-detection.py         # ENHANCED: Detect 4 stacks
├── stack-profiles/
│   ├── python-fastapi.yaml        # NEW: Python/FastAPI profile
│   ├── go.yaml                    # NEW: Go profile
│   ├── rust.yaml                  # NEW: Rust profile
│   └── typescript-react.yaml      # ENHANCED: From v0.1 generic
├── templates/
│   ├── BUG-TEMPLATE.yaml          # NEW: Bugfix spec template
│   └── ...                        # v0.1 templates
├── hooks/
│   └── handlers/
│       ├── session-start.sh       # ENHANCED: Resume detection
│       └── post-tool-use.sh       # ENHANCED: Trigger summaries
└── assets/
    └── strict-concise-behavior.md # v0.1: Behavior agent

.spec-drive/
├── state.yaml                     # ENHANCED: v2.0 (multi-workflow)
├── index.yaml                     # ENHANCED: v2.0 (summaries, queries, changes)
├── specs/
│   ├── SPEC-XXX.yaml              # v0.1: Feature specs
│   └── BUG-XXX.yaml               # NEW: Bugfix specs
└── logs/                          # NEW: Workflow/gate/retry/summary logs
    ├── workflows.log
    ├── gates.log
    ├── retry.log
    └── summaries.log
```

---

**Document Status:** Draft
**Next Steps:** Create TEST-PLAN.md, IMPLEMENTATION-PLAN.md, STATUS.md, 6 ADRs, 33 task files

---

**Prepared By:** spec-drive Planning Team
**Reviewed By:** [Pending]
**Approved By:** [Pending]
**Date:** 2025-11-01
