# ADR-007: Single State File (vs Per-Feature State)

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #8, [TDD.md](../TDD.md) Section 4.3

---

## Context

spec-drive's workflow system tracks development state across features. State includes:

- Current workflow (app-new, feature)
- Current spec (SPEC-ID)
- Current stage (discover, specify, implement, verify)
- Gate status (`can_advance: true/false`)
- Dirty flag (autodocs trigger)
- Workflow history (completed workflows, timestamps)

### State Persistence Design Choices

The system must decide:

1. **State file structure:** Single file vs multiple files?
2. **State scope:** Global (project-level) vs per-feature?
3. **State format:** YAML vs JSON vs other?
4. **State lifecycle:** When created? When deleted? Git-tracked?

### State Management Strategies Evaluated

**Option A: Per-feature state files**

```
.spec-drive/
├── state/
│   ├── APP-001-state.yaml
│   ├── AUTH-001-state.yaml
│   └── PROFILE-001-state.yaml
```

**Pros:**
- ✅ Parallel feature development (multiple features in progress)
- ✅ Clear separation (each feature isolated)

**Cons:**
- ❌ Complex implementation (track multiple state files)
- ❌ Current workflow ambiguous (which feature is active?)
- ❌ Merge conflicts (multiple developers, multiple state files)
- ❌ Cleanup required (delete state files after feature complete)

**Option B: Single state file**

```
.spec-drive/state.yaml
```

**Pros:**
- ✅ Simple implementation (one file to read/write)
- ✅ Clear current context (one active workflow)
- ✅ Easy to reason about (one source of truth)
- ✅ Atomic updates (single file, atomic writes)

**Cons:**
- ⚠️ Serial feature development (one feature at a time in v0.1)
- ⚠️ No parallel workflows (limitation for teams)

**Option C: Single state file + workflow history**

```yaml
# .spec-drive/state.yaml
current_workflow: "feature"
current_spec: "AUTH-001"
current_stage: "implement"

workflows:
  APP-001:
    status: "done"
    completed: "2025-11-01T10:00:00Z"
  AUTH-001:
    status: "in_progress"
    started: "2025-11-01T14:00:00Z"
```

**Pros:**
- ✅ Single file (simple)
- ✅ History preserved (track completed work)
- ✅ Current context clear (`current_*` fields)
- ✅ Scalable to multiple workflows (in history)

**Cons:**
- ⚠️ Still serial (one active workflow)

**Option D: Database (SQLite)**

```sql
CREATE TABLE state (
  key TEXT PRIMARY KEY,
  value TEXT
);
```

**Pros:**
- ✅ Structured queries
- ✅ Atomic transactions

**Cons:**
- ❌ Heavyweight (SQLite dependency)
- ❌ Binary file (not human-readable)
- ❌ Merge conflicts harder (binary diff)
- ❌ Overkill for simple state

---

## Decision

**We will use a single `state.yaml` file with workflow history.**

### File Structure

**Location:** `.spec-drive/state.yaml`

**Format:** YAML (human-readable, comment support)

**Schema:**

```yaml
current_workflow: "feature"  # app-new | feature | null
current_spec: "AUTH-001"     # SPEC-ID or null
current_stage: "implement"   # discover | specify | implement | verify | null
can_advance: false           # true | false (set by gates)
dirty: true                  # true | false (autodocs trigger)

workflows:
  APP-001:
    workflow: "app-new"
    status: "done"
    completed: "2025-11-01T10:00:00Z"

  AUTH-001:
    workflow: "feature"
    status: "in_progress"
    stage: "implement"
    started: "2025-11-01T14:00:00Z"
    gates:
      gate-1: { passed: true, timestamp: "2025-11-01T14:05:00Z" }
      gate-2: { passed: true, timestamp: "2025-11-01T14:10:00Z" }
      gate-3: { passed: false, timestamp: "2025-11-01T14:30:00Z" }

meta:
  initialized: "2025-11-01T09:00:00Z"
  last_gate_run: "2025-11-01T14:30:00Z"
  last_autodocs_run: "2025-11-01T14:15:00Z"
```

### State Lifecycle

**Creation:**
- `state.yaml` created on `/spec-drive:init` (project initialization)
- Default values: `current_workflow: null`, `workflows: {}`

**Updates:**
- Workflow scripts update `current_*` fields
- Gates update `can_advance` field
- PostToolUse hook updates `dirty` field
- Workflow completion adds entry to `workflows` history

**Deletion:**
- Never deleted (persistent history)
- Can reset: `current_workflow: null` (no active workflow)

**Git Tracking:**
- **Gitignored** (`.gitignore`: `.spec-drive/state.yaml`)
- **Reasoning:** Runtime state, not source code
- **History:** `workflows` preserves history, but file itself ephemeral

---

## Consequences

### Positive

1. **Simplicity**
   - Single file to read/write (no file management)
   - Clear implementation (`yq eval` commands)
   - Easy to debug (view state with `cat state.yaml`)

2. **Atomic updates**
   - Single file write = atomic operation
   - No partial state (either all updated or none)
   - Crash-safe (YAML write is atomic with `mv`)

3. **Clear current context**
   - `current_workflow` = what's active now
   - `current_spec` = which spec is in progress
   - `current_stage` = where we are in the workflow
   - No ambiguity (one active workflow)

4. **History preservation**
   - `workflows` object tracks all work
   - Completed workflows remain in history
   - Gate run history (when each gate passed)
   - Useful for analytics, debugging

5. **Human-readable**
   - YAML format (easy to read, edit manually if needed)
   - Comments supported (can add notes)
   - Grep-friendly (search for spec IDs)

### Negative

1. **Serial feature development (v0.1)**
   - One active workflow at a time
   - Cannot work on AUTH-001 and PROFILE-001 simultaneously
   - ❌ Limitation for teams (multiple developers)
   - **Mitigation:** v0.2 can add parallel workflow support
   - **Reasoning:** v0.1 keeps simple, focus single-developer workflow

2. **State file contention (multi-developer)**
   - Two developers update state.yaml simultaneously → conflict
   - ❌ Not designed for multi-developer yet
   - **Mitigation:** Single file easier to merge than multiple
   - **Future:** v0.2 adds locking, conflict resolution

3. **No feature isolation**
   - Switching features overwrites `current_*` fields
   - Previous feature state lost (unless committed first)
   - ❌ Context switching requires completing current workflow
   - **Mitigation:** Enforce workflow completion before switching

4. **Gitignored = no shared state**
   - Team members don't see each other's workflow state
   - ❌ No collaboration on same feature
   - **Mitigation:** Single-developer focus in v0.1
   - **Future:** v0.2 can make state.yaml tracked (optional)

### Trade-offs

**Chose simplicity over flexibility:**
- Single file vs per-feature files
- Benefit: Easier to implement, debug, maintain

**Chose serial over parallel:**
- One active workflow vs multiple concurrent
- Benefit: Simpler state management, clearer semantics
- v0.2 can add parallelism after proving single-developer value

**Chose gitignored over tracked:**
- Runtime state vs source code
- Benefit: No merge conflicts, no noise in git history
- Alternative: Could track for team collaboration (future)

---

## Alternatives Considered

### Per-Feature State Files - Rejected

```
.spec-drive/state/
├── AUTH-001.yaml
├── PROFILE-001.yaml
└── SESSION-002.yaml
```

**Why rejected:**
- Complex (manage multiple files)
- Ambiguous (which file is "current"?)
- Cleanup required (delete files after completion)
- v0.1 doesn't need parallelism (single-developer focus)

**Future consideration:** v0.2 could use this for parallel workflows.

### SQLite Database - Rejected

```sql
CREATE TABLE workflows (
  spec_id TEXT PRIMARY KEY,
  status TEXT,
  stage TEXT,
  ...
);
```

**Why rejected:**
- Heavyweight (adds SQLite dependency)
- Binary file (not human-readable, harder to debug)
- Merge conflicts harder (binary diff)
- Overkill for simple state (YAML sufficient)

### JSON State File - Rejected

```json
{
  "current_workflow": "feature",
  "current_spec": "AUTH-001"
}
```

**Why rejected:**
- No comments (YAML better for documentation)
- Less human-readable than YAML
- Same single-file approach (YAML preferred)

### Git-Tracked State - Rejected (for v0.1)

```yaml
# .spec-drive/state.yaml (tracked in git)
current_workflow: "feature"
current_spec: "AUTH-001"
```

**Why rejected (v0.1):**
- Noisy git history (state changes constantly)
- Merge conflicts (multiple developers update state)
- Not source code (runtime artifact)

**Future consideration:** v0.2 could make tracking optional (config flag).

---

## Implementation Notes

### Atomic Writes

**Pattern:** Write to temp, then move (atomic operation)

```bash
#!/bin/bash
# Update state.yaml atomically

TEMP_FILE=$(mktemp)
yq eval '.current_stage = "verify"' .spec-drive/state.yaml > "$TEMP_FILE"
mv "$TEMP_FILE" .spec-drive/state.yaml  # Atomic move
```

**Benefit:** No partial writes (either old file or new file, never corrupted).

### State Validation

**Schema validation on read:**

```bash
# scripts/tools/validate-state.sh
yq eval '.' .spec-drive/state.yaml > /dev/null
if [ $? -ne 0 ]; then
  echo "❌ state.yaml is invalid YAML"
  exit 1
fi

# Optional: JSON Schema validation
ajv validate -s .spec-drive/schemas/v0.1/state-schema.json \
              -d .spec-drive/state.yaml
```

**Purpose:** Detect corruption early (before runtime errors).

### State Initialization

```bash
# scripts/tools/init-state.sh
# Create initial state.yaml

cat > .spec-drive/state.yaml <<EOF
current_workflow: null
current_spec: null
current_stage: null
can_advance: false
dirty: false

workflows: {}

meta:
  initialized: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  last_gate_run: null
  last_autodocs_run: null
EOF
```

### State Reset

```bash
# scripts/tools/reset-state.sh
# Reset current workflow (keep history)

yq eval '
  .current_workflow = null |
  .current_spec = null |
  .current_stage = null |
  .can_advance = false |
  .dirty = false
' -i .spec-drive/state.yaml
```

**Use case:** Abandon current workflow, start fresh.

### History Cleanup

```bash
# scripts/tools/cleanup-history.sh
# Remove old completed workflows (keep last 10)

yq eval '
  .workflows |= (
    to_entries |
    sort_by(.value.completed) |
    reverse |
    .[0:10] |
    from_entries
  )
' -i .spec-drive/state.yaml
```

**Purpose:** Prevent state.yaml from growing unbounded.

---

## Related Decisions

- **ADR-001:** YAML format for specs (same format for state)
- **ADR-004:** Four quality gates (gates update state)
- **ADR-003:** Stage-boundary autodocs (dirty flag in state)

---

## Future Evolution (v0.2+)

### Parallel Workflows

```yaml
# Support multiple active workflows
active_workflows:
  - spec: "AUTH-001"
    stage: "implement"
  - spec: "PROFILE-001"
    stage: "specify"

# User switches context:
current_workflow: "AUTH-001"  # Active context
```

**Implementation:** More complex (need workflow switching logic).

### Git-Tracked Option

```yaml
# config.yaml
state:
  tracked: true  # or false (gitignored)
```

If tracked, team members share state (collaboration).

### Distributed State (Team Mode)

```
.spec-drive/state/
├── global.yaml       # Project-level state
├── user-joe.yaml     # Joe's personal state
└── user-alice.yaml   # Alice's personal state
```

**Purpose:** Multi-developer support (each developer has own state).

### State Snapshots

```bash
# Save state snapshot
/spec-drive:snapshot "Before refactoring"

# Restore snapshot
/spec-drive:restore "Before refactoring"
```

**Purpose:** Save/restore state for experimentation.

---

## References

- [TDD.md Section 4.3](../TDD.md) - Data architecture (.spec-drive/ structure)
- [TDD.md Section 5.3](../TDD.md) - Workflow state management
- [DECISIONS.md Decision #8](../DECISIONS.md) - Git tracking strategy

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 2 (workflow system)
- Trade-off: Simplicity over flexibility (serial vs parallel)
- Future: v0.2 adds parallel workflows, team collaboration
