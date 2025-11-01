# v0.1 Key Decisions Summary

**Last Updated:** 2025-11-01 (Documentation Phase Complete)
**Status:** Frozen for v0.1 implementation

Quick reference for major architectural decisions. See adr/ folder for detailed rationale.

**All 7 ADRs Complete:**
- ADR-001: YAML format for specs ✅
- ADR-002: SessionStart hook auto-injection ✅
- ADR-003: Stage-boundary autodocs updates ✅
- ADR-004: Four quality gates design ✅
- ADR-005: Aggressive existing project init ✅
- ADR-006: JSDoc-style @spec tags ✅
- ADR-007: Single state file (vs per-feature) ✅

---

## Core Architecture Decisions

### 1. Three Integrated Systems
**Decision:** Build behavior optimization + autodocs + spec-driven as ONE unified system
**Rationale:** All three problems interconnected - better behavior → better code → better docs
**Reference:** PRD Section 2 (Problem Statement)

### 2. Identical Structure (Plugin & User Projects)
**Decision:** spec-drive plugin uses EXACT same structure it creates for users
**Rationale:** Dogfooding - proves system works, provides reference implementation
**Reference:** PRD Section 11 (Appendix)

---

## Data & Storage Decisions

### 3. YAML for Specs (vs JSON)
**Decision:** Use YAML format for spec files
**Rationale:** Human-readable, supports comments, widely adopted
**ADR:** [ADR-001](./adr/ADR-001-yaml-format-for-specs.md) ✅
**Alternatives Rejected:** JSON (no comments), TOML (less common)

### 4. .spec-drive/ Hidden Structure
**Decision:** All internal data in `.spec-drive/` folder (config, state, index, schemas, specs, development)
**Rationale:** Clean root, no pollution, everything organized in one place
**Impact:** Users only see `docs/` in root (product documentation)

### 5. specs/ Inside .spec-drive/
**Decision:** Specs live in `.spec-drive/specs/` not project root
**Rationale:** Keeps root clean, aligns with hidden internal structure
**Impact:** All references use `.spec-drive/specs/SPEC-XXX.yaml`

### 6. schemas/ Inside .spec-drive/
**Decision:** Validation schemas in `.spec-drive/schemas/v0.1/`
**Rationale:** Schemas are implementation detail, versioned for evolution
**Impact:** Not user-facing, regenerable, gitignored possible

### 7. development/ Inside .spec-drive/
**Decision:** Planning docs (PRD, TDD, plans) in `.spec-drive/development/`
**Rationale:** Separates planning docs from product docs, version-controlled properly
**Structure:** current/planned/completed/archive for clear workflow

### 8. Single State File (vs Per-Feature)
**Decision:** Use single `state.yaml` file with workflow history
**Rationale:** Simpler implementation, atomic updates, clear current context
**ADR:** [ADR-007](./adr/ADR-007-single-state-file-vs-per-feature.md) ✅
**Alternatives Rejected:** Per-feature files (complex), SQLite (overkill), tracked state (merge conflicts)
**Trade-off:** Serial workflows (one at a time) in v0.1, parallelism deferred to v0.2

### 9. Git Tracking Strategy
**Tracked:** config.yaml, index.yaml, schemas/, specs/, development/
**Gitignored:** state.yaml (runtime only)
**Rationale:** State is ephemeral, everything else is source of truth

---

## Behavior & Workflow Decisions

### 10. SessionStart Hook Auto-Injection
**Decision:** Behavior agent (strict-concise) auto-injects via SessionStart hook
**Rationale:** Always-on enforcement, no user opt-in required
**ADR:** [ADR-002](./adr/ADR-002-sessionstart-hook-auto-injection.md) ✅
**Alternatives Rejected:** Manual activation (users forget), opt-in (adoption problem)

### 11. Stage-Boundary Autodocs Updates
**Decision:** Docs auto-update at workflow stage completions, not continuously
**Rationale:** Reduces churn, meaningful checkpoints, stable doc state
**ADR:** [ADR-003](./adr/ADR-003-stage-boundary-autodocs-updates.md) ✅
**Alternatives Rejected:** Continuous (too noisy), manual-only (defeats purpose)

### 12. JSDoc-Style @spec Tags
**Decision:** Use language-specific JSDoc-style traceability tags
**Format:** `/** @spec TAG-ID */` (TypeScript), `"""@spec TAG-ID"""` (Python)
**Rationale:** Lint-compatible, already understood by tooling, language-agnostic pattern
**ADR:** [ADR-006](./adr/ADR-006-jsdoc-style-spec-tags.md) ✅
**Alternatives Rejected:** Decorators (not universal), custom syntax (linting issues)

### 13. Four Quality Gates
**Decision:** Fixed 4-stage workflow with gates between each
**Stages:** Discover → Specify → Implement → Verify
**Enforcement:** Script-based gate checks, blocking advancement
**ADR:** [ADR-004](./adr/ADR-004-four-quality-gates-design.md) ✅

---

## Scope Decisions (v0.1)

### 14. Two Workflows Only
**Decision:** v0.1 ships with app-new + feature workflows only
**Deferred:** bugfix, research workflows (v0.2)
**Rationale:** Prove core system works before expanding
**Reference:** PRD Section 4

### 15. No Specialist Agents v0.1
**Decision:** Workflow DISCIPLINE not automation in v0.1
**Deferred:** spec-agent, impl-agent, test-agent (v0.2)
**Rationale:** Foundation first, automation second
**Reference:** PRD Section 4

### 16. Generic Stack Profile Only
**Decision:** v0.1 supports generic profile only
**Deferred:** TypeScript/React, Python/FastAPI profiles (v0.2)
**Rationale:** Prove architecture before customization
**Reference:** PRD Section 4

---

## Initialization Decisions

### 17. Aggressive Existing Project Init
**Decision:** Archive ALL old docs, regenerate from code
**Process:** Move `docs/` → `docs-archive-{timestamp}/`, full regeneration
**Rationale:** Same rich baseline for new AND existing projects
**Risk Mitigation:** Docs archived not deleted, user can recover
**ADR:** [ADR-005](./adr/ADR-005-aggressive-existing-project-init.md) ✅

---

## Future Decisions (Deferred to v0.2+)

- Stack profile system design
- Specialist agent architecture
- Multi-feature state management
- Context optimization strategy (AI summaries)
- Query patterns and changes feed
- Advanced traceability (auto-injection)

---

## Decision Template (for ADRs)

When writing ADRs, follow MADR format:

```markdown
# ADR-XXX: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
What is the issue motivating this decision?

## Decision
What change are we proposing/doing?

## Consequences
What becomes easier or harder?
- Positive consequences
- Negative consequences
- Trade-offs
```

---

**Maintained By:** Core Team
**Next Review:** When major decisions arise or v0.2 planning begins
