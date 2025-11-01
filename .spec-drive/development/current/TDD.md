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

*(To be completed in Step 2 - TDD Component Breakdown)*

---

## 7. DATA FLOWS

*(To be completed in Step 2 - TDD Data Flows)*

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
| 1.0     | 2025-11-01 | Team   | Initial TDD - Architecture Overview (Section 1) |

---

**Document Status:** Section 1 Complete (Architecture Overview)
**Next Steps:** Complete Sections 2-3 (Component Breakdown, Data Flows, Integration Points)
**Maintained By:** Core Team
**Last Review:** 2025-11-01
