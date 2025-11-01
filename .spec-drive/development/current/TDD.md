# SPEC-DRIVE TECHNICAL DESIGN DOCUMENT

**Version:** 1.0
**Date:** 2025-11-01
**Status:** Draft
**Related:** [PRD.md](./PRD.md) | [DECISIONS.md](./DECISIONS.md) | [STATUS.md](./STATUS.md)

---

## TABLE OF CONTENTS

1. [Introduction & Context](#1-introduction--context)
2. [Goals & Non-Goals](#2-goals--non-goals)
3. [Assumptions & Constraints](#3-assumptions--constraints)
4. [High-Level Architecture](#4-high-level-architecture)
5. [Three-System Overview](#5-three-system-overview)
6. [Component Breakdown](#6-component-breakdown) *(Section 2)*
7. [Data Flows](#7-data-flows) *(Section 2)*
8. [Integration Points](#8-integration-points) *(Section 3)*
9. [Implementation Details](#9-implementation-details) *(Section 3)*
10. [Quality Attributes](#10-quality-attributes) *(Section 3)*

---

## 1. INTRODUCTION & CONTEXT

### 1.1 Document Purpose

This Technical Design Document (TDD) specifies the architecture and technical implementation of **spec-drive v0.1**, a Claude Code plugin that integrates three interconnected systems:

1. **Behavior Optimization** - Enforce quality gates and best practices
2. **Self-Updating Documentation** - AI-indexed, auto-maintained docs
3. **Spec-Driven Development** - Workflows and traceability

This document translates the vision from [PRD.md](./PRD.md) into concrete technical architecture, component design, and implementation guidance.

### 1.2 Background

**Problem:** Claude Code development suffers from three interconnected issues:
- Inconsistent behavior (shortcuts, quality issues)
- Documentation drift (out-of-sync docs, inefficient context)
- No traceability (specs disconnected from code/tests/docs)

**Solution:** Unified plugin that solves all three problems simultaneously through integrated systems that reinforce each other.

### 1.3 Target Audience

- **Implementation Team:** Developers building spec-drive v0.1
- **Code Reviewers:** Validating implementation against design
- **Future Maintainers:** Understanding architecture decisions
- **AI Assistant (Claude Code):** Querying architecture context

### 1.4 Scope

**This TDD covers:**
- v0.1 architecture (foundation release)
- Two workflows: `app-new` and `feature`
- Generic behavior profile (no stack-specific rules)
- Linux and macOS support

**Out of Scope for v0.1:**
- Specialist agents (deferred to v0.2)
- Stack-specific profiles (deferred to v0.2)
- Bugfix/research workflows (deferred to v0.2)
- Windows support (optional for v0.1)
- MCP integration (Claude Code plugin environment only)

---

## 2. GOALS & NON-GOALS

### 2.1 Technical Goals

**Primary Goals (v0.1):**

1. **Integrated System Delivery**
   - All three systems (behavior, autodocs, spec-driven) work together
   - Each system reinforces the others
   - Single cohesive user experience

2. **Quality Gate Enforcement**
   - 100% of development follows enforced workflows
   - No stage advancement without passing gates
   - Stop-the-line on errors/shortcuts/incomplete work

3. **Documentation Automation**
   - Docs auto-update at workflow stage boundaries
   - AI-optimized index.yaml reduces context usage by ≥70%
   - Same documentation baseline for new AND existing projects

4. **Traceability System**
   - 100% spec → code → tests → docs linkage via @spec tags
   - Language-specific tag format (lint-compatible)
   - Automated trace verification in quality gates

5. **Dogfooding Architecture**
   - Plugin uses IDENTICAL structure to user projects
   - `.spec-drive/` folder organization proven in practice
   - Reference implementation for all best practices

**Performance Goals:**

- Hook overhead: <500ms per invocation
- Init time (existing project): <60 seconds for medium codebase (~10k LOC)
- Init time (new project): <30 seconds
- Index generation: <5 seconds for medium codebase
- Context reduction: ≥70% via index-first queries

**Quality Goals:**

- Zero shortcuts allowed (TODO/console.log/placeholders)
- All gates pass before stage advancement
- Docs updated within 1 stage of code changes
- 100% traceability coverage for specs

### 2.2 Non-Goals (Deferred)

**Deferred to v0.2:**

- Specialist agents (spec-agent, impl-agent, test-agent)
- Automatic code generation from specs
- Stack-specific behavior profiles (TypeScript/React, Python/FastAPI)
- Bugfix and research workflows
- Advanced context optimization (AI summaries, query patterns)
- Auto-injection of @spec tags (v0.1 requires manual tagging)
- Multi-feature parallel development (v0.1 supports one feature at a time)

**Out of Scope Permanently:**

- GUI/web interface (CLI-only plugin)
- Integration with non-Claude AI tools
- Real-time doc updates (stage-boundary only)
- Version control integration beyond git hooks
- Team collaboration features (v0.1 is single-developer focused)

---

## 3. ASSUMPTIONS & CONSTRAINTS

### 3.1 Environment Assumptions

**Claude Code Plugin Environment:**

- Plugin runs in Claude Code CLI (Linux/macOS)
- Access to file system, bash commands, git
- SessionStart and PostToolUse hooks available
- Slash commands via `commands/` folder
- No MCP (Model Context Protocol) in v0.1
- Node.js available for script execution
- Standard CLI tools: git, grep, find, tree

**Project Environment:**

- Git repository (existing or new)
- Node.js/npm available (for generic profile)
- Standard project structure (src/, tests/, docs/)
- User has write access to project directory
- .gitignore properly configured

### 3.2 Technical Constraints

**Claude Code Plugin Constraints:**

- Hook execution time budget (~500ms reasonable limit)
- No persistent processes (hooks are one-shot scripts)
- Limited to file operations, bash, and Claude API calls
- No network requests in v0.1 (all local operations)
- Text-based output only (no GUI)

**Implementation Constraints:**

- Must work without user configuration (sensible defaults)
- Cannot break existing project structure
- Must handle edge cases gracefully (no crashes)
- Clear error messages for all failure modes
- Rollback capability for destructive operations

**Performance Constraints:**

- Hook overhead must not slow development significantly
- Index generation must complete in reasonable time
- Code analysis must scale to medium codebases (~10k LOC)
- Memory footprint reasonable for CLI tool

### 3.3 Design Constraints

**From Architectural Decisions (See [DECISIONS.md](./DECISIONS.md)):**

1. **YAML for specs** (not JSON) - human-readable, comment support
2. **`.spec-drive/` hidden structure** - clean root, no pollution
3. **SessionStart auto-injection** - always-on enforcement
4. **Stage-boundary autodocs** - not continuous, reduces churn
5. **JSDoc-style @spec tags** - lint-compatible, language-agnostic pattern
6. **Four quality gates** - fixed stages (Discover → Specify → Implement → Verify)
7. **Aggressive existing init** - archive old docs, full regeneration
8. **Generic profile only (v0.1)** - no stack-specific behavior yet

### 3.4 User Constraints

**User Expectations:**

- Users expect minimal setup (<5 minutes to init)
- Users expect clear guidance at each workflow stage
- Users expect docs to "just work" without manual effort
- Users tolerate one-time migration cost (existing project init)
- Users accept workflow discipline (can't skip stages)

**User Capabilities:**

- Basic git knowledge
- Comfortable with CLI tools
- Understands project structure conventions
- Can write YAML (for spec editing)
- Can interpret error messages

---

## 4. HIGH-LEVEL ARCHITECTURE

### 4.1 System Context Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLAUDE CODE CLI                             │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    SPEC-DRIVE PLUGIN                          │ │
│  │                                                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │ │
│  │  │  SYSTEM 1   │  │  SYSTEM 2   │  │  SYSTEM 3   │          │ │
│  │  │  Behavior   │  │  Autodocs   │  │ Spec-Driven │          │ │
│  │  │Optimization │  │             │  │             │          │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘          │ │
│  │         │                 │                 │                 │ │
│  │         └─────────────────┼─────────────────┘                 │ │
│  │                           ▼                                   │ │
│  │                  ┌─────────────────┐                          │ │
│  │                  │  Integration    │                          │ │
│  │                  │     Layer       │                          │ │
│  │                  └─────────────────┘                          │ │
│  └───────────────────────────┬───────────────────────────────────┘ │
│                              ▼                                     │
│                  ┌─────────────────────┐                          │
│                  │  Hook System        │                          │
│                  │  - SessionStart     │                          │
│                  │  - PostToolUse      │                          │
│                  └─────────────────────┘                          │
└──────────────────────────┬──────────────────────────────────────────┘
                           ▼
               ┌────────────────────────┐
               │   USER PROJECT         │
               │                        │
               │  .spec-drive/          │
               │  ├── config.yaml       │
               │  ├── state.yaml        │
               │  ├── index.yaml        │
               │  ├── specs/            │
               │  ├── schemas/          │
               │  └── development/      │
               │                        │
               │  docs/                 │
               │  src/                  │
               │  tests/                │
               └────────────────────────┘
```

### 4.2 Three-System Integration Model

```
┌──────────────────────────────────────────────────────────────────┐
│                    INTEGRATED WORKFLOW                           │
└──────────────────────────────────────────────────────────────────┘

USER ACTION: /spec-drive:feature AUTH-001 "User authentication"

┌─────────────────────┐
│  SYSTEM 1: BEHAVIOR │  ← SessionStart hook injects strict-concise
└──────────┬──────────┘
           │ Enforces:
           │ - Extreme planning (TodoWrite)
           │ - Quality gates
           │ - No shortcuts
           ▼
┌─────────────────────┐
│ STAGE: DISCOVER     │
└──────────┬──────────┘
           │ PostToolUse hook → dirty: true
           │
           ▼
┌─────────────────────┐
│ STAGE: SPECIFY      │  ← SYSTEM 3: Workflow orchestration
└──────────┬──────────┘
           │ Create .spec-drive/specs/AUTH-001.yaml
           │
           ▼ GATE-1: Spec complete?
           │
┌─────────────────────┐
│ STAGE: IMPLEMENT    │
└──────────┬──────────┘
           │ Write code with /** @spec AUTH-001 */ tags
           │ Write tests with /** @spec AUTH-001 */ tags
           │
           ▼ GATE-3: Tests pass? @spec tags present?
           │
┌─────────────────────┐
│ STAGE: VERIFY       │
└──────────┬──────────┘
           │
           ▼ GATE-4: Docs updated? Traceability complete?
           │
           │ ┌────────────────────────┐
           └►│ SYSTEM 2: AUTODOCS     │
             │ - Update index.yaml    │
             │ - Regenerate docs      │
             │ - Clear dirty flag     │
             └────────┬───────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ SPEC COMPLETE │
              │ status: done  │
              └───────────────┘
```

### 4.3 Data Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    .spec-drive/ FOLDER STRUCTURE               │
└────────────────────────────────────────────────────────────────┘

.spec-drive/
├── config.yaml          ← Configuration (git tracked)
│   ├── project_name
│   ├── stack_profile
│   ├── behavior_mode
│   └── gate_enforcement
│
├── state.yaml          ← Runtime state (gitignored)
│   ├── current_workflow
│   ├── current_spec
│   ├── current_stage
│   ├── can_advance
│   └── dirty (autodocs trigger)
│
├── index.yaml          ← AI-optimized index (gitignored, regenerable)
│   ├── components[]
│   ├── specs[]
│   ├── docs[]
│   └── code[]
│
├── specs/              ← Spec YAML files (git tracked)
│   ├── APP-001.yaml
│   ├── AUTH-001.yaml
│   └── SPEC-XXX.yaml
│
├── schemas/            ← JSON Schemas (git tracked)
│   └── v0.1/
│       ├── spec-schema.json
│       ├── index-schema.json
│       ├── config-schema.json
│       └── state-schema.json
│
└── development/        ← Planning docs (git tracked)
    ├── current/        (active version)
    │   ├── PRD.md
    │   ├── TDD.md
    │   └── DECISIONS.md
    ├── planned/        (future versions)
    │   ├── v0.2/
    │   └── v0.3/
    ├── completed/      (shipped versions)
    └── archive/        (deprecated/obsolete)
```

**Data Flow Summary:**

1. **User Input** → Slash command (`/spec-drive:feature`)
2. **Workflow Script** → Updates `state.yaml` (current stage)
3. **PostToolUse Hook** → Sets `dirty: true` in `state.yaml`
4. **Quality Gate** → Checks criteria, sets `can_advance`
5. **Autodocs (if dirty)** → Updates `index.yaml`, regenerates docs
6. **Behavior Agent** → Verifies docs updated, allows stage advancement

---

## 5. THREE-SYSTEM OVERVIEW

### 5.1 System 1: Behavior Optimization

**Purpose:** Enforce quality gates, planning rigor, and best practices throughout development.

**Core Mechanism:** SessionStart hook auto-injection

```bash
# spec-drive/hooks/handlers/session-start.sh
cat spec-drive/assets/strict-concise-behavior.md
```

**Behavior Content (strict-concise-behavior.md):**
- Quality gates: Stop-the-line on errors, <95% confidence checks
- Extreme planning: TodoWrite with in/do/out/check/risk/needs format
- Parallel delegation: Multiple Task() calls in single messages
- Docs-first enforcement: Verify docs updated before marking stages complete
- Zero shortcuts: No TODO/console.log/placeholders allowed
- Atomic commits: Code + tests + docs committed together

**Integration Points:**

1. **With System 2 (Autodocs):**
   - Behavior agent VERIFIES docs are updated
   - Autodocs system UPDATES the docs
   - Separation of concerns: verify vs. update

2. **With System 3 (Spec-Driven):**
   - Behavior agent enforces workflow discipline
   - Reads `state.yaml` to know current stage
   - Blocks advancement if `can_advance: false`

**Key Components:**

- `spec-drive/hooks/hooks.json` - Hook registration
- `spec-drive/hooks/handlers/session-start.sh` - Hook handler
- `spec-drive/assets/strict-concise-behavior.md` - Agent behavior content

**Performance:**

- SessionStart executes once per session (~100ms)
- No per-action overhead
- Behavior rules loaded into Claude context

### 5.2 System 2: Autodocs (Self-Updating Documentation)

**Purpose:** Maintain accurate, AI-optimized documentation automatically at workflow stage boundaries.

**Core Mechanism:** Stage-boundary regeneration triggered by dirty flag

**Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                      AUTODOCS WORKFLOW                          │
└─────────────────────────────────────────────────────────────────┘

1. TRIGGER: PostToolUse hook (during development)
   └─► Set dirty: true in state.yaml

2. GATE PASSES: Quality gate at stage boundary
   └─► If dirty: true → Run autodocs

3. AUTODOCS EXECUTION:
   ┌──────────────────────┐
   │ DocIndexAgent        │
   │ - Scan code changes  │
   │ - Update index.yaml  │
   │ - Map traces         │
   └──────┬───────────────┘
          │
          ▼
   ┌──────────────────────┐
   │ DocUpdateAgent       │
   │ - Regenerate docs    │
   │ - Update AUTO marks  │
   │ - Preserve manual    │
   └──────┬───────────────┘
          │
          ▼
   Set dirty: false

4. RESULT: Docs current, index updated, ready for AI queries
```

**Index Structure (index.yaml):**

```yaml
meta:
  generated: "2025-11-01T10:30:00Z"
  version: "0.1.0"
  project_name: "my-app"

components:
  - id: "auth-service"
    type: "service"
    path: "src/auth/AuthService.ts:15"
    summary: "Handles user authentication and session management"
    dependencies: ["database-client", "jwt-utils"]

specs:
  - id: "AUTH-001"
    title: "User authentication"
    status: "implemented"
    trace:
      code:
        - "src/auth/AuthService.ts:42"
        - "src/auth/login.ts:18"
      tests:
        - "tests/auth/login.test.ts:12"
        - "tests/auth/session.test.ts:8"
      docs:
        - "docs/60-features/AUTH-001.md"

docs:
  - path: "docs/10-architecture/ARCHITECTURE.md"
    type: "architecture"
    summary: "System architecture and design philosophy"
    last_updated: "2025-11-01T09:15:00Z"

code:
  - path: "src/auth/AuthService.ts"
    components: ["auth-service"]
    specs: ["AUTH-001"]
    summary: "Main authentication service implementation"
```

**Integration Points:**

1. **With System 1 (Behavior):**
   - Behavior agent verifies docs updated (checks timestamps)
   - Behavior agent enforces docs-first (blocks completion if docs outdated)

2. **With System 3 (Spec-Driven):**
   - Autodocs reads `state.yaml` to know which spec is active
   - Updates spec status in `index.yaml`
   - Regenerates `docs/60-features/SPEC-ID.md` for active spec

**Key Components:**

- `scripts/tools/analyze-codebase.js` - Deep code analysis for existing projects
- `scripts/tools/index-docs.js` - Build/update index.yaml
- `scripts/tools/update-docs.js` - Regenerate docs from index
- `templates/docs/*.md.template` - Document templates
- `templates/index-template.yaml` - Index structure template

**Performance:**

- Index generation: <5 seconds for medium codebase
- Doc regeneration: <3 seconds for affected docs only
- Runs ONLY at stage boundaries (not continuous)

### 5.3 System 3: Spec-Driven Development

**Purpose:** Enforce workflow discipline with traceability connecting specs → code → tests → docs.

**Core Mechanism:** Stage-based workflows with quality gates

**Workflow State Machine:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    FEATURE WORKFLOW STAGES                      │
└─────────────────────────────────────────────────────────────────┘

    DISCOVER
       │
       │ User explores context, existing code
       │
       ▼
   [GATE-1]  ← Spec created?
       │
       ▼
    SPECIFY
       │
       │ Create .spec-drive/specs/SPEC-ID.yaml
       │ Define acceptance criteria
       │
       ▼
   [GATE-2]  ← Spec complete? ACs testable?
       │
       ▼
   IMPLEMENT
       │
       │ Write code with /** @spec SPEC-ID */ tags
       │ Write tests with /** @spec SPEC-ID */ tags
       │
       ▼
   [GATE-3]  ← Tests pass? @spec tags present? No lint errors?
       │
       ▼
    VERIFY
       │
       │ All ACs met? Docs updated? Traceability complete?
       │
       ▼
   [GATE-4]  ← All checks pass?
       │
       ▼
     DONE
```

**Quality Gates Detail:**

**Gate 1: Discover → Specify**
- Check: Spec file created at `.spec-drive/specs/SPEC-ID.yaml`
- Check: No `[NEEDS CLARIFICATION]` markers
- Check: Success criteria defined and measurable
- Script: `spec-drive/scripts/gates/gate-1-specify.sh`

**Gate 2: Specify → Implement**
- Check: All acceptance criteria testable and unambiguous
- Check: API contracts defined (if applicable)
- Check: Test scenarios outlined
- Script: `spec-drive/scripts/gates/gate-2-implement.sh`

**Gate 3: Implement → Verify**
- Check: All tests pass (`npm test` or equivalent)
- Check: `@spec SPEC-ID` tags present in code and tests
- Check: No linting errors (`npm run lint`)
- Check: No typecheck errors (`npx tsc --noEmit` or equivalent)
- Script: `spec-drive/scripts/gates/gate-3-verify.sh`

**Gate 4: Verify → Done**
- Check: All acceptance criteria met
- Check: Documentation updated (autodocs ran + manual sections complete)
- Check: No TODO/console.log/placeholders (`grep -r "TODO\|console\.log" src/`)
- Check: Traceability complete (index.yaml has spec → code → tests → docs links)
- Script: `spec-drive/scripts/gates/gate-4-done.sh`

**Traceability System:**

**Tag Format (Language-Specific):**

```typescript
// TypeScript/JavaScript
/** @spec AUTH-001 */
export function login(credentials: Credentials): Promise<User> {
  // implementation
}

// Test file
/** @spec AUTH-001 */
describe('login', () => {
  it('should authenticate valid credentials', () => {
    // test
  });
});
```

```python
# Python
"""@spec AUTH-001"""
def login(credentials: dict) -> User:
    """Authenticate user with credentials."""
    pass

# Test file
"""@spec AUTH-001"""
def test_login_valid_credentials():
    """Test authentication with valid credentials."""
    pass
```

**Detection Mechanism:**

```bash
# In gate-3-verify.sh
grep -r "@spec SPEC-ID" src/ tests/
# Must return matches in both src/ and tests/
```

**Index Trace Mapping:**

```yaml
# In index.yaml, populated by DocIndexAgent
specs:
  - id: "AUTH-001"
    trace:
      code:
        - "src/auth/login.ts:42"     # Line where @spec tag found
      tests:
        - "tests/auth/login.test.ts:12"  # Line where @spec tag found
```

**Integration Points:**

1. **With System 1 (Behavior):**
   - Workflow scripts update `state.yaml`
   - Behavior agent reads `state.yaml` to know current stage
   - Behavior agent enforces no stage skipping

2. **With System 2 (Autodocs):**
   - Workflow completion triggers autodocs (if dirty flag set)
   - Autodocs updates spec status in index.yaml
   - Autodocs regenerates feature page (`docs/60-features/SPEC-ID.md`)

**Key Components:**

- `commands/app-new.md` - App-new workflow slash command
- `commands/feature.md` - Feature workflow slash command
- `scripts/workflows/app-new.sh` - App-new orchestrator
- `scripts/workflows/feature.sh` - Feature orchestrator
- `scripts/gates/gate-*.sh` - Quality gate check scripts
- `templates/spec-template.yaml` - Spec YAML file template

**Performance:**

- Workflow script execution: <500ms per stage transition
- Gate checks: <2 seconds per gate (depends on test suite)
- State updates: <100ms

---

## 6. COMPONENT BREAKDOWN

### 6.1 Component Architecture Overview

spec-drive v0.1 consists of **27 primary components** organized into 6 subsystems:

```
spec-drive/
├── hooks/                    # Subsystem 1: Hook System (2 components)
├── commands/                 # Subsystem 2: Slash Commands (2 components)
├── scripts/
│   ├── workflows/            # Subsystem 3: Workflow Orchestrators (2 components)
│   ├── gates/                # Subsystem 4: Quality Gates (4 components)
│   └── tools/                # Subsystem 5: Autodocs Tools (7 components)
└── templates/                # Subsystem 6: Templates (10 components)
```

---

### 6.2 Subsystem 1: Hook System

**Purpose:** Auto-inject behavior and track tool usage during Claude Code sessions.

#### Component 1.1: hooks/hooks.json

**Type:** Configuration File
**Responsibility:** Register hooks with Claude Code plugin system

**Schema:**
```json
{
  "hooks": {
    "SessionStart": {
      "handler": "spec-drive/hooks/handlers/session-start.sh",
      "description": "Inject strict-concise behavior for all sessions"
    },
    "PostToolUse": {
      "handler": "spec-drive/hooks/handlers/post-tool-use.sh",
      "description": "Set dirty flag when code/docs change"
    }
  }
}
```

**Dependencies:** None
**Inputs:** None
**Outputs:** Hook registration in Claude Code
**Performance:** <10ms (one-time registration)

#### Component 1.2: hooks/handlers/session-start.sh

**Type:** Bash Script
**Responsibility:** Inject strict-concise behavior content into Claude Code session

**Pseudocode:**
```bash
#!/bin/bash
# Inject behavior optimization content
cat spec-drive/assets/strict-concise-behavior.md
```

**Dependencies:**
- `spec-drive/assets/strict-concise-behavior.md` (behavior content)

**Inputs:** None
**Outputs:** Behavior markdown content to stdout (consumed by Claude Code)
**Performance:** <100ms (cat operation)
**Error Handling:** Exit 1 if behavior file not found

#### Component 1.3: hooks/handlers/post-tool-use.sh

**Type:** Bash Script
**Responsibility:** Set dirty flag in state.yaml when code/docs change

**Pseudocode:**
```bash
#!/bin/bash
TOOL_NAME=$1
TOOL_ARGS=$2

# Check if tool affects code or docs
if [[ "$TOOL_NAME" =~ ^(Edit|Write|NotebookEdit)$ ]]; then
  # Tool affects code/docs → set dirty flag
  yq eval '.dirty = true' -i .spec-drive/state.yaml
fi
```

**Dependencies:**
- `yq` (YAML processor)
- `.spec-drive/state.yaml`

**Inputs:**
- `$1`: Tool name (Edit, Write, NotebookEdit, etc.)
- `$2`: Tool arguments

**Outputs:**
- Updates `.spec-drive/state.yaml` (sets `dirty: true`)

**Performance:** <50ms (YAML update)
**Error Handling:** Silently fail if state.yaml not found (project not initialized)

---

### 6.3 Subsystem 2: Slash Commands

**Purpose:** Entry points for user-initiated workflows.

#### Component 2.1: commands/app-new.md

**Type:** Markdown Slash Command
**Responsibility:** Launch new project initialization workflow

**Content Structure:**
```markdown
# /spec-drive:app-new

You are starting the **app-new** workflow for a new project.

## Current Stage: DISCOVER

Your task:
1. Ask the user about project vision, goals, users
2. Guide planning session for:
   - Project purpose and scope
   - Target users and use cases
   - Initial architecture decisions
   - Tech stack selection

3. After planning complete, advance to SPECIFY stage:
   - Create .spec-drive/specs/APP-001.yaml
   - Document project requirements

4. Then IMPLEMENT stage:
   - Generate full docs/ structure
   - Create .spec-drive/ config and index

5. Finally VERIFY stage:
   - Ensure documentation complete
   - Ready for feature development

State file: .spec-drive/state.yaml
Current workflow: app-new
```

**Dependencies:**
- `scripts/workflows/app-new.sh` (orchestrator)
- `.spec-drive/state.yaml`

**Inputs:** None (user invokes via `/spec-drive:app-new`)
**Outputs:** Claude Code prompt instructing app-new workflow
**Performance:** <10ms (markdown read)

#### Component 2.2: commands/feature.md

**Type:** Markdown Slash Command
**Responsibility:** Launch feature development workflow

**Content Structure:**
```markdown
# /spec-drive:feature [SPEC-ID] [title]

You are starting the **feature** workflow.

## Arguments
- SPEC-ID: Feature spec identifier (e.g., AUTH-001)
- title: Brief feature description

## Current Stage: {READ FROM state.yaml}

Your task:
1. DISCOVER: Explore context, existing code, requirements
2. SPECIFY: Create .spec-drive/specs/{SPEC-ID}.yaml with ACs
3. IMPLEMENT: Write code + tests with @spec tags
4. VERIFY: All gates pass, docs updated, traceability complete

Quality gates will run automatically at stage transitions.

State file: .spec-drive/state.yaml
```

**Dependencies:**
- `scripts/workflows/feature.sh` (orchestrator)
- `.spec-drive/state.yaml`

**Inputs:**
- `SPEC-ID`: Feature identifier
- `title`: Feature title

**Outputs:** Claude Code prompt instructing feature workflow
**Performance:** <10ms (markdown read)

---

### 6.4 Subsystem 3: Workflow Orchestrators

**Purpose:** Manage workflow state transitions and gate enforcement.

#### Component 3.1: scripts/workflows/app-new.sh

**Type:** Bash Script
**Responsibility:** Orchestrate app-new workflow stages

**Pseudocode:**
```bash
#!/bin/bash
# Initialize new project workflow

STAGE=${1:-"discover"}  # Current stage
PROJECT_NAME=${2:-""}

case $STAGE in
  discover)
    echo "DISCOVER stage: Planning session"
    # User does planning (no automation in v0.1)
    ;;

  specify)
    echo "Creating APP-001.yaml spec"
    scripts/tools/create-spec.sh APP-001 "Project: $PROJECT_NAME"
    yq eval '.current_stage = "specify"' -i .spec-drive/state.yaml
    ;;

  implement)
    echo "Generating documentation structure"
    scripts/tools/init-docs.sh
    scripts/tools/generate-index.sh
    yq eval '.current_stage = "implement"' -i .spec-drive/state.yaml
    ;;

  verify)
    echo "Running gate-4-done"
    scripts/gates/gate-4-done.sh
    if [ $? -eq 0 ]; then
      yq eval '.workflows.APP-001.status = "done"' -i .spec-drive/state.yaml
      echo "✅ App-new workflow complete"
    fi
    ;;
esac
```

**Dependencies:**
- `scripts/tools/create-spec.sh`
- `scripts/tools/init-docs.sh`
- `scripts/tools/generate-index.sh`
- `scripts/gates/gate-4-done.sh`
- `yq` (YAML processor)

**Inputs:**
- `$1`: Current stage (discover, specify, implement, verify)
- `$2`: Project name

**Outputs:**
- Updates `.spec-drive/state.yaml`
- Creates `.spec-drive/specs/APP-001.yaml`
- Generates `docs/` structure

**Performance:** <30 seconds (full workflow)
**Error Handling:** Exit non-zero if gate fails

#### Component 3.2: scripts/workflows/feature.sh

**Type:** Bash Script
**Responsibility:** Orchestrate feature workflow stages

**Pseudocode:**
```bash
#!/bin/bash
# Feature development workflow

SPEC_ID=$1
STAGE=${2:-"discover"}

case $STAGE in
  discover)
    echo "DISCOVER: Exploring context for $SPEC_ID"
    yq eval '.current_spec = "'$SPEC_ID'"' -i .spec-drive/state.yaml
    yq eval '.current_stage = "discover"' -i .spec-drive/state.yaml
    ;;

  specify)
    echo "SPECIFY: Running gate-1"
    scripts/gates/gate-1-specify.sh $SPEC_ID
    if [ $? -eq 0 ]; then
      yq eval '.current_stage = "specify"' -i .spec-drive/state.yaml
      yq eval '.can_advance = true' -i .spec-drive/state.yaml
    fi
    ;;

  implement)
    echo "IMPLEMENT: Running gate-2"
    scripts/gates/gate-2-implement.sh $SPEC_ID
    if [ $? -eq 0 ]; then
      yq eval '.current_stage = "implement"' -i .spec-drive/state.yaml
    fi
    ;;

  verify)
    echo "VERIFY: Running gate-3 and gate-4"
    scripts/gates/gate-3-verify.sh $SPEC_ID
    scripts/gates/gate-4-done.sh $SPEC_ID
    if [ $? -eq 0 ]; then
      yq eval '.workflows.'$SPEC_ID'.status = "done"' -i .spec-drive/state.yaml
      echo "✅ Feature $SPEC_ID complete"
    fi
    ;;
esac
```

**Dependencies:**
- All gate scripts (`gate-1` through `gate-4`)
- `yq` (YAML processor)

**Inputs:**
- `$1`: SPEC-ID
- `$2`: Current stage

**Outputs:**
- Updates `.spec-drive/state.yaml`
- Triggers gate checks
- Triggers autodocs (if dirty flag set)

**Performance:** <500ms per stage (excluding gate execution)
**Error Handling:** Block advancement if gate fails

---

### 6.5 Subsystem 4: Quality Gates

**Purpose:** Enforce quality criteria at workflow stage boundaries.

#### Component 4.1: scripts/gates/gate-1-specify.sh

**Type:** Bash Script
**Responsibility:** Verify spec file created and complete

**Checks:**
```bash
#!/bin/bash
SPEC_ID=$1
SPEC_FILE=".spec-drive/specs/$SPEC_ID.yaml"

# Check 1: Spec file exists
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Gate 1 FAILED: Spec file not found: $SPEC_FILE"
  exit 1
fi

# Check 2: No [NEEDS CLARIFICATION] markers
if grep -q "\[NEEDS CLARIFICATION\]" "$SPEC_FILE"; then
  echo "❌ Gate 1 FAILED: Spec contains [NEEDS CLARIFICATION] markers"
  exit 1
fi

# Check 3: Success criteria defined
if ! yq eval '.success_criteria' "$SPEC_FILE" | grep -q "."; then
  echo "❌ Gate 1 FAILED: No success criteria defined"
  exit 1
fi

echo "✅ Gate 1 PASSED: Spec complete and ready"
exit 0
```

**Dependencies:**
- `yq` (YAML processor)
- `grep`

**Inputs:** `$1` = SPEC-ID
**Outputs:** Exit 0 (pass) or 1 (fail)
**Performance:** <500ms

#### Component 4.2: scripts/gates/gate-2-implement.sh

**Type:** Bash Script
**Responsibility:** Verify spec has testable acceptance criteria

**Checks:**
```bash
#!/bin/bash
SPEC_ID=$1
SPEC_FILE=".spec-drive/specs/$SPEC_ID.yaml"

# Check 1: Acceptance criteria defined
AC_COUNT=$(yq eval '.acceptance_criteria | length' "$SPEC_FILE")
if [ "$AC_COUNT" -eq 0 ]; then
  echo "❌ Gate 2 FAILED: No acceptance criteria defined"
  exit 1
fi

# Check 2: Each AC has testable description
for i in $(seq 0 $(($AC_COUNT - 1))); do
  AC=$(yq eval ".acceptance_criteria[$i]" "$SPEC_FILE")
  if [[ -z "$AC" ]]; then
    echo "❌ Gate 2 FAILED: AC $i is empty"
    exit 1
  fi
done

echo "✅ Gate 2 PASSED: Spec ready for implementation"
exit 0
```

**Dependencies:**
- `yq` (YAML processor)

**Inputs:** `$1` = SPEC-ID
**Outputs:** Exit 0 (pass) or 1 (fail)
**Performance:** <500ms

#### Component 4.3: scripts/gates/gate-3-verify.sh

**Type:** Bash Script
**Responsibility:** Verify implementation complete with tests and @spec tags

**Checks:**
```bash
#!/bin/bash
SPEC_ID=$1

# Check 1: Tests pass
echo "Running tests..."
npm test
if [ $? -ne 0 ]; then
  echo "❌ Gate 3 FAILED: Tests failing"
  exit 1
fi

# Check 2: @spec tags present in code
CODE_TAGS=$(grep -r "@spec $SPEC_ID" src/ | wc -l)
if [ "$CODE_TAGS" -eq 0 ]; then
  echo "❌ Gate 3 FAILED: No @spec $SPEC_ID tags in src/"
  exit 1
fi

# Check 3: @spec tags present in tests
TEST_TAGS=$(grep -r "@spec $SPEC_ID" tests/ | wc -l)
if [ "$TEST_TAGS" -eq 0 ]; then
  echo "❌ Gate 3 FAILED: No @spec $SPEC_ID tags in tests/"
  exit 1
fi

# Check 4: No linting errors
npm run lint
if [ $? -ne 0 ]; then
  echo "❌ Gate 3 FAILED: Linting errors"
  exit 1
fi

echo "✅ Gate 3 PASSED: Implementation complete"
exit 0
```

**Dependencies:**
- `npm` (test and lint commands)
- `grep`

**Inputs:** `$1` = SPEC-ID
**Outputs:** Exit 0 (pass) or 1 (fail)
**Performance:** <10 seconds (depends on test suite)

#### Component 4.4: scripts/gates/gate-4-done.sh

**Type:** Bash Script
**Responsibility:** Verify docs updated and traceability complete

**Checks:**
```bash
#!/bin/bash
SPEC_ID=$1

# Check 1: No TODO/console.log in code
SHORTCUTS=$(grep -r "TODO\|console\.log" src/ | wc -l)
if [ "$SHORTCUTS" -gt 0 ]; then
  echo "❌ Gate 4 FAILED: Found $SHORTCUTS TODO/console.log instances"
  exit 1
fi

# Check 2: Index has trace for this spec
TRACE_COUNT=$(yq eval '.specs[] | select(.id == "'$SPEC_ID'") | .trace.code | length' .spec-drive/index.yaml)
if [ "$TRACE_COUNT" -eq 0 ]; then
  echo "❌ Gate 4 FAILED: No trace in index.yaml for $SPEC_ID"
  exit 1
fi

# Check 3: Feature doc exists
if [ ! -f "docs/60-features/$SPEC_ID.md" ]; then
  echo "❌ Gate 4 FAILED: Feature doc not found: docs/60-features/$SPEC_ID.md"
  exit 1
fi

# Check 4: Dirty flag cleared (docs updated)
DIRTY=$(yq eval '.dirty' .spec-drive/state.yaml)
if [ "$DIRTY" = "true" ]; then
  echo "❌ Gate 4 FAILED: Dirty flag still set (docs not updated)"
  exit 1
fi

echo "✅ Gate 4 PASSED: Spec complete and verified"
exit 0
```

**Dependencies:**
- `yq` (YAML processor)
- `grep`

**Inputs:** `$1` = SPEC-ID
**Outputs:** Exit 0 (pass) or 1 (fail)
**Performance:** <1 second

---

### 6.6 Subsystem 5: Autodocs Tools

**Purpose:** Analyze code, generate index, and update documentation.

#### Component 5.1: scripts/tools/analyze-codebase.js

**Type:** Node.js Script
**Responsibility:** Deep code analysis for existing projects

**Logic:**
```javascript
// Analyze codebase and extract structure
const fs = require('fs');
const path = require('path');

async function analyzeCodebase(srcDir) {
  const components = [];
  const files = walkDir(srcDir);

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');

    // Detect components (classes, functions, modules)
    const detectedComponents = detectComponents(content, file);
    components.push(...detectedComponents);
  }

  // Map dependencies between components
  const dependencyMap = buildDependencyMap(components);

  return { components, dependencies: dependencyMap };
}

function detectComponents(code, filePath) {
  // Regex patterns for different component types
  // TypeScript: class, interface, function, const exports
  // Python: class, def
  // Generic: exported symbols
}

function buildDependencyMap(components) {
  // Analyze imports/requires to map dependencies
}
```

**Dependencies:**
- Node.js fs, path modules
- `@babel/parser` (for TypeScript/JavaScript parsing)

**Inputs:** `srcDir` (project source directory)
**Outputs:** JSON object with components and dependencies
**Performance:** <60 seconds for medium codebase (~10k LOC)

#### Component 5.2: scripts/tools/index-docs.js

**Type:** Node.js Script
**Responsibility:** Build/update index.yaml from code and specs

**Logic:**
```javascript
// Generate index.yaml
const yaml = require('js-yaml');
const fs = require('fs');

async function buildIndex(projectRoot) {
  const index = {
    meta: {
      generated: new Date().toISOString(),
      version: '0.1.0',
      project_name: getProjectName(projectRoot)
    },
    components: [],
    specs: [],
    docs: [],
    code: []
  };

  // 1. Scan specs/
  index.specs = scanSpecs(`${projectRoot}/.spec-drive/specs/`);

  // 2. Scan code for @spec tags
  index.code = scanCodeForSpecTags(`${projectRoot}/src/`);

  // 3. Scan tests for @spec tags
  const testTraces = scanCodeForSpecTags(`${projectRoot}/tests/`);

  // 4. Map traces to specs
  index.specs = mapTracesToSpecs(index.specs, index.code, testTraces);

  // 5. Scan docs/
  index.docs = scanDocs(`${projectRoot}/docs/`);

  // 6. Write index.yaml
  fs.writeFileSync(
    `${projectRoot}/.spec-drive/index.yaml`,
    yaml.dump(index)
  );
}
```

**Dependencies:**
- `js-yaml` (YAML parsing)
- `grep` (for @spec tag detection)

**Inputs:** `projectRoot` (project directory)
**Outputs:** `.spec-drive/index.yaml` file
**Performance:** <5 seconds for medium codebase

#### Component 5.3: scripts/tools/update-docs.js

**Type:** Node.js Script
**Responsibility:** Regenerate docs from index and templates

**Logic:**
```javascript
// Regenerate documentation
const fs = require('fs');
const yaml = require('js-yaml');

async function updateDocs(projectRoot) {
  const index = yaml.load(fs.readFileSync(`${projectRoot}/.spec-drive/index.yaml`));
  const dirty = checkDirtyFlag(projectRoot);

  if (!dirty) {
    console.log('No changes, skipping doc update');
    return;
  }

  // 1. Update COMPONENT-CATALOG.md
  if (componentsChanged(index)) {
    regenerateComponentCatalog(index.components, projectRoot);
  }

  // 2. Update feature pages (docs/60-features/*.md)
  for (const spec of index.specs) {
    if (specChanged(spec)) {
      regenerateFeaturePage(spec, projectRoot);
    }
  }

  // 3. Update API docs (if APIs changed)
  if (apisChanged(index)) {
    regenerateApiDocs(index, projectRoot);
  }

  // 4. Clear dirty flag
  clearDirtyFlag(projectRoot);
}
```

**Dependencies:**
- `js-yaml` (YAML parsing)
- Template files (`templates/docs/*.template`)

**Inputs:** `projectRoot` (project directory)
**Outputs:**
- Updated `docs/10-architecture/COMPONENT-CATALOG.md`
- Updated `docs/60-features/SPEC-*.md` files
- Updated `docs/40-api/*.md` files

**Performance:** <3 seconds for affected docs only

#### Component 5.4-5.7: Supporting Tools

**5.4: scripts/tools/create-spec.sh** - Generate spec YAML from template
**5.5: scripts/tools/init-docs.sh** - Initialize docs/ structure for new projects
**5.6: scripts/tools/generate-index.sh** - Wrapper for index-docs.js
**5.7: scripts/tools/validate-spec.sh** - Validate spec YAML against schema

---

### 6.7 Subsystem 6: Templates

**Purpose:** Provide structure and content templates for docs and specs.

#### Component 6.1: templates/spec-template.yaml

**Type:** YAML Template
**Purpose:** Spec file structure

**Structure:**
```yaml
id: "{{SPEC_ID}}"
title: "{{TITLE}}"
status: draft
created: "{{DATE}}"
updated: "{{DATE}}"

summary: |
  Brief description of the feature

acceptance_criteria:
  - criterion: "AC1 description"
    testable: true
  - criterion: "AC2 description"
    testable: true

success_criteria:
  - "Measurable success metric 1"
  - "Measurable success metric 2"

dependencies: []
risks: []
```

#### Component 6.2-6.11: Documentation Templates

**6.2: templates/docs/SYSTEM-OVERVIEW.md.template** - Project overview
**6.3: templates/docs/GLOSSARY.md.template** - Terminology
**6.4: templates/docs/ARCHITECTURE.md.template** - System architecture
**6.5: templates/docs/COMPONENT-CATALOG.md.template** - Component registry (AUTO-updated)
**6.6: templates/docs/DATA-FLOWS.md.template** - Data movement
**6.7: templates/docs/RUNTIME-DEPLOYMENT.md.template** - Deployment
**6.8: templates/docs/BUILD-RELEASE.md.template** - Build process
**6.9: templates/docs/PRODUCT-BRIEF.md.template** - Goals, roadmap
**6.10: templates/docs/FEATURE-SPEC.md.template** - Feature page (AUTO-generated)
**6.11: templates/index-template.yaml** - index.yaml structure

---

## 7. DATA FLOWS

### 7.1 Complete Feature Development Flow

```
┌──────────────────────────────────────────────────────────────────┐
│              END-TO-END FEATURE WORKFLOW DATA FLOW               │
└──────────────────────────────────────────────────────────────────┘

USER: /spec-drive:feature AUTH-001 "User authentication"
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. SLASH COMMAND PROCESSING                                     │
└─────────────────────────────────────────────────────────────────┘
  commands/feature.md
    │
    ├─ Parse arguments: SPEC_ID="AUTH-001", title="User authentication"
    └─ Invoke: scripts/workflows/feature.sh AUTH-001 discover
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. WORKFLOW ORCHESTRATOR                                        │
└─────────────────────────────────────────────────────────────────┘
  scripts/workflows/feature.sh
    │
    ├─ Update state.yaml:
    │    current_workflow: feature
    │    current_spec: AUTH-001
    │    current_stage: discover
    │
    └─ User performs discovery (explore code, gather requirements)
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. POSTTOOLUSE HOOK (During Discovery)                         │
└─────────────────────────────────────────────────────────────────┘
  hooks/handlers/post-tool-use.sh
    │
    ├─ Detect: User used Edit/Write tools
    └─ Update state.yaml: dirty = true
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. STAGE TRANSITION: DISCOVER → SPECIFY                        │
└─────────────────────────────────────────────────────────────────┘
  scripts/workflows/feature.sh AUTH-001 specify
    │
    ├─ Run gate-1-specify.sh AUTH-001
    │    │
    │    ├─ Check: .spec-drive/specs/AUTH-001.yaml exists?
    │    ├─ Check: No [NEEDS CLARIFICATION] markers?
    │    └─ Check: Success criteria defined?
    │
    ├─ If gate passes:
    │    └─ Update state.yaml: can_advance = true, current_stage = specify
    │
    └─ If gate fails:
         └─ Update state.yaml: can_advance = false
             (Behavior agent blocks advancement)
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. STAGE TRANSITION: SPECIFY → IMPLEMENT                       │
└─────────────────────────────────────────────────────────────────┘
  scripts/workflows/feature.sh AUTH-001 implement
    │
    ├─ Run gate-2-implement.sh AUTH-001
    │    └─ Check: Acceptance criteria testable?
    │
    ├─ User writes code with /** @spec AUTH-001 */ tags
    └─ User writes tests with /** @spec AUTH-001 */ tags
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. STAGE TRANSITION: IMPLEMENT → VERIFY                        │
└─────────────────────────────────────────────────────────────────┘
  scripts/workflows/feature.sh AUTH-001 verify
    │
    ├─ Run gate-3-verify.sh AUTH-001
    │    │
    │    ├─ Run: npm test
    │    ├─ Check: @spec AUTH-001 tags in src/
    │    ├─ Check: @spec AUTH-001 tags in tests/
    │    └─ Run: npm run lint
    │
    └─ If gate passes:
         └─ Proceed to gate-4
        │
        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. FINAL GATE: VERIFY → DONE                                   │
└─────────────────────────────────────────────────────────────────┘
  scripts/gates/gate-4-done.sh AUTH-001
    │
    ├─ Check: No TODO/console.log in src/
    ├─ Check: Trace exists in index.yaml
    ├─ Check: Feature doc exists (docs/60-features/AUTH-001.md)
    └─ Check: dirty = false (docs updated)
        │
        ├─ If dirty = true → Trigger autodocs
        │    │
        │    ▼
        │  ┌─────────────────────────────────────────────────────┐
        │  │ 8. AUTODOCS EXECUTION                               │
        │  └─────────────────────────────────────────────────────┘
        │    scripts/tools/index-docs.js
        │      │
        │      ├─ Scan src/ for @spec AUTH-001 tags → find file:line
        │      ├─ Scan tests/ for @spec AUTH-001 tags → find file:line
        │      ├─ Update index.yaml:
        │      │    specs[AUTH-001].trace.code = ["src/auth/login.ts:42"]
        │      │    specs[AUTH-001].trace.tests = ["tests/auth/login.test.ts:12"]
        │      │
        │      └─ Invoke: scripts/tools/update-docs.js
        │           │
        │           ├─ Regenerate: docs/60-features/AUTH-001.md
        │           ├─ Update: docs/10-architecture/COMPONENT-CATALOG.md
        │           └─ Clear: state.yaml dirty = false
        │
        └─ Re-run gate-4 → passes
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. WORKFLOW COMPLETION                                          │
└─────────────────────────────────────────────────────────────────┘
  scripts/workflows/feature.sh
    │
    └─ Update state.yaml:
         workflows.AUTH-001.status = done
         current_workflow = null
         current_spec = null
         current_stage = null

✅ Feature AUTH-001 complete with full traceability
```

### 7.2 Data Flow: Autodocs Trigger Mechanism

```
┌──────────────────────────────────────────────────────────────────┐
│                    AUTODOCS TRIGGER FLOW                         │
└──────────────────────────────────────────────────────────────────┘

Developer writes code (Edit/Write tool)
  │
  ▼
PostToolUse Hook fires
  │
  ├─ Detects: Tool = Edit or Write
  └─ Updates: .spec-drive/state.yaml
       dirty: true
  │
  ▼
Development continues...
  │
  ▼
Stage boundary reached (e.g., Implement → Verify)
  │
  ▼
Quality gate executes (gate-3-verify.sh)
  │
  ├─ Tests pass? ✅
  ├─ @spec tags present? ✅
  └─ Lint clean? ✅
  │
  ▼
Gate-4-done.sh executes
  │
  ├─ Checks: dirty flag in state.yaml
  └─ If dirty = true:
       │
       ▼
     AUTODOCS TRIGGERED
       │
       ├─ 1. Run: scripts/tools/index-docs.js
       │      │
       │      ├─ Scan code for @spec tags
       │      ├─ Update index.yaml (traces)
       │      └─ Update index.yaml (component changes)
       │
       ├─ 2. Run: scripts/tools/update-docs.js
       │      │
       │      ├─ Read: index.yaml
       │      ├─ Regenerate: docs/60-features/SPEC-ID.md
       │      ├─ Update: docs/10-architecture/COMPONENT-CATALOG.md
       │      └─ Update: docs/40-api/*.md (if APIs changed)
       │
       └─ 3. Clear dirty flag
            └─ Update: .spec-drive/state.yaml
                 dirty: false
  │
  ▼
Gate-4 re-checks: dirty = false? ✅
  │
  ▼
Workflow completes
```

### 7.3 Data Flow: Index Generation

```
┌──────────────────────────────────────────────────────────────────┐
│                    INDEX GENERATION FLOW                         │
└──────────────────────────────────────────────────────────────────┘

scripts/tools/index-docs.js invoked
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. SCAN SPECS                                                   │
└─────────────────────────────────────────────────────────────────┘
  Read: .spec-drive/specs/*.yaml
    │
    └─ Extract: id, title, status, acceptance_criteria
        │
        ▼ Output: specs[] array
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. SCAN CODE FOR @SPEC TAGS                                    │
└─────────────────────────────────────────────────────────────────┘
  Run: grep -rn "@spec" src/
    │
    ├─ Find: src/auth/login.ts:42: /** @spec AUTH-001 */
    ├─ Find: src/auth/session.ts:18: /** @spec AUTH-001 */
    └─ Map: AUTH-001 → ["src/auth/login.ts:42", "src/auth/session.ts:18"]
        │
        ▼ Output: code_traces map
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. SCAN TESTS FOR @SPEC TAGS                                   │
└─────────────────────────────────────────────────────────────────┘
  Run: grep -rn "@spec" tests/
    │
    ├─ Find: tests/auth/login.test.ts:12: /** @spec AUTH-001 */
    └─ Map: AUTH-001 → ["tests/auth/login.test.ts:12"]
        │
        ▼ Output: test_traces map
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. MERGE TRACES INTO SPECS                                     │
└─────────────────────────────────────────────────────────────────┘
  For each spec in specs[]:
    │
    ├─ spec.trace.code = code_traces[spec.id]
    ├─ spec.trace.tests = test_traces[spec.id]
    └─ spec.trace.docs = ["docs/60-features/${spec.id}.md"]
        │
        ▼ Output: specs[] with full traces
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SCAN DOCS METADATA                                          │
└─────────────────────────────────────────────────────────────────┘
  Walk: docs/**/*.md
    │
    ├─ Extract frontmatter: type, summary
    ├─ Get: last_updated timestamp (file mtime)
    └─ Build: docs[] array
        │
        ▼ Output: docs[] metadata
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. WRITE INDEX.YAML                                            │
└─────────────────────────────────────────────────────────────────┘
  Write: .spec-drive/index.yaml
    │
    ├─ meta: {generated, version, project_name}
    ├─ components: [] (from code analysis)
    ├─ specs: [with traces]
    ├─ docs: [with metadata]
    └─ code: [with spec mappings]

✅ index.yaml generated (<5 seconds)
```

### 7.4 Data Flow: Quality Gate Execution

```
┌──────────────────────────────────────────────────────────────────┐
│                    QUALITY GATE CHECK FLOW                       │
└──────────────────────────────────────────────────────────────────┘

Workflow requests stage advancement
  │
  ▼
scripts/gates/gate-N-stage.sh SPEC-ID
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ GATE CHECKS (example: gate-3-verify.sh)                        │
└─────────────────────────────────────────────────────────────────┘
  │
  ├─ CHECK 1: Run tests
  │    │
  │    └─ Execute: npm test
  │         │
  │         ├─ Exit 0 → PASS ✅
  │         └─ Exit non-zero → FAIL ❌
  │
  ├─ CHECK 2: @spec tags in src/
  │    │
  │    └─ Execute: grep -r "@spec $SPEC_ID" src/
  │         │
  │         ├─ Matches found → PASS ✅
  │         └─ No matches → FAIL ❌
  │
  ├─ CHECK 3: @spec tags in tests/
  │    │
  │    └─ Execute: grep -r "@spec $SPEC_ID" tests/
  │         │
  │         ├─ Matches found → PASS ✅
  │         └─ No matches → FAIL ❌
  │
  └─ CHECK 4: Lint clean
       │
       └─ Execute: npm run lint
            │
            ├─ Exit 0 → PASS ✅
            └─ Exit non-zero → FAIL ❌
  │
  ▼
┌─────────────────────────────────────────────────────────────────┐
│ GATE RESULT                                                     │
└─────────────────────────────────────────────────────────────────┘
  │
  ├─ ALL CHECKS PASS:
  │    │
  │    ├─ Update state.yaml: can_advance = true
  │    └─ Exit 0
  │
  └─ ANY CHECK FAILS:
       │
       ├─ Update state.yaml: can_advance = false
       ├─ Echo error message
       └─ Exit 1
  │
  ▼
Behavior agent reads state.yaml
  │
  ├─ can_advance = true → Allow stage advancement
  └─ can_advance = false → Block stage advancement (stop-the-line)
```

---

## 8. INTEGRATION POINTS

*(To be completed in Step 3 - TDD Integration Points)*

---

## 9. IMPLEMENTATION DETAILS

*(To be completed in Step 3 - TDD Implementation Details)*

---

## 10. QUALITY ATTRIBUTES

*(To be completed in Step 3 - TDD Quality Attributes)*

---

## APPENDICES

### A. Glossary

- **Behavior Agent:** Claude Code with strict-concise behavior injected via SessionStart
- **Autodocs:** System 2, self-updating documentation
- **Quality Gate:** Script-based check that must pass before stage advancement
- **Spec:** YAML file defining feature requirements and acceptance criteria
- **Trace:** Link from spec ID to code/test/doc locations (via @spec tags)
- **Workflow:** Staged process (Discover → Specify → Implement → Verify)
- **Stage:** Phase within a workflow (e.g., "Implement")
- **Dirty Flag:** Boolean in state.yaml indicating docs need updating

### B. References

- [PRD.md](./PRD.md) - Product Requirements Document
- [DECISIONS.md](./DECISIONS.md) - Key Architectural Decisions
- [STATUS.md](./STATUS.md) - Development Progress Tracker
- ADR-001 through ADR-007 (to be written)

### C. Version History

| Version | Date       | Author | Changes                          |
|---------|------------|--------|----------------------------------|
| 1.0     | 2025-11-01 | Team   | Initial TDD - Architecture Overview (Sections 1-5) |
| 1.1     | 2025-11-01 | Team   | Added Component Breakdown & Data Flows (Sections 6-7) |

---

**Document Status:** Sections 1-7 Complete (Architecture, Components, Data Flows)
**Next Steps:** Complete Sections 8-10 (Integration Points, Implementation Details, Quality Attributes)
**Maintained By:** Core Team
**Last Review:** 2025-11-01
