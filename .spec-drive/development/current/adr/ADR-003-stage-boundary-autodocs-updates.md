# ADR-003: Stage-Boundary Autodocs Updates

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #10, [TDD.md](../TDD.md) Section 5.2

---

## Context

spec-drive's autodocs system (System 2) must keep documentation synchronized with code changes. The system needs to decide **when** to regenerate documentation:

1. **After every file change?** (continuous updates)
2. **After every tool use?** (high-frequency updates)
3. **On-demand only?** (manual trigger)
4. **At workflow stage boundaries?** (checkpoint updates)

### Requirements

- **Accuracy:** Docs must reflect current codebase state
- **Performance:** Updates must not slow development
- **Stability:** Docs should not churn during active development
- **Developer UX:** Updates should feel automatic but not intrusive

### Update Frequency Strategies Evaluated

**Option A: Continuous (file watcher)**
- Monitor file system, regenerate docs on any change
- ✅ Docs always up-to-date (real-time)
- ❌ High overhead (runs after every save)
- ❌ Churn (docs regenerate during active editing)
- ❌ Resource intensive (filesystem watchers, constant regeneration)
- ❌ Disrupts workflow (git diffs constantly changing)

**Option B: After every tool use (PostToolUse hook)**
- Regenerate docs after Edit, Write, NotebookEdit tools
- ✅ Fairly up-to-date (updates after code changes)
- ❌ Still high frequency (many tool uses per feature)
- ❌ Performance cost (runs dozens of times per feature)
- ❌ Git noise (docs change multiple times during development)

**Option C: Manual only (user triggers)**
- User runs `/spec-drive:update-docs` when desired
- ✅ User controls timing
- ❌ Users will forget to run it
- ❌ Defeats automation purpose
- ❌ Docs will drift (same problem we're solving)

**Option D: Stage-boundary (workflow checkpoints)**
- Regenerate docs at stage transitions (Discover → Specify → Implement → Verify)
- ✅ Meaningful checkpoints (work completed, ready to advance)
- ✅ Minimal overhead (4 regenerations per feature max)
- ✅ Stable docs (no churn during active development)
- ✅ Natural sync points (gate checks align with doc updates)
- ⚠️ Docs lag during active stage (acceptable trade-off)

---

## Decision

**We will regenerate documentation at workflow stage boundaries only.**

Autodocs updates trigger when:
1. Quality gate passes (work for stage complete)
2. Dirty flag is set (code/docs changed during stage)
3. Stage advancement requested

### Mechanism

**Dirty Flag System:**

During development, PostToolUse hook sets dirty flag:

```bash
# hooks/handlers/post-tool-use.sh
if [[ "$TOOL_NAME" =~ ^(Edit|Write|NotebookEdit)$ ]]; then
  yq eval '.dirty = true' -i .spec-drive/state.yaml
fi
```

At stage boundary, gate-4 checks dirty flag:

```bash
# scripts/gates/gate-4-done.sh
DIRTY=$(yq eval '.dirty' .spec-drive/state.yaml)
if [ "$DIRTY" = "true" ]; then
  # Trigger autodocs
  scripts/tools/index-docs.js      # Update index.yaml
  scripts/tools/update-docs.js     # Regenerate affected docs
  yq eval '.dirty = false' -i .spec-drive/state.yaml  # Clear flag
fi
```

### Update Flow

```
Developer writes code (Edit/Write tool)
  │
  ▼
PostToolUse hook fires
  └─► Set dirty: true in state.yaml
  │
  ▼
Development continues... (dirty flag remains true)
  │
  ▼
Stage boundary reached (Implement → Verify)
  │
  ▼
Quality gate executes (gate-3-verify.sh)
  └─► Tests pass? @spec tags present? Lint clean?
  │
  ▼
Gate-4-done.sh executes
  ├─► Check dirty flag
  └─► If dirty=true:
       ├─► Run index-docs.js (scan code, update traces)
       ├─► Run update-docs.js (regenerate feature page, catalog)
       └─► Set dirty: false
  │
  ▼
Workflow advances to next stage
```

### Regeneration Scope

**Stage boundaries that trigger autodocs:**

1. **Discover → Specify:** Usually no code changes (dirty=false, no regeneration)
2. **Specify → Implement:** Spec created (regenerate spec trace if spec changed)
3. **Implement → Verify:** Code + tests written (full regeneration)
4. **Verify → Done:** Final verification (regenerate if any last-minute changes)

**What gets regenerated:**

- `index.yaml` - Always updated (scan for @spec tags, update traces)
- `docs/60-features/SPEC-ID.md` - Feature page for active spec
- `docs/10-architecture/COMPONENT-CATALOG.md` - If components changed
- `docs/40-api/*.md` - If API signatures changed

---

## Consequences

### Positive

1. **Reduced overhead**
   - Max 4 regenerations per feature (vs dozens with per-tool-use)
   - Performance acceptable (<5s per regeneration)
   - Developer workflow not interrupted

2. **Stable documentation**
   - Docs don't churn during active development
   - Git diffs cleaner (docs change at meaningful checkpoints)
   - Easier to review doc changes (aligned with stage completion)

3. **Natural sync points**
   - Doc updates align with quality gates
   - Stage boundaries = work complete = good time to update docs
   - Dirty flag ensures updates happen when needed (not wasted)

4. **Acceptable lag**
   - Docs lag during active stage (e.g., while implementing)
   - **Acceptable:** Docs meant for other developers, not actively editing developer
   - **Mitigation:** Developer knows current state (actively working on it)

### Negative

1. **Documentation lag during development**
   - Docs outdated while developer works within a stage
   - Example: Implement stage (30 min coding) → docs outdated for 30 min
   - **Mitigation:** Acceptable trade-off for performance
   - **Reasoning:** Developer knows code state, docs for others

2. **Manual trigger not available (v0.1)**
   - User cannot force doc update mid-stage
   - **Mitigation:** v0.2 can add `/spec-drive:update-docs` command
   - **Reasoning:** Keep v0.1 simple, add flexibility later

3. **Dependency on workflow discipline**
   - Autodocs only updates if user follows workflow stages
   - If user skips stages, docs never update
   - **Mitigation:** Behavior agent enforces stage discipline (can't skip)
   - **Reasoning:** Workflow enforcement is core value proposition

4. **All-or-nothing update**
   - Either regenerate all affected docs or none
   - Cannot selectively update one doc type
   - **Mitigation:** Selective regeneration logic (only changed docs)
   - **Implementation:** `update-docs.js` checks what changed

### Trade-offs

**Chose performance over real-time accuracy:**
- Stage-boundary updates = lower overhead
- Docs lag acceptable for significant performance gain

**Chose stability over immediacy:**
- Stable docs better than constantly changing docs
- Git history cleaner, reviews easier

**Chose automation over user control:**
- Automatic updates at stage boundaries vs manual trigger
- Removes burden from user, enforces discipline

---

## Alternatives Considered

### Continuous Updates (File Watcher) - Rejected

**Implementation:**
```javascript
// Watch all src/ and tests/ files
const watcher = chokidar.watch(['src/**', 'tests/**']);
watcher.on('change', (path) => {
  regenerateDocs();  // After every save
});
```

**Why rejected:**
- Too frequent (runs after every file save)
- High overhead (dozens of regenerations during active development)
- Disrupts workflow (git status constantly changing)
- Resource intensive (filesystem watchers)

### Per-Tool-Use Updates - Rejected

**Implementation:**
```bash
# hooks/handlers/post-tool-use.sh
if [[ "$TOOL_NAME" =~ ^(Edit|Write)$ ]]; then
  scripts/tools/update-docs.js &  # Background regeneration
fi
```

**Why rejected:**
- Still high frequency (10-20 tool uses per feature)
- Performance cost adds up (10-20 regenerations × 3s = 30-60s overhead)
- Git noise (docs change after every code edit)
- No clear benefit over stage-boundary (docs still lag a bit)

### Manual Only - Rejected

**Implementation:**
```markdown
# commands/update-docs.md
Run autodocs regeneration now.
```

**Why rejected:**
- Users will forget to run it
- Defeats automation purpose
- Docs will drift (same problem as no autodocs)
- Requires user to remember (cognitive load)

### Time-Based (Every N Minutes) - Rejected

**Implementation:**
```bash
# Cron-like: regenerate every 10 minutes
while true; do
  sleep 600
  if [ "$(yq eval '.dirty' state.yaml)" = "true" ]; then
    regenerate_docs
  fi
done
```

**Why rejected:**
- Arbitrary timing (no relation to work completion)
- Background process complexity
- Doesn't align with workflow stages
- Worse than stage-boundary (less meaningful sync points)

---

## Implementation Notes

### Dirty Flag Semantics

**Set dirty flag when:**
- Edit tool used (code changes)
- Write tool used (new file)
- NotebookEdit tool used (notebook changes)

**Clear dirty flag when:**
- Autodocs regeneration completes successfully
- Gate-4 passes and docs verified current

**Ignore dirty flag when:**
- Read tool used (no changes)
- Bash tool used (may or may not change files - conservative: don't set dirty)
- Grep/Glob tools used (search only)

**Edge case: What if bash script modifies files?**
- Conservative approach: Don't set dirty for Bash
- **Reasoning:** Too broad (bash could be git status, ls, etc.)
- **Mitigation:** If bash modifies code, developer uses Edit after → dirty set anyway

### Performance Optimization

**Selective regeneration:**

```javascript
// scripts/tools/update-docs.js
function updateDocs() {
  const index = loadIndex();
  const lastRun = getLastRunTimestamp();

  // Only regenerate docs for changed specs
  const changedSpecs = index.specs.filter(spec =>
    spec.updated > lastRun
  );

  for (const spec of changedSpecs) {
    regenerateFeaturePage(spec);  // Only this spec
  }

  // Only regenerate catalog if components changed
  if (componentsChanged(index, lastRun)) {
    regenerateComponentCatalog();
  }
}
```

**Result:** Typical feature regeneration <3s (only affected docs).

### Error Handling

**If autodocs fails:**

```bash
# scripts/gates/gate-4-done.sh
if ! scripts/tools/update-docs.js; then
  echo "⚠️ WARNING: Autodocs regeneration failed"
  echo "Docs may be out of sync. Review manually."
  # Don't block gate (docs failure shouldn't prevent workflow advancement)
  # Dirty flag remains true (retry next stage)
fi
```

**Design decision:** Autodocs failure is warning, not error.
- **Reasoning:** Documentation lag acceptable, workflow should continue
- **Alternative:** Could block gate-4 until docs update succeeds (more strict)

---

## Related Decisions

- **ADR-002:** SessionStart hook auto-injection (loads behavior that enforces docs-first)
- **ADR-004:** Four quality gates (gates trigger autodocs)
- **DECISIONS.md Decision #11:** JSDoc-style @spec tags (what autodocs scans for)

---

## Future Evolution (v0.2+)

### Manual Trigger Support

```bash
# User can force doc update mid-stage
/spec-drive:update-docs

# Bypasses dirty flag, always regenerates
```

### Configurable Update Frequency

```yaml
# config.yaml
autodocs:
  update_frequency: "stage-boundary"  # or "manual", "per-tool", "continuous"
```

### Incremental Updates

```javascript
// Only update changed sections within docs
// Currently: regenerate entire doc
// Future: Update only affected sections (preserve manual edits better)
```

---

## References

- [TDD.md Section 5.2](../TDD.md) - Autodocs system architecture
- [TDD.md Section 7.2](../TDD.md) - Autodocs trigger flow
- [PRD.md](../PRD.md) - Auto-update mechanism design

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 3 (autodocs system)
- Performance validated: <5s per regeneration
- Trade-off: Stability over real-time accuracy
