# ADR-003: Multi-Workflow Conflict Detection

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.5)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 5: Multi-Workflow State)
- `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-004)

---

## Context

v0.2 enables 3+ concurrent workflows (e.g., AUTH-001 feature + BUG-042 bugfix + RESEARCH-001 running simultaneously). Each workflow modifies files, and users can switch between workflows.

**Problem:** When should we detect file conflicts between workflows?

**Conflict Scenarios:**
1. **Workflow A** modifies `src/auth.ts` (stage: implement)
2. **Workflow B** also modifies `src/auth.ts` (stage: fix)
3. User switches from A → B without committing changes
4. **Risk:** B overwrites A's uncommitted changes → data loss

**Requirements:**
- Detect conflicts before data loss occurs
- Warn user with clear message (which workflows conflict, which files)
- Provide resolution options (commit, abort, force)
- Performance: Detection must be fast (<1s)
- Correctness: No false positives (allow legitimate concurrent edits)

---

## Decision

**Detect conflicts on workflow switch (not on every file write) by comparing `files_locked[]` arrays in state.yaml.**

### Implementation

**State Schema (state.yaml v2.0):**
```yaml
workflows:
  AUTH-001:
    files_locked:
      - src/auth.ts
      - src/middleware/validate.ts
      - tests/auth.test.ts
    stage: implement
    priority: 5

  BUG-042:
    files_locked:
      - src/auth.ts        # CONFLICT: Also locked by AUTH-001
      - src/utils/hash.ts
    stage: fix
    priority: 0  # Bugfix = highest priority
```

**Conflict Detection Algorithm:**
```bash
# In /spec-drive:switch command (switch.sh)

detect_conflicts() {
  local from_workflow=$1
  local to_workflow=$2

  # Load files_locked arrays
  from_files=$(yq eval ".workflows.$from_workflow.files_locked" .spec-drive/state.yaml)
  to_files=$(yq eval ".workflows.$to_workflow.files_locked" .spec-drive/state.yaml)

  # Find intersection (O(n*m), acceptable for small arrays)
  conflicts=()
  for file in $to_files; do
    if echo "$from_files" | grep -q "$file"; then
      conflicts+=("$file")
    fi
  done

  # If conflicts found, warn user
  if [ ${#conflicts[@]} -gt 0 ]; then
    echo "WARNING: Workflow conflict detected"
    echo "Files locked by both $from_workflow and $to_workflow:"
    printf '  - %s\n' "${conflicts[@]}"
    echo ""
    echo "Options:"
    echo "  1. Commit changes in $from_workflow before switching"
    echo "  2. Abort switch (stay on $from_workflow)"
    echo "  3. Force switch (--force flag, may lose changes)"

    # Require user decision
    read -p "Choose (1/2/3): " choice
    case $choice in
      1) git add . && git commit -m "WIP: $from_workflow" ;;
      2) exit 0 ;;
      3) echo "Force switching, uncommitted changes may be lost" ;;
      *) echo "Invalid choice, aborting"; exit 1 ;;
    esac
  fi
}

# Usage
detect_conflicts "$CURRENT_WORKFLOW" "$TARGET_WORKFLOW"
```

**Tracking files_locked[]:**
```bash
# When workflow modifies a file (in orchestrator)
update_locked_files() {
  local workflow=$1
  local file=$2

  # Add file to workflow's files_locked array
  yq eval -i ".workflows.$workflow.files_locked += [\"$file\"]" .spec-drive/state.yaml
}

# Example: In feature.sh during implement stage
update_locked_files "$SPEC_ID" "src/components/Login.tsx"
```

---

## Consequences

### Positive

1. ✅ **Data loss prevented** - User warned before overwriting changes
2. ✅ **Fast detection** - Only checks on switch (not every file write)
3. ✅ **Simple algorithm** - Array intersection, O(n*m) acceptable
4. ✅ **Clear user messaging** - Shows conflicting files, provides options
5. ✅ **Non-blocking** - Workflows can run concurrently, conflict only on switch
6. ✅ **Commit encouragement** - Users commit more frequently (good practice)

### Negative

1. ⚠️ **Switch-time overhead** - Adds ~100-500ms to switch command
2. ⚠️ **False negatives possible** - If files_locked[] not updated correctly
3. ⚠️ **Manual resolution** - User must choose option (not automatic)

### Risks

- **RISK-004 (File Conflicts):** Mitigated by this detection, but relies on accurate files_locked[] tracking
- **False positives:** If files_locked[] not cleared after commit, shows conflicts unnecessarily
- **Performance:** If workflows lock 100+ files, intersection check may be slow (optimize with hash sets if needed)

---

## Alternatives Considered

### Alternative 1: Detect on Every File Write

**Approach:** Check for conflicts on every file modification (Edit, Write tools)

**Pros:**
- Immediate conflict detection (no switch needed)
- Can block writes to locked files (stricter safety)

**Cons:**
- **Performance overhead** - Every file write triggers conflict check (100s of checks per workflow)
- **User friction** - Blocks concurrent edits even when safe (e.g., different branches)
- **Complex implementation** - Requires hooking all file write operations

**Rejected because:** Too slow, too restrictive for concurrent workflows

---

### Alternative 2: Git Merge-Based Detection

**Approach:** Use git status to detect merge conflicts

**Pros:**
- Leverages git's conflict detection (proven, robust)
- Works with git workflows (branches per workflow)

**Cons:**
- **Requires git branches** - Each workflow needs separate branch (complex)
- **Merge overhead** - User must resolve merge conflicts manually
- **Not real-time** - Only detects conflicts after merge attempt

**Rejected because:** Too heavyweight, assumes git branch workflow (not all users use branches)

---

### Alternative 3: File Locking with OS-Level Locks

**Approach:** Use `flock` or `fcntl` for exclusive file locks

**Pros:**
- OS-enforced (no race conditions)
- Works across processes (even outside Claude Code)

**Cons:**
- **Blocks writes** - Second workflow cannot edit locked file (too restrictive)
- **Lock cleanup** - Orphaned locks if process crashes
- **Platform-specific** - flock behavior varies (Linux vs macOS)

**Rejected because:** Too restrictive, prevents legitimate concurrent edits

---

### Alternative 4: No Conflict Detection (User Responsibility)

**Approach:** Trust user to manage conflicts manually

**Pros:**
- No overhead, no complexity
- Maximum flexibility

**Cons:**
- **Data loss risk** - User accidentally overwrites changes
- **Poor UX** - Frustrating to lose work
- **Violates safety requirement** - PRD requires conflict detection

**Rejected because:** Fails safety requirement, poor user experience

---

## Implementation Notes

### Best Practices

1. **Update files_locked[] eagerly:**
```bash
# When workflow modifies file
echo "Editing src/auth.ts"
update_locked_files "$SPEC_ID" "src/auth.ts"
```

2. **Clear files_locked[] on commit:**
```bash
# After git commit
yq eval -i ".workflows.$SPEC_ID.files_locked = []" .spec-drive/state.yaml
```

3. **Normalize file paths:**
```bash
# Use absolute paths to avoid duplicates
file=$(realpath "$file")
update_locked_files "$SPEC_ID" "$file"
```

4. **Show diff on conflict:**
```bash
# Help user decide
git diff src/auth.ts
```

### Edge Cases

**Case 1: User force-switches despite warning**
- Document that uncommitted changes may be lost
- Consider auto-stash before force switch (git stash)

**Case 2: files_locked[] out of sync**
- Validate on load, warn if stale
- Allow manual refresh: `/spec-drive:refresh-locks`

**Case 3: 100+ locked files**
- Optimize with hash set for O(n+m) intersection
- Consider pagination in conflict warning

### Testing

```bash
# Test scenario
/spec-drive:feature AUTH-001 "Login"
# Modify src/auth.ts
/spec-drive:bugfix BUG-042 "Auth timeout"
# Modify src/auth.ts
/spec-drive:switch AUTH-001

# Expected: WARNING about src/auth.ts conflict
# User prompted for resolution
```

---

## References

- v0.2 TDD Section 3.5 (Multi-Workflow State)
- v0.2 RISK-ASSESSMENT RISK-004 (Multi-Workflow File Conflicts)
- Git conflict resolution documentation

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
