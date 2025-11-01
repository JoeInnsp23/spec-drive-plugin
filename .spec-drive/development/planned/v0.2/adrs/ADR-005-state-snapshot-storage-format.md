# ADR-005: State Snapshot Storage Format

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.6)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 6: Error Recovery)
- `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-003)

---

## Context

v0.2 adds error recovery with rollback capability. When a quality gate fails or workflow errors occur, users can rollback to a previous stage.

**Problem:** How should we store state snapshots for rollback?

**Requirements:**
1. **Capture critical state** - stage, timestamp, files modified, git commit
2. **Fast restore** - Rollback should take <5s
3. **Minimal storage** - Avoid large snapshot files (100s of snapshots over time)
4. **Simple access** - Easy to load snapshot for given stage
5. **Bounded size** - Prevent unlimited growth (max snapshots per workflow)

**Snapshot Use Cases:**
- **Rollback:** User reverts to previous stage after critical error
- **Resume:** User resumes interrupted workflow from last snapshot
- **History:** User views workflow progression history

---

## Decision

**Store snapshots nested in state.yaml v2.0 (not separate files), max 5 per workflow, FIFO eviction.**

### Implementation

**State Schema (state.yaml v2.0):**
```yaml
workflows:
  AUTH-001:
    spec_id: AUTH-001
    type: feature
    stage: implement
    priority: 5
    files_locked:
      - src/auth.ts
      - tests/auth.test.ts

    snapshots:
      - stage: discover
        timestamp: 2025-11-01T10:00:00Z
        git_commit: abc123
        files_modified: []

      - stage: specify
        timestamp: 2025-11-01T10:15:00Z
        git_commit: def456
        files_modified:
          - specs/SPEC-AUTH-001.yaml

      - stage: implement
        timestamp: 2025-11-01T11:00:00Z
        git_commit: ghi789
        files_modified:
          - src/auth.ts
          - tests/auth.test.ts

      # Max 5 snapshots, oldest evicted when 6th added (FIFO)

    retry_history: []
    created: 2025-11-01T09:00:00Z
    updated: 2025-11-01T11:00:00Z
```

**Snapshot Creation (create-snapshot.sh):**
```bash
#!/bin/bash

create_snapshot() {
  local workflow=$1
  local stage=$2

  # Capture current state
  timestamp=$(date -Iseconds)
  git_commit=$(git rev-parse HEAD)
  files_modified=$(git diff --name-only HEAD~1 HEAD | tr '\n' ',' | sed 's/,$//')

  # Add snapshot to workflow
  yq eval -i "
    .workflows.$workflow.snapshots += [{
      \"stage\": \"$stage\",
      \"timestamp\": \"$timestamp\",
      \"git_commit\": \"$git_commit\",
      \"files_modified\": \"$files_modified\"
    }]
  " .spec-drive/state.yaml

  # Enforce max 5 snapshots (evict oldest if needed)
  snapshot_count=$(yq eval ".workflows.$workflow.snapshots | length" .spec-drive/state.yaml)
  if [ "$snapshot_count" -gt 5 ]; then
    yq eval -i ".workflows.$workflow.snapshots |= .[1:]" .spec-drive/state.yaml
    echo "Evicted oldest snapshot (FIFO)"
  fi
}

# Usage: Called at stage boundaries
create_snapshot "AUTH-001" "implement"
```

**Snapshot Restoration (restore-snapshot.sh):**
```bash
#!/bin/bash

restore_snapshot() {
  local workflow=$1
  local target_stage=$2

  # Find snapshot for target stage
  snapshot=$(yq eval ".workflows.$workflow.snapshots[] | select(.stage == \"$target_stage\")" .spec-drive/state.yaml)

  if [ -z "$snapshot" ]; then
    echo "ERROR: No snapshot found for stage '$target_stage'"
    exit 1
  fi

  # Extract snapshot data
  git_commit=$(echo "$snapshot" | yq eval '.git_commit' -)
  timestamp=$(echo "$snapshot" | yq eval '.timestamp' -)

  # Warn user (destructive operation)
  echo "WARNING: Rollback will reset to commit $git_commit (from $timestamp)"
  echo "Uncommitted changes will be lost."
  read -p "Continue? (y/N): " confirm

  if [ "$confirm" != "y" ]; then
    echo "Rollback cancelled"
    exit 0
  fi

  # Restore git state
  git reset --hard "$git_commit"

  # Update workflow stage in state.yaml
  yq eval -i ".workflows.$workflow.stage = \"$target_stage\"" .spec-drive/state.yaml

  # Clear future snapshots (stages after target)
  # (User can re-progress from restored stage)
  yq eval -i ".workflows.$workflow.snapshots |= .[] | select(.stage == \"$target_stage\" or earlier)" .spec-drive/state.yaml

  echo "✓ Rolled back to stage '$target_stage'"
}

# Usage
restore_snapshot "AUTH-001" "specify"
```

---

## Consequences

### Positive

1. ✅ **Single file storage** - All snapshots in state.yaml (no separate files)
2. ✅ **Easy access** - yq queries find snapshots instantly
3. ✅ **Bounded size** - Max 5 snapshots per workflow (FIFO eviction)
4. ✅ **Simple backup** - Backup state.yaml = backup all snapshots
5. ✅ **Git-based restore** - Leverages git reset --hard (fast, reliable)
6. ✅ **No orphaned files** - Snapshots cleaned up with workflow

### Negative

1. ⚠️ **state.yaml size grows** - 3 workflows × 5 snapshots = 15 snapshots in one file
2. ⚠️ **No snapshot compression** - Full YAML structure (not binary)
3. ⚠️ **Git dependency** - Requires git commits at stage boundaries

### Risks

- **RISK-003 (State Corruption):** Mitigated by atomic updates, validation on load
- **Snapshot data loss:** If state.yaml corrupted, all snapshots lost (backup state.yaml regularly)
- **FIFO eviction too aggressive:** If 5 snapshots insufficient, allow config override

---

## Alternatives Considered

### Alternative 1: Separate Snapshot Files

**Approach:** Store each snapshot as separate file (.spec-drive/snapshots/AUTH-001-implement.yaml)

**Pros:**
- Smaller state.yaml (offloads snapshot data)
- Easy to delete individual snapshots
- Could compress old snapshots (gzip)

**Cons:**
- **File management complexity** - Many files to track (cleanup, backup)
- **Orphaned files** - Snapshots not cleaned up when workflow abandoned
- **Slower access** - Must read multiple files to list snapshots
- **Backup complexity** - Must backup entire snapshots/ directory

**Rejected because:** Too complex, file management overhead

---

### Alternative 2: Git Stash-Based Snapshots

**Approach:** Use git stash to save state at each stage

**Pros:**
- Git native (no custom storage)
- Includes uncommitted changes
- Built-in compression

**Cons:**
- **No metadata** - Cannot store stage, timestamp easily in stash
- **Hard to query** - git stash list doesn't show stage info
- **Fragile** - Stash can be lost (git stash drop)
- **No FIFO eviction** - Stashes accumulate indefinitely

**Rejected because:** Insufficient metadata, hard to query

---

### Alternative 3: SQLite Database

**Approach:** Store snapshots in SQLite database (.spec-drive/snapshots.db)

**Pros:**
- Efficient queries (SELECT * WHERE stage = 'implement')
- Compression (SQLite file smaller than YAML)
- Transactional (atomic updates)

**Cons:**
- **New dependency** - Requires SQLite (not always available)
- **Binary format** - Cannot edit manually (YAML is human-readable)
- **Overkill** - Database for 5 snapshots per workflow is excessive
- **Backup complexity** - Requires SQLite backup tools

**Rejected because:** Overkill, adds dependency, not human-readable

---

### Alternative 4: Unlimited Snapshots (No Eviction)

**Approach:** Store all snapshots indefinitely (no max 5 limit)

**Pros:**
- Full history preserved
- Can rollback to any point in workflow

**Cons:**
- **Unbounded growth** - state.yaml grows indefinitely
- **Performance degradation** - Large YAML file slow to parse
- **Backup size** - Backups become very large over time

**Rejected because:** Unbounded growth unacceptable

---

## Implementation Notes

### Best Practices

1. **Create snapshots at stage boundaries:**
```bash
# In workflow orchestrator (feature.sh)
advance_stage "AUTH-001" "implement"
create_snapshot "AUTH-001" "implement"
```

2. **Validate snapshot before restore:**
```bash
git_commit=$(yq eval ".workflows.$workflow.snapshots[-1].git_commit" .spec-drive/state.yaml)
if ! git cat-file -e "$git_commit"; then
  echo "ERROR: Snapshot commit $git_commit does not exist"
  exit 1
fi
```

3. **Show snapshot history:**
```bash
# /spec-drive:status command
yq eval ".workflows.AUTH-001.snapshots[] | .stage + \" (\" + .timestamp + \")\"" .spec-drive/state.yaml
# Output:
# discover (2025-11-01T10:00:00Z)
# specify (2025-11-01T10:15:00Z)
# implement (2025-11-01T11:00:00Z)
```

4. **Clean up snapshots on workflow completion:**
```bash
# When workflow reaches "done" stage
yq eval -i ".workflows.AUTH-001.snapshots = []" .spec-drive/state.yaml
```

### Edge Cases

**Case 1: No git commit at stage boundary**
- Force commit before snapshot creation
- Use WIP commit message: "WIP: AUTH-001 implement stage"

**Case 2: Rollback to stage with uncommitted changes**
- Warn user changes will be lost
- Offer stash option: `git stash save "Before rollback"`

**Case 3: Snapshot commit deleted (git gc)**
- Validate commit exists before restore
- Warn user if commit unreachable

### Testing

```bash
# Test snapshot creation
/spec-drive:feature AUTH-001 "Login"
# Progress through stages, verify snapshots created
yq eval '.workflows.AUTH-001.snapshots | length' .spec-drive/state.yaml
# Should be 3 (discover, specify, implement)

# Test rollback
/spec-drive:rollback AUTH-001 specify
# Verify git HEAD at specify stage commit
git log -1 --oneline

# Test FIFO eviction
# Create 10 snapshots, verify only 5 remain
```

---

## References

- Git reset documentation
- YAML nested structures
- v0.2 TDD Section 3.6 (Error Recovery)
- v0.2 PRD Enhancement 6 (Error Recovery)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
