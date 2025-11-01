# ADR-005: Aggressive Existing Project Initialization

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #16, [TDD.md](../TDD.md) Section 5.2, [PRD.md](../PRD.md)

---

## Context

spec-drive must initialize in two scenarios:

1. **New projects:** No existing code or docs (app-new workflow)
2. **Existing projects:** Code exists, docs may or may not exist

For existing projects, the key question is: **What to do with existing documentation?**

### User Expectations

- New projects should get rich documentation baseline (12 docs)
- Existing projects should get SAME baseline (consistency)
- Onboarding new developers should have complete, accurate docs
- Legacy docs may be outdated, incomplete, or non-existent

### Existing Documentation States

**State A: No docs exist**
- Fresh codebase with no `docs/` folder
- ✅ Easy: Generate full doc structure from code analysis

**State B: Partial docs exist**
- Some docs present (e.g., README.md, ARCHITECTURE.md)
- Some missing (e.g., API docs, data flows)
- Docs likely outdated (code evolved, docs didn't)
- ⚠️ Challenge: Merge existing + generated? Replace? Ignore?

**State C: Complete but outdated docs**
- Full `docs/` folder exists
- Docs written months/years ago, not maintained
- Doesn't reflect current code state
- ⚠️ Challenge: Trust old docs or regenerate?

### Initialization Strategies Evaluated

**Option A: Preserve existing docs (conservative)**
- Keep all existing docs untouched
- Generate only missing docs
- ❌ Inconsistent baseline (new vs existing projects different)
- ❌ Outdated docs persist (same problem we're solving)
- ❌ No value to existing projects (just adds missing docs)

**Option B: Merge existing docs (hybrid)**
- Analyze existing docs, extract content
- Merge with auto-generated docs
- ❌ Complex implementation (AI-based merging? Manual review?)
- ❌ Still inconsistent (each project unique)
- ❌ Risk of preserving outdated information

**Option C: Prompt user per doc (manual)**
- For each existing doc, ask: "Keep, Replace, or Merge?"
- ❌ Poor UX (dozens of prompts for 12 docs)
- ❌ User doesn't know which docs are outdated
- ❌ Cognitive overhead (user must decide without context)

**Option D: Archive and regenerate (aggressive)**
- Move `docs/` → `docs-archive-{timestamp}/`
- Analyze code, regenerate ALL docs from scratch
- ✅ Consistent baseline (new + existing get same docs)
- ✅ Fresh, accurate docs (reflect current code)
- ✅ Simple implementation (no merging complexity)
- ⚠️ Old docs archived, not deleted (recoverable)
- ⚠️ Manual content lost (user must port if valuable)

---

## Decision

**We will archive existing docs and regenerate from scratch (aggressive approach).**

### Initialization Process

**Step 1: Backup existing docs**

```bash
# Archive docs/ to timestamped folder
TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
if [ -d "docs/" ]; then
  mv docs/ "docs-archive-${TIMESTAMP}/"
  echo "Existing docs archived to: docs-archive-${TIMESTAMP}/"
fi
```

**Step 2: Deep code analysis**

```bash
# Analyze codebase structure
scripts/tools/analyze-codebase.js
# Output: components.json (classes, functions, modules, dependencies)
```

**Step 3: Generate full docs/ structure**

```bash
# Generate all 12 docs from templates + code analysis
scripts/tools/init-docs.sh
# Output:
# - docs/00-overview/SYSTEM-OVERVIEW.md
# - docs/00-overview/GLOSSARY.md
# - docs/10-architecture/ARCHITECTURE.md
# - docs/10-architecture/COMPONENT-CATALOG.md
# - docs/10-architecture/DATA-FLOWS.md
# - docs/10-architecture/RUNTIME-DEPLOYMENT.md
# - docs/10-architecture/OBSERVABILITY.md
# - docs/20-build/BUILD-RELEASE.md
# - docs/20-build/CI-QUALITY-GATES.md
# - docs/PRODUCT-BRIEF.md
```

**Step 4: Build AI-optimized index**

```bash
# Generate index.yaml from code analysis
scripts/tools/generate-index.sh
# Output: .spec-drive/index.yaml with components[], code[], docs[]
```

**Result:** Existing project has SAME documentation baseline as new project.

### User Communication

**On init:**

```
🔄 Initializing spec-drive for existing project...

Found existing docs/ folder (42 files)
📦 Archiving to: docs-archive-2025-11-01T10-30-00/

🔍 Analyzing codebase...
   - Detected: 156 components across 89 files
   - Tech stack: TypeScript, React, Node.js

📚 Generating documentation...
   ✅ SYSTEM-OVERVIEW.md
   ✅ ARCHITECTURE.md
   ✅ COMPONENT-CATALOG.md (156 components)
   ✅ ... (9 more docs)

✅ Initialization complete!

Next steps:
1. Review generated docs in docs/
2. Port valuable content from docs-archive-2025-11-01T10-30-00/
3. Delete archive once confirmed (or keep for history)

Note: Generated docs reflect current codebase. Old docs preserved in archive.
```

### Recovery Process

If user wants old docs back:

```bash
# Restore archived docs
rm -rf docs/
mv docs-archive-2025-11-01T10-30-00/ docs/

# Re-run init if you want to try again later
/spec-drive:init
```

---

## Consequences

### Positive

1. **Consistent baseline**
   - New projects: Full docs from planning
   - Existing projects: Full docs from code analysis
   - Same 12-doc structure, same quality, same accuracy

2. **Fresh, accurate documentation**
   - Docs reflect current code (not stale)
   - Components detected from actual code (not manual list)
   - Data flows inferred from imports (not outdated diagrams)

3. **Simple implementation**
   - No merging logic (complex, error-prone)
   - Archive + regenerate (straightforward)
   - Clear semantics (old gone, new fresh)

4. **Recoverable**
   - Old docs archived, not deleted
   - User can review archive, port valuable content
   - Safety net for important information

5. **Forcing function**
   - Aggressive approach forces project to adopt new structure
   - Proves value quickly (complete docs immediately)
   - No half-measures (fully spec-drive or not)

### Negative

1. **Manual content lost**
   - Existing docs may have valuable manual content (design rationale, architectural notes)
   - User must manually port from archive if valuable
   - ❌ Time investment required (review archive, port content)
   - **Mitigation:** Auto-generated docs have AUTO markers where manual content can be added

2. **Disruption**
   - Significant change to project structure
   - Team must adapt to new doc organization
   - ❌ Initial friction during adoption
   - **Mitigation:** Clear communication, migration guide

3. **One-time cost**
   - Porting manual content takes time (30-60 min typical)
   - Reviewing generated docs for accuracy (30 min)
   - ❌ Upfront investment
   - **Mitigation:** One-time cost, ongoing benefit

4. **Trust requirement**
   - User must trust auto-generation produces good docs
   - Risk: Generated docs incomplete or inaccurate
   - ❌ User may reject approach if quality low
   - **Mitigation:** High-quality code analysis, clear AUTO markers showing what's generated

### Trade-offs

**Chose consistency over preservation:**
- Same baseline for all projects vs preserve existing docs
- Benefit: Predictable structure, no inconsistency

**Chose simplicity over sophistication:**
- Archive + regenerate vs intelligent merging
- Benefit: Clear, deterministic, no merge conflicts

**Chose aggressive over conservative:**
- Force adoption vs gradual migration
- Benefit: Proves value quickly, no half-measures

---

## Alternatives Considered

### Preserve Existing Docs (Conservative) - Rejected

**Implementation:**
```bash
# Keep existing docs/, only generate missing
if [ ! -f "docs/ARCHITECTURE.md" ]; then
  generate_architecture_doc
fi
```

**Why rejected:**
- Inconsistent (each project different based on what existed)
- Outdated docs persist (doesn't solve documentation drift)
- Limited value (just fills gaps, doesn't fix existing problems)

### Intelligent Merging (Hybrid) - Rejected

**Implementation:**
```javascript
// AI-based merging of existing + generated
const existingContent = readExistingDoc();
const generatedContent = generateFromCode();
const merged = aiMerge(existingContent, generatedContent);  // Complex!
```

**Why rejected:**
- Complex implementation (AI-based merging unreliable)
- Unpredictable results (each merge unique)
- Still risk outdated info (AI might preserve old content)
- v0.1 complexity budget (keep simple)

### Per-Doc User Choice (Manual) - Rejected

**Implementation:**
```bash
for doc in docs/*.md; do
  echo "Found existing: $doc"
  read -p "Keep, Replace, or Merge? (k/r/m): " choice
  # Process based on choice
done
```

**Why rejected:**
- Poor UX (too many prompts)
- Cognitive overload (user doesn't know which docs outdated)
- Slow (manual review of 12+ docs)
- Inconsistent results (depends on user choices)

### Gradual Migration (Incremental) - Rejected

**Implementation:**
```bash
# Generate one doc at a time over multiple runs
/spec-drive:migrate-docs --doc=ARCHITECTURE.md
/spec-drive:migrate-docs --doc=COMPONENT-CATALOG.md
# ... repeat 12 times
```

**Why rejected:**
- Slow adoption (takes weeks to migrate all docs)
- Inconsistent state (half old, half new docs)
- No immediate value (partial migration unhelpful)

---

## Implementation Notes

### Archive Naming

```bash
# Timestamp format: ISO-8601 compatible, filesystem-safe
TIMESTAMP=$(date +"%Y-%m-%dT%H-%M-%S")
ARCHIVE_DIR="docs-archive-${TIMESTAMP}"

# Examples:
# docs-archive-2025-11-01T10-30-00/
# docs-archive-2025-11-01T14-15-30/
```

**Sorting:** Lexicographic sort = chronological order (latest last).

### Rollback Support

```bash
# scripts/tools/rollback-init.sh
# Restore most recent archive

LATEST_ARCHIVE=$(ls -1d docs-archive-* | sort | tail -1)
if [ -n "$LATEST_ARCHIVE" ]; then
  rm -rf docs/
  mv "$LATEST_ARCHIVE" docs/
  echo "Restored: $LATEST_ARCHIVE → docs/"
else
  echo "No archive found"
fi
```

### Code Analysis Depth

**Full analysis for existing projects:**

```javascript
// scripts/tools/analyze-codebase.js
async function analyzeExistingProject(projectRoot) {
  return {
    components: detectComponents(projectRoot),      // Classes, functions, modules
    dependencies: buildDependencyGraph(projectRoot), // Import/require analysis
    patterns: detectPatterns(projectRoot),           // MVC, layered, microservices
    techStack: detectTechStack(projectRoot),         // package.json, imports
    apis: detectAPIs(projectRoot),                   // Exported functions/classes
    tests: detectTests(projectRoot),                 // Test files, coverage
  };
}
```

**Performance:** <60s for medium codebase (~10k LOC).

### Manual Content Markers

Generated docs include AUTO markers:

```markdown
<!-- AUTO: Component list below -->
## Components

- AuthService - Handles user authentication
- UserRepository - Database access for users

<!-- AUTO: End component list -->

## Design Decisions

[MANUAL: Add architectural decisions here]
```

**Purpose:**
- Show which sections auto-generated
- Indicate where manual content should go
- Help user port content from archive

---

## Related Decisions

- **ADR-001:** YAML format for specs (code analysis outputs YAML)
- **ADR-003:** Stage-boundary autodocs (how docs stay fresh after init)
- **DECISIONS.md Decision #4:** `.spec-drive/` hidden structure

---

## Future Evolution (v0.2+)

### Opt-Out (Conservative Mode)

```yaml
# config.yaml
init:
  mode: "aggressive"  # or "conservative", "hybrid"
```

If `conservative`, preserve existing docs, only generate missing.

### Content Preservation Hints

```markdown
<!-- PRESERVE: This section has valuable manual content -->
## Security Architecture

[Manual content here that should not be overwritten]

<!-- PRESERVE: End section -->
```

Auto-generation respects PRESERVE markers, doesn't overwrite.

### Diff-Based Migration

```bash
# Show user what changed between old and new docs
/spec-drive:init --dry-run
# Output: Diffs for each doc (old vs generated)
# User reviews, approves
```

---

## References

- [TDD.md Section 5.2](../TDD.md) - Autodocs architecture
- [TDD.md Section 6.6](../TDD.md) - Autodocs tools (analyze-codebase.js)
- [PRD.md](../PRD.md) - Initialization behavior

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 3 (autodocs system)
- Trade-off: Consistency + simplicity over preservation
- User communication critical (explain archival, recovery)
