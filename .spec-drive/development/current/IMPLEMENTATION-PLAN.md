# spec-drive v0.1 Implementation Plan

**Version:** 0.1.0
**Target Release:** TBD
**Last Updated:** 2025-11-01
**Status:** Planning Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1: Foundation](#phase-1-foundation)
3. [Phase 2: Workflows](#phase-2-workflows)
4. [Phase 3: Autodocs](#phase-3-autodocs)
5. [Phase 4: Quality Gates](#phase-4-quality-gates)
6. [Phase 5: Integration & Testing](#phase-5-integration--testing)
7. [Dependencies & Critical Path](#dependencies--critical-path)
8. [Risk Mitigation](#risk-mitigation)
9. [Success Criteria](#success-criteria)

---

## Overview

### Purpose

This implementation plan breaks down the spec-drive v0.1 development into 5 phases with specific tasks, acceptance criteria, and dependencies. Each task is designed to be:

- **Atomic**: Independently testable and committable
- **Measurable**: Clear acceptance criteria (done/not done)
- **Sequenced**: Dependencies identified to enable parallel work where possible

### Phases Summary

| Phase | Focus | Duration | Dependencies |
|-------|-------|----------|--------------|
| Phase 1 | Foundation | 1-2 weeks | None |
| Phase 2 | Workflows | 2-3 weeks | Phase 1 complete |
| Phase 3 | Autodocs | 2-3 weeks | Phase 1 complete |
| Phase 4 | Quality Gates | 1-2 weeks | Phase 2 & 3 complete |
| Phase 5 | Integration & Testing | 2-3 weeks | All phases complete |

**Total Estimated Duration:** 8-13 weeks

### Work Organization

**Branch Strategy:**
- Main branch: `main` (documentation phase)
- Development branch: `develop` (integration branch)
- Feature branches: `feature/phase-N-task-name`

**Commit Strategy:**
- Atomic commits per task
- Conventional Commits format
- Separate mechanical vs behavioral changes

**Testing Strategy:**
- Unit tests written alongside implementation
- Integration tests at end of each phase
- Manual smoke tests after each task

---

## Phase 1: Foundation

**Goal:** Build basic infrastructure (templates, directories, config management)
**Duration:** 1-2 weeks
**Prerequisites:** Documentation phase complete

### Task 1.1: Template System - Core Engine

**File:** `scripts/tools/render-template.sh`

**Description:** Create template rendering engine supporting variable substitution and AUTO markers.

**Acceptance Criteria:**
- [ ] Script accepts template path, output path, and key=value pairs
- [ ] Supports `{{VAR_NAME}}` syntax for variable substitution
- [ ] Supports `<!-- AUTO:section-name -->...<!-- /AUTO -->` markers
- [ ] Preserves manual content outside AUTO sections
- [ ] Returns error if template file not found
- [ ] Returns error if required variable missing
- [ ] Unit tests for all substitution cases

**Implementation Details:**
```bash
# Usage:
./render-template.sh \
  --template templates/docs/README.md.template \
  --output docs/README.md \
  --var PROJECT_NAME="my-app" \
  --var VERSION="0.1.0"
```

**Dependencies:** None

**Verification:**
```bash
# Test basic substitution
./render-template.sh --template test.template --output test.out --var FOO="bar"
grep "bar" test.out

# Test AUTO marker preservation
# (manual test: edit output, re-render, verify manual changes preserved outside AUTO)
```

---

### Task 1.2: Template System - Create 12 Templates

**Files:** `templates/docs/*.template`

**Description:** Create all 12 documentation templates with AUTO markers.

**Templates to Create:**

1. **README.md.template**
   - Sections: Project overview, Quick Start, Architecture (AUTO), API Reference (AUTO), Contributing
   - Variables: `{{PROJECT_NAME}}`, `{{VERSION}}`, `{{DESCRIPTION}}`

2. **ARCHITECTURE.md.template**
   - Sections: System Overview, Components (AUTO), Data Flow (AUTO), Design Decisions
   - Variables: `{{PROJECT_NAME}}`, `{{STACK_PROFILE}}`

3. **API.md.template**
   - Sections: Endpoints (AUTO), Models (AUTO), Error Codes (AUTO)
   - Variables: `{{PROJECT_NAME}}`, `{{VERSION}}`

4. **TESTING.md.template**
   - Sections: Test Strategy, Running Tests, Coverage (AUTO), Test Matrix (AUTO)
   - Variables: `{{TEST_COMMAND}}`, `{{COVERAGE_THRESHOLD}}`

5. **BUILD.md.template**
   - Sections: Prerequisites, Build Steps, CI/CD (AUTO), Deployment
   - Variables: `{{BUILD_COMMAND}}`, `{{NODE_VERSION}}`, `{{PACKAGE_MANAGER}}`

6. **CONTRIBUTING.md.template**
   - Sections: Code Style, PR Process, Quality Gates (AUTO), Commit Guidelines
   - Variables: `{{PROJECT_NAME}}`, `{{LINT_COMMAND}}`

7. **CHANGELOG.md.template**
   - Sections: Version History (AUTO), Unreleased, Format Guidelines
   - Variables: `{{VERSION}}`

8. **DECISIONS.md.template**
   - Sections: Key Decisions (AUTO), Decision Template, Decision Log
   - Variables: `{{PROJECT_NAME}}`

9. **USER-JOURNEYS.md.template**
   - Sections: Journey Map (AUTO), Personas, Use Cases (AUTO)
   - Variables: `{{PROJECT_NAME}}`

10. **WORKFLOWS.md.template**
    - Sections: Workflow Overview, app-new (AUTO), feature (AUTO), Gate Checklist (AUTO)
    - Variables: `{{PROJECT_NAME}}`, `{{ENABLED_WORKFLOWS}}`

11. **GLOSSARY.md.template**
    - Sections: Terms (AUTO), Acronyms, Domain Concepts
    - Variables: `{{PROJECT_NAME}}`

12. **TRACEABILITY.md.template**
    - Sections: Traceability Matrix (AUTO), Coverage Report (AUTO), Spec Status (AUTO)
    - Variables: `{{PROJECT_NAME}}`

**Acceptance Criteria:**
- [ ] All 12 templates created in `templates/docs/`
- [ ] Each template includes `<!-- AUTO:section -->` markers for generated content
- [ ] Each template uses `{{VAR}}` syntax for variables
- [ ] Manual sections have placeholder content
- [ ] Templates validated (no syntax errors, variables documented)
- [ ] README for templates/ explains usage and variables

**Dependencies:** Task 1.1 (template engine)

**Verification:**
```bash
# Test render all templates
for template in templates/docs/*.template; do
  ./render-template.sh --template "$template" --output "test-$(basename $template)"
done

# Verify no errors and output files created
```

---

### Task 1.3: Directory Scaffolding - .spec-drive Structure

**Files:** `scripts/tools/init-directories.sh`

**Description:** Create script to scaffold `.spec-drive/` directory structure.

**Directory Structure to Create:**
```
.spec-drive/
├── config.yaml
├── state.yaml
├── index.yaml
├── specs/
│   └── .gitkeep
├── schemas/
│   └── v0.1/
│       ├── spec-schema.json
│       ├── index-schema.json
│       ├── config-schema.json
│       └── state-schema.json
└── development/
    ├── current/
    ├── planned/
    ├── completed/
    └── archive/
```

**Note:** `assets/` folder is at plugin root level, not in `.spec-drive/`

**Acceptance Criteria:**
- [ ] Script creates all directories if they don't exist
- [ ] Script copies schemas from templates/ to .spec-drive/schemas/v0.1/
- [ ] Script copies workflow definitions to .spec-drive/assets/workflows/
- [ ] Script is idempotent (safe to run multiple times)
- [ ] Returns error if .spec-drive/ already exists with content (prevent overwrite)
- [ ] Option flag `--force` to recreate structure

**Dependencies:** Task 1.2 (templates exist)

**Verification:**
```bash
# Test fresh creation
rm -rf .spec-drive/
./init-directories.sh
test -d .spec-drive/specs
test -d .spec-drive/schemas/v0.1
test -f .spec-drive/schemas/v0.1/spec-schema.json

# Test idempotence
./init-directories.sh  # Should succeed without errors
```

---

### Task 1.4: Directory Scaffolding - docs Structure

**Files:** `scripts/tools/init-docs.sh`

**Description:** Create script to scaffold `docs/` directory structure.

**Directory Structure to Create:**
```
docs/
├── README.md
├── 10-architecture/
│   ├── ARCHITECTURE.md
│   └── diagrams/
├── 20-decisions/
│   ├── DECISIONS.md
│   └── adr/
├── 30-api/
│   └── API.md
├── 40-guides/
│   ├── CONTRIBUTING.md
│   ├── TESTING.md
│   └── BUILD.md
├── 50-workflows/
│   ├── WORKFLOWS.md
│   └── USER-JOURNEYS.md
├── 60-features/
│   └── .gitkeep
└── 90-reference/
    ├── GLOSSARY.md
    ├── CHANGELOG.md
    └── TRACEABILITY.md
```

**Acceptance Criteria:**
- [ ] Script creates all directories
- [ ] Script renders templates into docs/ (using render-template.sh)
- [ ] Script accepts variables (project name, version, etc.)
- [ ] Generated docs/ structure matches template
- [ ] Script is idempotent (checks if docs exist, asks before overwrite)
- [ ] Option flag `--archive-existing` to move old docs/ to docs-archive-{timestamp}/

**Dependencies:** Task 1.1 (template engine), Task 1.2 (templates)

**Verification:**
```bash
# Test docs generation
./init-docs.sh --var PROJECT_NAME="test-app" --var VERSION="0.1.0"
test -f docs/README.md
test -f docs/10-architecture/ARCHITECTURE.md
grep "test-app" docs/README.md

# Test archive existing
./init-docs.sh --archive-existing
test -d docs-archive-*
```

---

### Task 1.5: Config Management - config.yaml Generation

**Files:** `scripts/tools/generate-config.sh`

**Description:** Generate initial `config.yaml` from user inputs or defaults.

**config.yaml Structure:**
```yaml
project:
  name: "my-app"
  version: "0.1.0"
  stack_profile: "generic"
  description: "Example application"

behavior:
  mode: "strict-concise"
  gates_enabled: true
  auto_commit: false

autodocs:
  enabled: true
  update_frequency: "stage-boundary"
  preserve_manual_sections: true

workflows:
  enabled:
    - "app-new"
    - "feature"

tools:
  test_command: "npm test"
  lint_command: "npm run lint"
  typecheck_command: "npx tsc --noEmit"
  build_command: "npm run build"
```

**Acceptance Criteria:**
- [ ] Script prompts for project name, version, stack profile
- [ ] Script detects package.json (infer test/lint/build commands)
- [ ] Script validates config against config-schema.json
- [ ] Script writes config.yaml to .spec-drive/
- [ ] Option flag `--defaults` to skip prompts (use defaults)
- [ ] Option flag `--interactive` for step-by-step prompts

**Dependencies:** Task 1.3 (directories exist), schemas (from Task 1.2)

**Verification:**
```bash
# Test with defaults
./generate-config.sh --defaults --project-name "test-app"
yq eval '.project.name' .spec-drive/config.yaml  # Should be "test-app"

# Test validation
# (inject invalid config, verify script rejects it)
```

---

### Task 1.6: Config Management - state.yaml Initialization

**Files:** `scripts/tools/init-state.sh`

**Description:** Create initial state.yaml with default values.

**state.yaml Structure:**
```yaml
current_workflow: null
current_spec: null
current_stage: null
can_advance: false
dirty: false

workflows: {}

meta:
  initialized: "2025-11-01T09:00:00Z"
  last_gate_run: null
  last_autodocs_run: null
```

**Acceptance Criteria:**
- [ ] Script creates state.yaml with default values
- [ ] Script sets `meta.initialized` to current ISO 8601 timestamp
- [ ] Script validates state against state-schema.json
- [ ] Script returns error if state.yaml already exists (prevent overwrite)
- [ ] Option flag `--reset` to reinitialize existing state

**Dependencies:** Task 1.3 (directories), schemas

**Verification:**
```bash
# Test initialization
./init-state.sh
test -f .spec-drive/state.yaml
yq eval '.current_workflow' .spec-drive/state.yaml  # Should be "null"

# Test validation
ajv validate -s .spec-drive/schemas/v0.1/state-schema.json \
              -d .spec-drive/state.yaml
```

---

### Task 1.7: Config Management - index.yaml Skeleton

**Files:** `scripts/tools/init-index.sh`

**Description:** Create initial index.yaml skeleton (empty arrays).

**index.yaml Structure:**
```yaml
meta:
  generated: "2025-11-01T10:00:00Z"
  version: "0.1.0"
  project_name: "my-app"

components: []
specs: []
docs: []
code: []
```

**Acceptance Criteria:**
- [ ] Script creates index.yaml skeleton
- [ ] Script reads project name/version from config.yaml
- [ ] Script sets `meta.generated` to current ISO 8601 timestamp
- [ ] Script validates index against index-schema.json
- [ ] Script is idempotent (regenerates with current timestamp)

**Dependencies:** Task 1.5 (config.yaml exists), schemas

**Verification:**
```bash
# Test initialization
./init-index.sh
test -f .spec-drive/index.yaml
yq eval '.meta.project_name' .spec-drive/index.yaml  # Should match config

# Test validation
ajv validate -s .spec-drive/schemas/v0.1/index-schema.json \
              -d .spec-drive/index.yaml
```

---

### Task 1.8: Hook System - SessionStart (Behavior Injection)

**Files:**
- `hooks/hooks.json`
- `hooks-handlers/session-start.sh`
- `assets/strict-concise-behavior.md`

**Description:** Implement SessionStart hook for automatic behavior prompt injection following the `explanatory-output-style` plugin pattern.

**hooks/hooks.json Structure:**
```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/session-start.sh"
      }]
    }]
  }
}
```

**hooks-handlers/session-start.sh Logic:**
```bash
#!/bin/bash
BEHAVIOR_FILE="${CLAUDE_PLUGIN_ROOT}/assets/strict-concise-behavior.md"
BEHAVIOR_CONTENT=$(cat "$BEHAVIOR_FILE")

cat << EOF
{
  "hookEventName": "SessionStart",
  "additionalContext": $(echo "$BEHAVIOR_CONTENT" | jq -Rs .)
}
EOF
```

**assets/strict-concise-behavior.md Content:**
- Strict-concise v3.0 behavior prompt
- Quality gates enforcement
- Extreme planning requirements
- Docs-first enforcement
- Zero shortcuts policy

**Acceptance Criteria:**
- [ ] `hooks/hooks.json` created with SessionStart configuration
- [ ] `hooks-handlers/session-start.sh` created and executable
- [ ] `assets/strict-concise-behavior.md` created with full behavior prompt
- [ ] Hook returns valid JSON format
- [ ] Hook execution completes <100ms
- [ ] Behavior prompt loads into Claude Code sessions automatically
- [ ] Test: Start new session, verify behavior active

**Dependencies:** None (foundation component)

**Verification:**
```bash
# Test hook script directly
./hooks-handlers/session-start.sh | jq '.'  # Valid JSON

# Test hook execution time
time ./hooks-handlers/session-start.sh  # <100ms

# Test in Claude Code session (manual)
# Start session, check if behavior instructions active
```

---

### Phase 1 Exit Criteria

**All tasks 1.1-1.8 complete:**
- [ ] Template rendering system working
- [ ] 12 documentation templates created and validated
- [ ] Directory scaffolding scripts (init-directories.sh, init-docs.sh) working
- [ ] Config generation (generate-config.sh) working
- [ ] State initialization (init-state.sh) working
- [ ] Index skeleton (init-index.sh) working
- [ ] All scripts have unit tests
- [ ] Manual smoke test: Fresh project initialization end-to-end
- [ ] All commits follow conventional commits
- [ ] Phase 1 documentation updated (README, usage examples)

**Deliverables:**
- Working infrastructure scripts in `scripts/tools/`
- Complete template library in `templates/docs/`
- Test suite for all scripts
- Documentation for script usage

---

## Phase 2: Workflows

**Goal:** Implement app-new and feature workflows with state management
**Duration:** 2-3 weeks
**Prerequisites:** Phase 1 complete

### Task 2.1: Workflow State Machine - Core Logic

**Files:** `scripts/workflows/workflow-engine.sh`

**Description:** Create workflow state machine that manages stage transitions.

**State Machine:**
```
[NULL] → app-new/feature → [discover] → [specify] → [implement] → [verify] → [done]
                              ↑____________↓ (gates control transitions)
```

**Functions to Implement:**
```bash
workflow_start()    # Initialize workflow, set current_workflow/spec/stage
workflow_advance()  # Move to next stage (check can_advance first)
workflow_complete() # Mark workflow done, reset current_*, add to history
workflow_abandon()  # Mark workflow abandoned, reset state
workflow_status()   # Print current workflow status
```

**Acceptance Criteria:**
- [ ] Functions read/write state.yaml atomically (temp file + mv)
- [ ] `workflow_start` validates spec ID format (SPEC-ID regex)
- [ ] `workflow_advance` checks `can_advance` flag (blocks if false)
- [ ] `workflow_complete` adds entry to `workflows` history
- [ ] `workflow_abandon` sets status to "abandoned"
- [ ] `workflow_status` prints human-readable status
- [ ] All state mutations validate against state-schema.json
- [ ] Unit tests for all state transitions

**Dependencies:** Phase 1 (state.yaml exists)

**Verification:**
```bash
# Test workflow lifecycle
./workflow_start.sh --workflow feature --spec AUTH-001
yq eval '.current_spec' .spec-drive/state.yaml  # AUTH-001

./workflow_advance.sh --stage specify
yq eval '.current_stage' .spec-drive/state.yaml  # specify

./workflow_complete.sh
yq eval '.workflows.AUTH-001.status' .spec-drive/state.yaml  # done
```

---

### Task 2.2: app-new Workflow - Planning Session

**Files:** `scripts/workflows/app-new/planning-session.sh`

**Description:** Implement app-new planning session (prompts user for project vision).

**Planning Session Flow:**
1. Prompt: "What are you building?" → `PROJECT_VISION`
2. Prompt: "Key features?" → `KEY_FEATURES` (bullet list)
3. Prompt: "Target users?" → `TARGET_USERS`
4. Prompt: "Tech stack?" → `TECH_STACK`
5. Generate APP-001 spec from inputs
6. Render all 12 docs using templates + planning inputs

**Acceptance Criteria:**
- [ ] Script prompts user for inputs (or accepts --var flags)
- [ ] Script validates inputs (non-empty, reasonable length)
- [ ] Script creates APP-001 spec in .spec-drive/specs/APP-001.yaml
- [ ] Script renders all docs/ using planning inputs
- [ ] Script updates index.yaml with APP-001 spec entry
- [ ] Script sets state: workflow=app-new, spec=APP-001, stage=discover
- [ ] Generated docs pass quality checks (no [NEEDS CLARIFICATION])

**Dependencies:** Task 2.1 (workflow engine), Phase 1 (templates, directories)

**Verification:**
```bash
# Test planning session
./planning-session.sh --interactive
test -f .spec-drive/specs/APP-001.yaml
test -f docs/README.md
grep "PROJECT_VISION" docs/README.md
```

---

### Task 2.3: app-new Workflow - Doc Generation

**Files:** `scripts/workflows/app-new/generate-docs.sh`

**Description:** Generate all docs/ structure from APP-001 spec and planning inputs.

**Docs to Generate:**
1. README.md (project overview)
2. ARCHITECTURE.md (high-level design)
3. API.md (placeholder, to be filled in feature workflows)
4. TESTING.md (test strategy)
5. BUILD.md (build instructions)
6. CONTRIBUTING.md (contribution guidelines)
7. CHANGELOG.md (initial version)
8. DECISIONS.md (initial decisions)
9. USER-JOURNEYS.md (personas, use cases)
10. WORKFLOWS.md (workflow overview)
11. GLOSSARY.md (domain terms)
12. TRACEABILITY.md (spec tracking)

**Acceptance Criteria:**
- [ ] Script renders all 12 docs using render-template.sh
- [ ] Script populates AUTO sections with planning data
- [ ] Script updates index.yaml docs[] array with all generated docs
- [ ] Generated docs pass spell check (no typos in generated content)
- [ ] Script sets dirty flag to false (docs in sync)

**Dependencies:** Task 2.2 (planning session data available)

**Verification:**
```bash
# Test doc generation
./generate-docs.sh --spec APP-001
test -f docs/README.md
test -f docs/10-architecture/ARCHITECTURE.md
# ... (check all 12 docs exist)
```

---

### Task 2.4: app-new Workflow - Command Integration

**Files:** `scripts/commands/spec-drive-app-new.sh`

**Description:** Create `/spec-drive:app-new` command that orchestrates planning + docs.

**Command Flow:**
1. Check: No active workflow (state.current_workflow = null)
2. Run: planning-session.sh (creates APP-001)
3. Run: generate-docs.sh (creates docs/)
4. Set state: workflow=app-new, spec=APP-001, stage=discover
5. Print: Next steps (run /spec-drive:feature to start building)

**Acceptance Criteria:**
- [ ] Command checks prerequisites (no active workflow)
- [ ] Command orchestrates planning + docs generation
- [ ] Command updates state correctly
- [ ] Command prints clear next steps
- [ ] Command handles errors gracefully (rollback on failure)
- [ ] Command respects --dry-run flag (preview without writing)

**Dependencies:** Tasks 2.2, 2.3

**Verification:**
```bash
# Test end-to-end app-new
./spec-drive-app-new.sh --project-name "test-app"
test -f .spec-drive/specs/APP-001.yaml
test -d docs/
yq eval '.current_spec' .spec-drive/state.yaml  # APP-001
```

---

### Task 2.5: feature Workflow - 4-Stage Orchestration

**Files:** `scripts/workflows/feature/feature-orchestrator.sh`

**Description:** Implement feature workflow state machine with 4 stages.

**Stages:**
1. **Discover** - Requirements gathering, create spec YAML
2. **Specify** - Define acceptance criteria, design decisions
3. **Implement** - Write code, tests, add @spec tags
4. **Verify** - Run gates, update docs, complete traceability

**Orchestrator Responsibilities:**
- Track current stage
- Run appropriate gate before stage transition
- Update state.yaml on each transition
- Trigger autodocs at stage boundaries (if dirty flag set)
- Enforce serial workflow (one spec at a time)

**Acceptance Criteria:**
- [ ] Orchestrator enforces stage order (discover → specify → implement → verify → done)
- [ ] Orchestrator runs gates before advancing (blocks if gate fails)
- [ ] Orchestrator triggers autodocs after each stage (if dirty=true)
- [ ] Orchestrator updates state.yaml atomically on each transition
- [ ] Orchestrator prints clear status at each stage
- [ ] Orchestrator handles abandonment (user cancels workflow)

**Dependencies:** Task 2.1 (workflow engine)

**Verification:**
```bash
# Test stage transitions
./feature-orchestrator.sh --spec AUTH-001 --stage discover
# ... (implement spec, advance through stages)
./feature-orchestrator.sh --advance
yq eval '.current_stage' .spec-drive/state.yaml  # specify
```

---

### Task 2.6: feature Workflow - Discover Stage

**Files:** `scripts/workflows/feature/stages/discover.sh`

**Description:** Implement discover stage (requirements gathering, spec creation).

**Discover Stage Activities:**
1. User describes feature (via prompts or --description)
2. Script creates SPEC-ID (e.g., AUTH-001, PROFILE-002)
3. Script creates skeleton spec YAML in .spec-drive/specs/
4. Script prompts for summary, dependencies, risks
5. Script validates spec against spec-schema.json
6. Script sets state: stage=discover, current_spec=SPEC-ID
7. Script prints: "Next: Add acceptance criteria (run /spec-drive:feature --advance)"

**Acceptance Criteria:**
- [ ] Script generates unique SPEC-ID (checks existing specs)
- [ ] Script creates valid spec YAML (passes schema validation)
- [ ] Script prompts for all required fields (summary, title)
- [ ] Script allows optional fields (dependencies, risks, tags)
- [ ] Script updates index.yaml specs[] array
- [ ] Script sets state correctly (stage=discover)

**Dependencies:** Phase 1 (spec schema), Task 2.5 (orchestrator)

**Verification:**
```bash
# Test discover stage
./discover.sh --title "User authentication" --summary "Email/password login"
test -f .spec-drive/specs/AUTH-001.yaml
yq eval '.id' .spec-drive/specs/AUTH-001.yaml  # AUTH-001
```

---

### Task 2.7: feature Workflow - Specify Stage

**Files:** `scripts/workflows/feature/stages/specify.sh`

**Description:** Implement specify stage (acceptance criteria definition).

**Specify Stage Activities:**
1. User adds acceptance criteria to spec YAML (manual or assisted)
2. Script validates each criterion (testable=true/false)
3. Script checks for [NEEDS CLARIFICATION] markers
4. Script runs gate-1 (checks spec completeness)
5. If gate passes: set can_advance=true
6. Script prints: "Next: Implement feature (run /spec-drive:feature --advance)"

**Acceptance Criteria:**
- [ ] Script reads spec YAML, displays current acceptance_criteria
- [ ] Script allows adding/editing criteria (interactive mode)
- [ ] Script validates each criterion (non-empty, clear language)
- [ ] Script runs gate-1 automatically (blocks advance if fails)
- [ ] Script updates spec YAML with new criteria
- [ ] Script sets can_advance based on gate result

**Dependencies:** Task 2.6 (discover stage), Phase 4 (gate-1 script)

**Verification:**
```bash
# Test specify stage
./specify.sh --spec AUTH-001 --add-criterion "User can log in with email/password"
yq eval '.acceptance_criteria | length' .spec-drive/specs/AUTH-001.yaml  # >= 1

# Test gate-1 integration
./specify.sh --run-gate
yq eval '.can_advance' .spec-drive/state.yaml  # true (if gate passes)
```

---

### Task 2.8: feature Workflow - Implement Stage

**Files:** `scripts/workflows/feature/stages/implement.sh`

**Description:** Implement stage helper (guides implementation, tracks progress).

**Implement Stage Activities:**
1. Script displays acceptance criteria checklist
2. User implements code + tests (manual work)
3. Script reminds user to add @spec tags
4. Script runs periodic checks (tests pass? lint clean?)
5. User signals "ready for verification"
6. Script runs gate-3 (code complete, @spec tags present, tests pass)
7. If gate passes: set can_advance=true

**Acceptance Criteria:**
- [ ] Script displays acceptance criteria as checklist
- [ ] Script provides @spec tag examples for detected languages
- [ ] Script runs `test_command` and `lint_command` from config
- [ ] Script scans for @spec tags (warns if missing)
- [ ] Script runs gate-3 automatically when user signals ready
- [ ] Script sets can_advance based on gate result

**Dependencies:** Task 2.7 (specify stage), Phase 4 (gate-3 script)

**Verification:**
```bash
# Test implement stage
./implement.sh --spec AUTH-001 --check-progress
# (mock: create test files with @spec tags)
./implement.sh --spec AUTH-001 --run-gate
yq eval '.can_advance' .spec-drive/state.yaml  # true (if tests pass, tags present)
```

---

### Task 2.9: feature Workflow - Verify Stage

**Files:** `scripts/workflows/feature/stages/verify.sh`

**Description:** Implement verify stage (final checks, docs update, completion).

**Verify Stage Activities:**
1. Script runs gate-4 (docs updated, no TODOs, traceability complete)
2. Script triggers autodocs if dirty flag set
3. Script validates traceability (spec ↔ code ↔ tests ↔ docs)
4. If gate passes: mark workflow complete
5. Script moves spec status: verified → done
6. Script prints completion summary (files changed, tests added, docs updated)

**Acceptance Criteria:**
- [ ] Script runs gate-4 automatically
- [ ] Script triggers autodocs (runs index-docs + update-docs)
- [ ] Script validates traceability (checks index.yaml)
- [ ] Script marks spec status=done in spec YAML
- [ ] Script adds workflow entry to state.yaml history
- [ ] Script resets current_* fields (workflow complete)
- [ ] Script prints completion report

**Dependencies:** Task 2.8 (implement stage), Phase 3 (autodocs), Phase 4 (gate-4)

**Verification:**
```bash
# Test verify stage
./verify.sh --spec AUTH-001
yq eval '.workflows.AUTH-001.status' .spec-drive/state.yaml  # done
yq eval '.current_workflow' .spec-drive/state.yaml  # null
```

---

### Task 2.10: feature Workflow - Command Integration

**Files:** `scripts/commands/spec-drive-feature.sh`

**Description:** Create `/spec-drive:feature` command that orchestrates 4-stage workflow.

**Command Modes:**
1. **Start** - `./spec-drive-feature.sh --start --title "Feature name"`
   - Runs discover stage, creates spec
2. **Advance** - `./spec-drive-feature.sh --advance`
   - Moves to next stage (checks can_advance)
3. **Status** - `./spec-drive-feature.sh --status`
   - Prints current workflow state
4. **Abandon** - `./spec-drive-feature.sh --abandon`
   - Marks workflow abandoned, resets state

**Acceptance Criteria:**
- [ ] Command supports all 4 modes (start, advance, status, abandon)
- [ ] Command delegates to appropriate stage scripts
- [ ] Command checks prerequisites (e.g., no active workflow for --start)
- [ ] Command enforces can_advance flag (blocks --advance if false)
- [ ] Command prints clear error messages and next steps
- [ ] Command integrates with workflow engine (state management)

**Dependencies:** Tasks 2.6-2.9 (all stages)

**Verification:**
```bash
# Test end-to-end feature workflow
./spec-drive-feature.sh --start --title "User auth"
./spec-drive-feature.sh --advance  # discover → specify
./spec-drive-feature.sh --advance  # specify → implement
# (implement code + tests)
./spec-drive-feature.sh --advance  # implement → verify
./spec-drive-feature.sh --advance  # verify → done
yq eval '.workflows.AUTH-001.status' .spec-drive/state.yaml  # done
```

---

### Phase 2 Exit Criteria

**All tasks 2.1-2.10 complete:**
- [ ] Workflow state machine (workflow-engine.sh) working
- [ ] app-new workflow complete (planning, docs generation)
- [ ] feature workflow complete (4 stages: discover, specify, implement, verify)
- [ ] Commands integrated (/spec-drive:app-new, /spec-drive:feature)
- [ ] State management working (state.yaml updates atomically)
- [ ] All workflow scripts have unit tests
- [ ] Manual smoke test: Full app-new + feature workflow end-to-end
- [ ] Integration test: Multiple features in sequence
- [ ] Phase 2 documentation updated

**Deliverables:**
- Working workflow scripts in `scripts/workflows/`
- Commands in `scripts/commands/`
- Test suite for all workflows
- Workflow documentation (USER-JOURNEYS.md, WORKFLOWS.md)

---

## Phase 3: Autodocs

**Goal:** Self-updating documentation system (code analysis, index generation, doc updates)
**Duration:** 2-3 weeks
**Prerequisites:** Phase 1 complete (parallel with Phase 2)

### Task 3.1: Code Analysis - Component Detection

**Files:** `scripts/autodocs/analyze-code.js`

**Description:** Analyze codebase, detect components (classes, functions, services).

**Component Detection Logic:**
- **JavaScript/TypeScript**: `class`, `export function`, `export const`
- **Python**: `class`, `def` (module level)
- **Go**: `type X struct`, `func`
- **Generic**: File-level detection (one component per file fallback)

**Output Format (JSON):**
```json
{
  "components": [
    {
      "id": "auth-service",
      "type": "class",
      "path": "src/auth/AuthService.ts:15",
      "name": "AuthService",
      "summary": "Handles user authentication",
      "dependencies": ["database-client", "jwt-utils"]
    }
  ]
}
```

**Acceptance Criteria:**
- [ ] Script accepts source directories (e.g., `src/`, `lib/`)
- [ ] Script detects components in supported languages (TS, JS, Py, Go)
- [ ] Script generates unique component IDs (kebab-case)
- [ ] Script infers dependencies (import statements)
- [ ] Script generates summary (first JSDoc comment or function name)
- [ ] Script outputs JSON (components array)
- [ ] Unit tests for all language parsers

**Dependencies:** Phase 1 (index schema defines component structure)

**Verification:**
```bash
# Test component detection
./analyze-code.js --dir src/ > components.json
jq '.components | length' components.json  # > 0
jq '.components[0].id' components.json  # "some-component-id"
```

---

### Task 3.2: Code Analysis - @spec Tag Detection

**Files:** `scripts/autodocs/scan-spec-tags.js`

**Description:** Scan codebase for @spec tags, build traceability map.

**@spec Tag Formats:**
```typescript
// TypeScript/JavaScript
/** @spec AUTH-001 */

// Python
"""@spec AUTH-001"""

// Go
// @spec AUTH-001
```

**Output Format (JSON):**
```json
{
  "traces": {
    "AUTH-001": {
      "code": ["src/auth/login.ts:42", "src/auth/session.ts:18"],
      "tests": ["tests/auth/login.test.ts:12"]
    }
  }
}
```

**Acceptance Criteria:**
- [ ] Script scans all source and test files
- [ ] Script detects @spec tags in comments (all formats)
- [ ] Script extracts SPEC-ID from tag (validates format)
- [ ] Script records file:line for each tag
- [ ] Script distinguishes code vs tests (path-based heuristic)
- [ ] Script outputs JSON (traces object)
- [ ] Unit tests for all tag formats

**Dependencies:** Task 3.1 (component detection)

**Verification:**
```bash
# Test @spec tag detection
echo '/** @spec AUTH-001 */' > test.ts
./scan-spec-tags.js --dir . > traces.json
jq '.traces."AUTH-001".code | length' traces.json  # 1
```

---

### Task 3.3: Code Analysis - Dependency Mapping

**Files:** `scripts/autodocs/map-dependencies.js`

**Description:** Build component dependency graph from import statements.

**Dependency Detection Logic:**
- Parse `import` / `require` (JS/TS)
- Parse `import` (Python)
- Parse `import` (Go)
- Map imported modules to detected components

**Output Format (JSON):**
```json
{
  "dependencies": {
    "auth-service": ["database-client", "jwt-utils"],
    "user-repository": ["database-client"]
  }
}
```

**Acceptance Criteria:**
- [ ] Script parses import statements (all supported languages)
- [ ] Script resolves imports to component IDs
- [ ] Script builds dependency map (component → [dependencies])
- [ ] Script detects circular dependencies (warns)
- [ ] Script outputs JSON (dependencies object)

**Dependencies:** Task 3.1 (components detected)

**Verification:**
```bash
# Test dependency mapping
./map-dependencies.js --dir src/ > deps.json
jq '.dependencies."auth-service" | length' deps.json  # > 0
```

---

### Task 3.4: DocIndexAgent - Index Population

**Files:** `scripts/autodocs/index-docs.js`

**Description:** Populate index.yaml with components, specs, docs, code.

**Index Population Steps:**
1. Run analyze-code.js → get components
2. Run scan-spec-tags.js → get traces
3. Run map-dependencies.js → get dependencies
4. Read all specs from .spec-drive/specs/ → get specs
5. Scan docs/ → get doc files
6. Merge all data into index.yaml

**index.yaml Structure:**
```yaml
meta:
  generated: "2025-11-01T10:00:00Z"
  version: "0.1.0"
  project_name: "my-app"

components:
  - id: "auth-service"
    type: "class"
    path: "src/auth/AuthService.ts:15"
    summary: "Handles user authentication"
    dependencies: ["database-client"]

specs:
  - id: "AUTH-001"
    title: "User authentication"
    status: "implemented"
    trace:
      code: ["src/auth/login.ts:42"]
      tests: ["tests/auth/login.test.ts:12"]
      docs: ["docs/60-features/AUTH-001.md"]

docs:
  - path: "docs/README.md"
    type: "overview"
    summary: "Project overview"

code:
  - path: "src/auth/login.ts"
    components: ["auth-service"]
    specs: ["AUTH-001"]
    summary: "User login implementation"
```

**Acceptance Criteria:**
- [ ] Script runs all analysis scripts (components, traces, deps)
- [ ] Script reads all specs from .spec-drive/specs/
- [ ] Script scans docs/ for markdown files
- [ ] Script merges data into index.yaml structure
- [ ] Script validates output against index-schema.json
- [ ] Script writes index.yaml atomically
- [ ] Script sets meta.generated to current timestamp

**Dependencies:** Tasks 3.1, 3.2, 3.3 (analysis scripts)

**Verification:**
```bash
# Test index population
./index-docs.js
test -f .spec-drive/index.yaml
yq eval '.components | length' .spec-drive/index.yaml  # > 0
yq eval '.specs | length' .spec-drive/index.yaml  # > 0

# Validate schema
ajv validate -s .spec-drive/schemas/v0.1/index-schema.json \
              -d .spec-drive/index.yaml
```

---

### Task 3.5: DocUpdateAgent - AUTO Section Regeneration

**Files:** `scripts/autodocs/update-docs.js`

**Description:** Regenerate AUTO sections in docs/ from index.yaml data.

**AUTO Sections to Update:**
1. **README.md**
   - `<!-- AUTO:components -->` → Component list from index.yaml
2. **ARCHITECTURE.md**
   - `<!-- AUTO:components -->` → Component details
   - `<!-- AUTO:dataflow -->` → Data flow (inferred from dependencies)
3. **API.md**
   - `<!-- AUTO:endpoints -->` → API routes (from code analysis)
4. **TRACEABILITY.md**
   - `<!-- AUTO:matrix -->` → Spec → Code/Tests/Docs table

**Update Algorithm:**
1. Read doc file
2. Find `<!-- AUTO:section -->...<!-- /AUTO -->` markers
3. Regenerate content from index.yaml
4. Replace content between markers (preserve manual content outside)
5. Write doc file atomically

**Acceptance Criteria:**
- [ ] Script reads index.yaml
- [ ] Script updates all AUTO sections in all docs
- [ ] Script preserves manual content outside AUTO markers
- [ ] Script formats generated content (markdown tables, lists)
- [ ] Script handles missing AUTO markers gracefully (warns)
- [ ] Script validates updated docs (no broken links)
- [ ] Script clears dirty flag in state.yaml after successful update

**Dependencies:** Task 3.4 (index.yaml populated)

**Verification:**
```bash
# Test doc update
./update-docs.js
grep "auth-service" docs/README.md  # Component appears in AUTO section

# Test preservation of manual content
echo "Manual section" >> docs/README.md
./update-docs.js
grep "Manual section" docs/README.md  # Still present
```

---

### Task 3.6: Autodocs - Trigger Mechanism (PostToolUse Hook)

**Files:** `.claude/hooks/posttool`

**Description:** Hook that sets dirty flag when code/docs change.

**Hook Logic:**
```bash
#!/bin/bash
# PostToolUse hook - runs after every tool call

TOOL_NAME="$1"  # Tool that was just called

# Tools that modify code/docs → set dirty flag
if [[ "$TOOL_NAME" =~ ^(Write|Edit|Delete)$ ]]; then
  yq eval '.dirty = true' -i .spec-drive/state.yaml
fi
```

**Acceptance Criteria:**
- [ ] Hook detects Write/Edit/Delete tool calls
- [ ] Hook sets dirty flag in state.yaml
- [ ] Hook runs efficiently (<100ms)
- [ ] Hook handles missing state.yaml gracefully (no error)
- [ ] Hook is executable (chmod +x)

**Dependencies:** Phase 1 (state.yaml exists)

**Verification:**
```bash
# Test hook
yq eval '.dirty = false' -i .spec-drive/state.yaml
# (simulate Write tool call)
.claude/hooks/posttool Write
yq eval '.dirty' .spec-drive/state.yaml  # true
```

---

### Task 3.7: Autodocs - Stage Boundary Trigger

**Files:** `scripts/autodocs/run-autodocs.sh`

**Description:** Wrapper script that runs autodocs at stage boundaries.

**Autodocs Flow:**
1. Check dirty flag in state.yaml
2. If dirty=false: skip (docs already in sync)
3. If dirty=true:
   - Run index-docs.js (rebuild index.yaml)
   - Run update-docs.js (regenerate AUTO sections)
   - Set dirty=false
   - Set meta.last_autodocs_run to current timestamp

**Acceptance Criteria:**
- [ ] Script checks dirty flag
- [ ] Script runs index-docs + update-docs sequentially
- [ ] Script clears dirty flag after successful run
- [ ] Script updates meta.last_autodocs_run
- [ ] Script handles errors gracefully (does not clear dirty if failed)
- [ ] Script prints summary (files updated, sections regenerated)

**Dependencies:** Tasks 3.4, 3.5 (index-docs, update-docs)

**Verification:**
```bash
# Test autodocs trigger
yq eval '.dirty = true' -i .spec-drive/state.yaml
./run-autodocs.sh
yq eval '.dirty' .spec-drive/state.yaml  # false
yq eval '.meta.last_autodocs_run' .spec-drive/state.yaml  # recent timestamp
```

---

### Task 3.8: Autodocs - Existing Project Initialization

**Files:** `scripts/autodocs/init-existing-project.sh`

**Description:** Deep analysis + doc generation for existing codebases.

**Existing Project Init Flow:**
1. Check: docs/ exists?
   - If yes: Prompt to archive (mv docs/ docs-archive-{timestamp}/)
2. Run deep code analysis (all languages, all files)
3. Generate specs for major components (auto-generate COMP-NNN specs)
4. Generate full docs/ structure (12 docs)
5. Build index.yaml from analysis
6. Print summary (components found, specs generated, docs created)

**Acceptance Criteria:**
- [ ] Script archives existing docs/ (with user confirmation)
- [ ] Script runs comprehensive code analysis
- [ ] Script generates specs for detected components
- [ ] Script generates all 12 docs from templates
- [ ] Script populates AUTO sections with analysis data
- [ ] Script builds complete index.yaml
- [ ] Script sets config (infer test/lint commands from package.json/setup.py)
- [ ] Script prints detailed summary

**Dependencies:** Tasks 3.1-3.5 (analysis + index + update)

**Verification:**
```bash
# Test existing project init
./init-existing-project.sh --project-name "legacy-app"
test -d docs-archive-*  # Old docs archived
test -d docs/
test -f .spec-drive/index.yaml
yq eval '.components | length' .spec-drive/index.yaml  # > 0
```

---

### Phase 3 Exit Criteria

**All tasks 3.1-3.8 complete:**
- [ ] Code analysis scripts (components, @spec tags, dependencies) working
- [ ] DocIndexAgent (index-docs.js) populates index.yaml
- [ ] DocUpdateAgent (update-docs.js) regenerates AUTO sections
- [ ] PostToolUse hook sets dirty flag
- [ ] Stage boundary trigger (run-autodocs.sh) runs autodocs
- [ ] Existing project init (init-existing-project.sh) working
- [ ] All autodocs scripts have unit tests
- [ ] Manual smoke test: Change code, trigger autodocs, verify docs updated
- [ ] Integration test: Existing project init on sample codebase
- [ ] Phase 3 documentation updated

**Deliverables:**
- Working autodocs scripts in `scripts/autodocs/`
- Hooks in `.claude/hooks/`
- Test suite for all autodocs
- Autodocs documentation

---

## Phase 4: Quality Gates

**Goal:** Automated gate enforcement (4 gates: specify, architect, implement, verify)
**Duration:** 1-2 weeks
**Prerequisites:** Phase 2 (workflows) & Phase 3 (autodocs) complete

### Task 4.1: Gate Infrastructure - Gate Runner

**Files:** `scripts/gates/run-gate.sh`

**Description:** Generic gate runner that executes gate scripts and records results.

**Gate Runner Responsibilities:**
- Execute gate script (gate-1.sh, gate-2.sh, etc.)
- Capture exit code (0 = pass, 1 = fail)
- Parse gate output (failure reasons)
- Update state.yaml:
  - `can_advance` = true/false
  - `workflows.{SPEC}.gates.{gate-N}` = {passed, timestamp, failures[]}
  - `meta.last_gate_run` = current timestamp
- Print summary (passed/failed, reasons)

**Acceptance Criteria:**
- [ ] Script accepts gate number (1-4) and spec ID
- [ ] Script executes gate script (e.g., scripts/gates/gate-1.sh)
- [ ] Script captures exit code and output
- [ ] Script parses failures (expects one failure reason per line)
- [ ] Script updates state.yaml atomically
- [ ] Script sets can_advance flag based on result
- [ ] Script prints clear pass/fail summary

**Dependencies:** Phase 2 (state.yaml workflow tracking)

**Verification:**
```bash
# Test gate runner
./run-gate.sh --gate 1 --spec AUTH-001
yq eval '.workflows.AUTH-001.gates.gate-1.passed' .spec-drive/state.yaml  # true/false
yq eval '.can_advance' .spec-drive/state.yaml  # true/false
```

---

### Task 4.2: Gate 1 - Discover → Specify Transition

**Files:** `scripts/gates/gate-1.sh`

**Description:** Validate spec completeness before moving to specify stage.

**Gate 1 Checks:**
1. Spec file exists (.spec-drive/specs/{SPEC-ID}.yaml)
2. Spec validates against spec-schema.json
3. Required fields present (id, title, summary, acceptance_criteria)
4. No [NEEDS CLARIFICATION] markers in spec
5. acceptance_criteria array has at least 1 criterion
6. All criteria are well-formed (criterion, testable fields present)

**Exit Code:**
- `0` if all checks pass
- `1` if any check fails (print failure reasons to stdout)

**Acceptance Criteria:**
- [ ] Script checks spec file exists
- [ ] Script validates spec against schema (ajv or yq)
- [ ] Script checks for [NEEDS CLARIFICATION] markers
- [ ] Script validates acceptance_criteria array
- [ ] Script prints clear failure reasons (one per line)
- [ ] Script exits with appropriate code

**Dependencies:** Phase 1 (spec-schema.json)

**Verification:**
```bash
# Test gate-1 pass
./gate-1.sh --spec AUTH-001
echo $?  # 0 (pass)

# Test gate-1 fail (invalid spec)
yq eval '.acceptance_criteria = []' -i .spec-drive/specs/AUTH-001.yaml
./gate-1.sh --spec AUTH-001
echo $?  # 1 (fail)
# Output: "acceptance_criteria array is empty"
```

---

### Task 4.3: Gate 2 - Specify → Implement Transition

**Files:** `scripts/gates/gate-2.sh`

**Description:** Validate acceptance criteria quality before implementation.

**Gate 2 Checks:**
1. All gate-1 checks pass (call gate-1.sh)
2. All acceptance criteria marked as testable or have notes explaining why not
3. No vague criteria (e.g., "system works", "it's good")
4. Criteria are specific (Given/When/Then format encouraged)
5. Dependencies declared (if any) exist as specs
6. Risks documented (at least 1 risk per spec)

**Exit Code:**
- `0` if all checks pass
- `1` if any check fails

**Acceptance Criteria:**
- [ ] Script runs gate-1 first (delegates)
- [ ] Script validates testable flag on all criteria
- [ ] Script checks for vague language (heuristics)
- [ ] Script validates dependencies (refs to existing specs)
- [ ] Script checks risks array (at least 1 risk recommended)
- [ ] Script prints clear failure reasons

**Dependencies:** Task 4.2 (gate-1)

**Verification:**
```bash
# Test gate-2 pass
./gate-2.sh --spec AUTH-001
echo $?  # 0

# Test gate-2 fail (vague criterion)
yq eval '.acceptance_criteria[0].criterion = "it works"' -i .spec-drive/specs/AUTH-001.yaml
./gate-2.sh --spec AUTH-001
echo $?  # 1
# Output: "Criterion 'it works' is too vague"
```

---

### Task 4.4: Gate 3 - Implement → Verify Transition

**Files:** `scripts/gates/gate-3.sh`

**Description:** Validate implementation completeness before verification.

**Gate 3 Checks:**
1. Tests pass (run `config.tools.test_command`)
2. Lint passes (run `config.tools.lint_command`)
3. Type check passes (run `config.tools.typecheck_command` if set)
4. @spec tags present in code (at least 1 tag matching SPEC-ID)
5. @spec tags present in tests (at least 1 test tagged)
6. No TODO or console.log in changed files (scan git diff)
7. No commented-out code blocks (heuristics)

**Exit Code:**
- `0` if all checks pass
- `1` if any check fails

**Acceptance Criteria:**
- [ ] Script reads test/lint/typecheck commands from config.yaml
- [ ] Script runs all commands, captures exit codes
- [ ] Script scans for @spec tags (uses scan-spec-tags.js)
- [ ] Script checks for TODO/console.log (grep in git diff)
- [ ] Script checks for commented code (heuristics)
- [ ] Script prints clear failure reasons
- [ ] Script respects config.behavior.gates_enabled (skip if disabled)

**Dependencies:** Task 3.2 (scan-spec-tags), Phase 1 (config.yaml)

**Verification:**
```bash
# Test gate-3 pass
./gate-3.sh --spec AUTH-001
echo $?  # 0

# Test gate-3 fail (tests fail)
# (mock: create failing test)
./gate-3.sh --spec AUTH-001
echo $?  # 1
# Output: "Tests failed: 1 test failed"
```

---

### Task 4.5: Gate 4 - Verify → Done Transition

**Files:** `scripts/gates/gate-4.sh`

**Description:** Validate final quality before marking done.

**Gate 4 Checks:**
1. All gate-3 checks pass (call gate-3.sh)
2. Docs updated (check index.yaml has spec → docs link)
3. Traceability complete (spec → code, tests, docs all present)
4. No [NEEDS CLARIFICATION] markers in docs
5. CHANGELOG.md updated (mentions SPEC-ID)
6. Feature doc exists (docs/60-features/{SPEC-ID}.md)
7. Spec status = verified (not done yet, will be set after gate passes)

**Exit Code:**
- `0` if all checks pass
- `1` if any check fails

**Acceptance Criteria:**
- [ ] Script runs gate-3 first (delegates)
- [ ] Script validates traceability (checks index.yaml)
- [ ] Script checks docs/ for [NEEDS CLARIFICATION]
- [ ] Script checks CHANGELOG.md mentions SPEC-ID
- [ ] Script checks feature doc exists
- [ ] Script prints clear failure reasons

**Dependencies:** Task 4.4 (gate-3), Task 3.4 (index.yaml)

**Verification:**
```bash
# Test gate-4 pass
./gate-4.sh --spec AUTH-001
echo $?  # 0

# Test gate-4 fail (no feature doc)
rm docs/60-features/AUTH-001.md
./gate-4.sh --spec AUTH-001
echo $?  # 1
# Output: "Feature doc missing: docs/60-features/AUTH-001.md"
```

---

### Task 4.6: Gate Enforcement - Workflow Integration

**Files:** `scripts/workflows/feature/feature-orchestrator.sh` (updated)

**Description:** Integrate gates into workflow orchestrator.

**Gate Integration Points:**
1. **Discover → Specify:** Run gate-1, block advance if fails
2. **Specify → Implement:** Run gate-2, block advance if fails
3. **Implement → Verify:** Run gate-3, block advance if fails
4. **Verify → Done:** Run gate-4, block advance if fails

**Orchestrator Updates:**
```bash
# Before advancing stage, run appropriate gate
case $CURRENT_STAGE in
  discover)
    run-gate.sh --gate 1 --spec $SPEC_ID || exit 1
    ;;
  specify)
    run-gate.sh --gate 2 --spec $SPEC_ID || exit 1
    ;;
  implement)
    run-gate.sh --gate 3 --spec $SPEC_ID || exit 1
    ;;
  verify)
    run-gate.sh --gate 4 --spec $SPEC_ID || exit 1
    ;;
esac
```

**Acceptance Criteria:**
- [ ] Orchestrator runs gate before each stage transition
- [ ] Orchestrator blocks advance if gate fails (can_advance=false)
- [ ] Orchestrator prints gate results (passed/failed, reasons)
- [ ] Orchestrator respects config.behavior.gates_enabled flag
- [ ] Orchestrator allows manual gate override (--force-advance flag, warns)

**Dependencies:** Tasks 4.1-4.5 (all gates), Task 2.5 (orchestrator)

**Verification:**
```bash
# Test gate enforcement
./feature-orchestrator.sh --spec AUTH-001 --advance
# (gate-1 runs automatically, blocks if fails)
yq eval '.can_advance' .spec-drive/state.yaml  # false (if gate failed)
```

---

### Task 4.7: Gate Enforcement - Manual Gate Runs

**Files:** `scripts/commands/spec-drive-gate.sh`

**Description:** Command to manually run gates (debugging, preview).

**Command Modes:**
1. **Run** - `./spec-drive-gate.sh --gate 1 --spec AUTH-001`
   - Runs specified gate, prints results
2. **Status** - `./spec-drive-gate.sh --status --spec AUTH-001`
   - Shows all gate results for spec from state.yaml
3. **Rerun** - `./spec-drive-gate.sh --rerun --spec AUTH-001`
   - Reruns all gates for spec (debugging)

**Acceptance Criteria:**
- [ ] Command supports run, status, rerun modes
- [ ] Command delegates to run-gate.sh
- [ ] Command prints clear results (table format)
- [ ] Command updates state.yaml (run mode)
- [ ] Command reads from state.yaml (status mode)

**Dependencies:** Task 4.1 (run-gate.sh)

**Verification:**
```bash
# Test manual gate run
./spec-drive-gate.sh --gate 1 --spec AUTH-001
# Output: "Gate 1: PASSED" (or FAILED with reasons)

# Test status
./spec-drive-gate.sh --status --spec AUTH-001
# Output: Table of all gate results
```

---

### Phase 4 Exit Criteria

**All tasks 4.1-4.7 complete:**
- [ ] Gate infrastructure (run-gate.sh) working
- [ ] All 4 gates implemented (gate-1 through gate-4)
- [ ] Gates integrated into workflow orchestrator
- [ ] Manual gate command (spec-drive-gate.sh) working
- [ ] All gate scripts have unit tests
- [ ] Manual smoke test: Run feature workflow, verify gates block invalid transitions
- [ ] Integration test: Test each gate with passing and failing scenarios
- [ ] Phase 4 documentation updated

**Deliverables:**
- Working gate scripts in `scripts/gates/`
- Updated workflow orchestrator with gate enforcement
- Gate command in `scripts/commands/`
- Test suite for all gates
- Gate documentation

---

## Phase 5: Integration & Testing

**Goal:** End-to-end validation, multi-platform testing, bug fixes
**Duration:** 2-3 weeks
**Prerequisites:** All phases complete

### Task 5.1: Integration Test - New Project Workflow

**Files:** `tests/integration/test-new-project.sh`

**Description:** End-to-end test of /spec-drive:app-new workflow.

**Test Scenario:**
1. Create temp directory
2. Run /spec-drive:app-new with test inputs
3. Verify:
   - .spec-drive/ structure created
   - docs/ structure created
   - APP-001 spec exists
   - config.yaml valid
   - state.yaml valid
   - index.yaml populated
4. Clean up

**Acceptance Criteria:**
- [ ] Test script creates isolated test environment
- [ ] Test script runs app-new workflow
- [ ] Test script verifies all expected files/dirs exist
- [ ] Test script validates YAML files against schemas
- [ ] Test script cleans up (no leftover files)
- [ ] Test script exits with 0 on success, 1 on failure

**Dependencies:** Phase 1, Phase 2 (app-new workflow)

**Verification:**
```bash
# Run integration test
./test-new-project.sh
echo $?  # 0 (pass)
```

---

### Task 5.2: Integration Test - Feature Workflow (Full Cycle)

**Files:** `tests/integration/test-feature-workflow.sh`

**Description:** End-to-end test of /spec-drive:feature workflow (all 4 stages).

**Test Scenario:**
1. Initialize project (app-new)
2. Start feature workflow (AUTH-001)
3. Advance through all stages:
   - Discover → Specify (mock: add acceptance criteria, run gate-1)
   - Specify → Implement (mock: create code/tests with @spec tags, run gate-2)
   - Implement → Verify (mock: run tests, run gate-3)
   - Verify → Done (mock: update docs, run gate-4)
4. Verify:
   - Spec status = done
   - Tests pass
   - Docs updated
   - Index.yaml traceability complete
5. Clean up

**Acceptance Criteria:**
- [ ] Test script runs full feature lifecycle
- [ ] Test script mocks implementation steps (code, tests, docs)
- [ ] Test script verifies all gates pass
- [ ] Test script verifies final state (status=done, traceability complete)
- [ ] Test script cleans up

**Dependencies:** Phase 2 (feature workflow), Phase 4 (gates)

**Verification:**
```bash
# Run integration test
./test-feature-workflow.sh
echo $?  # 0 (pass)
```

---

### Task 5.3: Integration Test - Autodocs Regeneration

**Files:** `tests/integration/test-autodocs.sh`

**Description:** Test autodocs system (code change → docs update).

**Test Scenario:**
1. Initialize project
2. Create mock code file with @spec tag
3. Set dirty flag
4. Run autodocs (run-autodocs.sh)
5. Verify:
   - index.yaml updated (component detected)
   - docs/ AUTO sections regenerated
   - dirty flag cleared
6. Modify code (add new component)
7. Run autodocs again
8. Verify incremental update (new component added)
9. Clean up

**Acceptance Criteria:**
- [ ] Test script simulates code changes
- [ ] Test script triggers autodocs
- [ ] Test script verifies index.yaml updates
- [ ] Test script verifies docs/ updates (AUTO sections)
- [ ] Test script verifies dirty flag cleared
- [ ] Test script tests incremental updates

**Dependencies:** Phase 3 (autodocs)

**Verification:**
```bash
# Run integration test
./test-autodocs.sh
echo $?  # 0 (pass)
```

---

### Task 5.4: Integration Test - Existing Project Initialization

**Files:** `tests/integration/test-existing-project.sh`

**Description:** Test existing project init (deep analysis + doc generation).

**Test Scenario:**
1. Create mock existing codebase (5-10 files)
2. Add existing docs/ (will be archived)
3. Run init-existing-project.sh
4. Verify:
   - Old docs/ archived (docs-archive-{timestamp}/)
   - New docs/ created
   - Components detected
   - Specs auto-generated
   - index.yaml populated
5. Clean up

**Acceptance Criteria:**
- [ ] Test script creates mock codebase
- [ ] Test script runs existing project init
- [ ] Test script verifies docs archived
- [ ] Test script verifies components detected
- [ ] Test script verifies specs generated
- [ ] Test script cleans up

**Dependencies:** Task 3.8 (existing project init)

**Verification:**
```bash
# Run integration test
./test-existing-project.sh
echo $?  # 0 (pass)
```

---

### Task 5.5: Multi-Platform Testing - Linux

**Files:** `tests/platform/test-linux.sh`

**Description:** Validate all workflows on Linux (Ubuntu, Debian).

**Test Matrix:**
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 12

**Tests:**
- All integration tests (5.1-5.4)
- Shell script compatibility (bash 4+)
- Tool dependencies (yq, jq, ajv)

**Acceptance Criteria:**
- [ ] Tests run on all Linux distros
- [ ] All integration tests pass
- [ ] No shell compatibility issues
- [ ] Tool dependencies documented (installation instructions)

**Dependencies:** Tasks 5.1-5.4 (integration tests)

**Verification:**
```bash
# Run on Ubuntu 22.04
docker run -v $(pwd):/workspace ubuntu:22.04 /workspace/tests/platform/test-linux.sh
# Run on Debian 12
docker run -v $(pwd):/workspace debian:12 /workspace/tests/platform/test-linux.sh
```

---

### Task 5.6: Multi-Platform Testing - macOS

**Files:** `tests/platform/test-macos.sh`

**Description:** Validate all workflows on macOS.

**Test Matrix:**
- macOS 13 (Ventura)
- macOS 14 (Sonoma)

**Tests:**
- All integration tests (5.1-5.4)
- Shell script compatibility (bash 3+ or zsh)
- Tool dependencies (brew install yq jq ajv)

**Acceptance Criteria:**
- [ ] Tests run on all macOS versions
- [ ] All integration tests pass
- [ ] No shell compatibility issues (bash vs zsh)
- [ ] Tool dependencies documented (brew installation)

**Dependencies:** Tasks 5.1-5.4

**Verification:**
```bash
# Run on macOS
./tests/platform/test-macos.sh
echo $?  # 0 (pass)
```

---

### Task 5.7: Performance Testing - Large Codebase

**Files:** `tests/performance/test-large-codebase.sh`

**Description:** Validate performance on large codebases (1000+ files).

**Test Scenario:**
1. Generate mock codebase (1000 files, 10k LOC)
2. Run code analysis (analyze-code.js)
3. Measure time: Should complete in <30 seconds
4. Run autodocs (index-docs + update-docs)
5. Measure time: Should complete in <60 seconds
6. Verify memory usage: <500MB

**Acceptance Criteria:**
- [ ] Test script generates large mock codebase
- [ ] Test script measures analysis time
- [ ] Test script measures autodocs time
- [ ] Test script measures memory usage
- [ ] Test script validates performance targets
- [ ] Test script provides performance report

**Dependencies:** Phase 3 (autodocs)

**Verification:**
```bash
# Run performance test
./test-large-codebase.sh
# Output:
# Analysis: 15s ✅
# Autodocs: 45s ✅
# Memory: 320MB ✅
```

---

### Task 5.8: Bug Fixes - Critical Issues

**Files:** (various, based on issues found)

**Description:** Fix critical bugs found during integration/platform testing.

**Bug Categories:**
1. **Workflow bugs** - Stage transitions fail, state corrupted
2. **Autodocs bugs** - Index generation fails, docs not updated
3. **Gate bugs** - False positives/negatives, crashes
4. **Schema bugs** - Validation errors, schema too strict
5. **Platform bugs** - Linux/macOS incompatibilities

**Process:**
1. Triage bugs (critical, high, medium, low)
2. Fix critical bugs first (blockers for release)
3. Document fixes (add tests, update docs)
4. Verify fix (regression test)

**Acceptance Criteria:**
- [ ] All critical bugs fixed (no known blockers)
- [ ] All bug fixes have regression tests
- [ ] All bug fixes documented (CHANGELOG.md)
- [ ] All bug fixes verified (manual + automated)

**Dependencies:** Tasks 5.1-5.7 (testing reveals bugs)

**Verification:**
```bash
# Re-run all tests after bug fixes
./tests/run-all-tests.sh
echo $?  # 0 (all tests pass)
```

---

### Task 5.9: Performance Optimization

**Files:** (various, based on profiling)

**Description:** Optimize performance bottlenecks.

**Optimization Targets:**
1. **Code analysis** - Parallelize file parsing (use worker threads)
2. **Autodocs** - Cache analysis results (skip unchanged files)
3. **Index generation** - Incremental updates (only regenerate changed sections)
4. **Schema validation** - Lazy validation (validate only when needed)

**Process:**
1. Profile scripts (time, memory)
2. Identify bottlenecks (90/10 rule)
3. Optimize hot paths
4. Measure improvement (before/after)

**Acceptance Criteria:**
- [ ] Code analysis 2x faster (parallelization)
- [ ] Autodocs 3x faster (caching)
- [ ] Index generation incremental (only changed files)
- [ ] Schema validation lazy (validate on demand)
- [ ] All optimizations have benchmarks
- [ ] All optimizations preserve correctness (regression tests pass)

**Dependencies:** Task 5.7 (performance tests)

**Verification:**
```bash
# Run performance test before/after
./test-large-codebase.sh
# Before: Analysis 15s, Autodocs 45s
# After: Analysis 7s, Autodocs 15s
```

---

### Task 5.10: Final Documentation Update

**Files:** (all docs/)

**Description:** Update all documentation for release.

**Documentation Updates:**
1. **README.md** - Final review, add badges, screenshots
2. **ARCHITECTURE.md** - Verify diagrams, update component list
3. **API.md** - Document all commands (spec-drive:*, spec-drive-*)
4. **TESTING.md** - Add test instructions, coverage report
5. **BUILD.md** - Add platform-specific instructions
6. **CONTRIBUTING.md** - Add contribution workflow
7. **CHANGELOG.md** - Finalize v0.1 release notes
8. **WORKFLOWS.md** - Add workflow examples (app-new, feature)
9. **TRACEABILITY.md** - Add traceability matrix
10. **All ADRs** - Review for accuracy

**Acceptance Criteria:**
- [ ] All docs reviewed (no stale content)
- [ ] All docs spell-checked (no typos)
- [ ] All docs have examples (screenshots, code blocks)
- [ ] All docs have clear next steps
- [ ] CHANGELOG.md complete (all features, fixes listed)
- [ ] README.md has clear "Getting Started" section

**Dependencies:** All phases complete

**Verification:**
```bash
# Run doc linter
./scripts/tools/lint-docs.sh
echo $?  # 0 (all docs pass)
```

---

### Phase 5 Exit Criteria

**All tasks 5.1-5.10 complete:**
- [ ] All integration tests pass (new project, feature workflow, autodocs, existing init)
- [ ] All platform tests pass (Linux, macOS)
- [ ] Performance tests pass (large codebase)
- [ ] All critical bugs fixed
- [ ] Performance optimized (analysis, autodocs faster)
- [ ] All documentation updated and finalized
- [ ] Manual smoke test: Full workflow on fresh project
- [ ] Release notes written (CHANGELOG.md)
- [ ] Phase 5 documentation complete

**Deliverables:**
- Working integration tests in `tests/integration/`
- Platform tests in `tests/platform/`
- Performance tests in `tests/performance/`
- Final documentation (all docs/)
- Release-ready codebase

---

## Dependencies & Critical Path

### Phase Dependencies

```
Phase 1 (Foundation)
  ↓
Phase 2 (Workflows) ←--parallel--→ Phase 3 (Autodocs)
  ↓                                     ↓
  Phase 4 (Quality Gates) ← (needs both)
  ↓
Phase 5 (Integration & Testing)
```

### Critical Path

**Longest path (determines minimum time):**
1. Phase 1: Foundation (1-2 weeks)
2. Phase 2: Workflows (2-3 weeks)
3. Phase 4: Quality Gates (1-2 weeks)
4. Phase 5: Integration & Testing (2-3 weeks)

**Total:** 6-10 weeks (assuming parallelism between Phase 2 and 3)

### Parallelization Opportunities

**Phase 1 & 2:**
- Task 1.1-1.2 (templates) can run parallel with Task 1.3-1.7 (directories/config)

**Phase 2 & 3:**
- Entire Phase 2 and Phase 3 can run in parallel (independent systems)

**Phase 4:**
- Tasks 4.2-4.5 (individual gates) can run parallel after 4.1 (runner) complete

**Phase 5:**
- Tasks 5.1-5.4 (integration tests) can run parallel
- Tasks 5.5-5.6 (platform tests) can run parallel

---

## Risk Mitigation

### High-Priority Risks

**Risk 1: Shell Script Portability**
- **Impact:** Scripts fail on some platforms (bash vs zsh, Linux vs macOS)
- **Mitigation:** Use portable shell syntax (POSIX), test on all platforms early
- **Contingency:** Add platform detection, use platform-specific implementations

**Risk 2: Performance (Large Codebases)**
- **Impact:** Autodocs too slow (>5 minutes on 1000+ files)
- **Mitigation:** Parallelize analysis, cache results, incremental updates
- **Contingency:** Add --skip-analysis flag for manual mode

**Risk 3: Tool Dependencies**
- **Impact:** Users missing yq, jq, ajv, node
- **Mitigation:** Document dependencies clearly, provide install scripts
- **Contingency:** Bundle tools (vendored dependencies)

**Risk 4: State Corruption**
- **Impact:** state.yaml corrupted (workflow stuck)
- **Mitigation:** Atomic writes (temp + mv), validation on read, backups
- **Contingency:** Add /spec-drive:reset-state command (with confirmation)

**Risk 5: Template Complexity**
- **Impact:** Templates hard to maintain, variables confusing
- **Mitigation:** Keep templates simple, document variables, validation
- **Contingency:** Simplify templates (fewer AUTO sections)

---

## Success Criteria

### v0.1 Release Criteria

**Functional:**
- [ ] app-new workflow complete (planning → docs generation)
- [ ] feature workflow complete (4 stages: discover, specify, implement, verify)
- [ ] Autodocs system working (code → index → docs)
- [ ] Quality gates enforced (4 gates: specify, architect, implement, verify)
- [ ] Existing project init working (deep analysis + doc generation)

**Quality:**
- [ ] All integration tests pass (100% pass rate)
- [ ] All platform tests pass (Linux, macOS)
- [ ] Performance targets met (analysis <30s, autodocs <60s for 1000 files)
- [ ] No critical bugs (zero blockers)
- [ ] Code coverage >80% (unit tests)

**Documentation:**
- [ ] All 12 docs generated and reviewed
- [ ] All 7 ADRs complete and accurate
- [ ] README.md clear and comprehensive
- [ ] CHANGELOG.md complete (v0.1 release notes)
- [ ] API documentation complete (all commands documented)

**User Experience:**
- [ ] /spec-drive:app-new takes <5 minutes (interactive)
- [ ] /spec-drive:feature workflow clear (obvious next steps)
- [ ] Error messages helpful (actionable suggestions)
- [ ] Autodocs non-disruptive (runs in background)

---

## Next Steps After v0.1

**v0.2 Planned Features:**
1. Parallel workflows (multiple specs in progress)
2. bugfix workflow (Investigate → Specify Fix → Fix → Verify)
3. research workflow (Timeboxed research + ADR output)
4. Multi-developer support (distributed state)
5. Web UI (dashboard for workflow status, traceability)

**Refer to:**
- TDD Section 11: Future Enhancements (v0.2+)
- ADRs: "Future Evolution" sections

---

**Maintained By:** Core Team
**Update Frequency:** Weekly during implementation
**Last Review:** 2025-11-01
