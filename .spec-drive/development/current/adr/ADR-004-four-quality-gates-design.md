# ADR-004: Four Quality Gates Design

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #12, [TDD.md](../TDD.md) Section 5.3

---

## Context

spec-drive's spec-driven development system (System 3) enforces workflow discipline through quality gates. Gates ensure work meets quality criteria before advancing to the next stage.

### Design Decisions Required

1. **How many gates?** (2, 3, 4, 5+?)
2. **Where do gates go?** (between which stages?)
3. **What does each gate check?**
4. **How are gates enforced?** (advisory vs blocking?)
5. **Who runs gates?** (automatic vs manual?)

### Workflow Stages (Fixed)

Based on industry best practices (RUP, SAFe, Waterfall adaptations):

```
DISCOVER → SPECIFY → IMPLEMENT → VERIFY → DONE
```

- **Discover:** Explore context, gather requirements
- **Specify:** Write spec with acceptance criteria
- **Implement:** Code + tests with @spec tags
- **Verify:** All quality checks pass, docs updated

### Gate Placement Options Evaluated

**Option A: No gates (trust-based)**
- User advances stages manually, no automated checks
- ❌ No enforcement (defeats purpose of spec-drive)
- ❌ Shortcuts will happen (incomplete specs, missing tests)

**Option B: Single gate (final check only)**
- One gate between Verify → Done
- ❌ Too late (problems discovered at end)
- ❌ Rework expensive (redo multiple stages)

**Option C: Three gates**
- Specify → Implement, Implement → Verify, Verify → Done
- ✅ Covers critical transitions
- ⚠️ No check after Discover (spec could be created prematurely)

**Option D: Four gates**
- After each stage: Discover → Specify → Implement → Verify → Done
- ✅ Every transition validated
- ✅ Catch problems early (fail fast)
- ✅ Clear responsibility per gate
- ✅ Incremental validation (small checkpoints)
- ⚠️ More overhead (4 gate executions per feature)

**Option E: Five+ gates (micro-checkpoints)**
- Gates within stages (e.g., mid-implementation checks)
- ❌ Too granular (interrupts flow)
- ❌ Overhead without benefit

---

## Decision

**We will implement four quality gates, one after each workflow stage.**

### Gate Responsibilities

**Gate 1: Discover → Specify**
- **Purpose:** Ensure planning complete before writing spec
- **Checks:**
  - Spec file created (`.spec-drive/specs/SPEC-ID.yaml`)
  - No `[NEEDS CLARIFICATION]` markers
  - Success criteria defined and measurable
- **Script:** `scripts/gates/gate-1-specify.sh`
- **Failure:** Cannot advance to Specify stage

**Gate 2: Specify → Implement**
- **Purpose:** Ensure spec is complete and implementable
- **Checks:**
  - All acceptance criteria testable and unambiguous
  - API contracts defined (if applicable)
  - Test scenarios outlined in spec
- **Script:** `scripts/gates/gate-2-implement.sh`
- **Failure:** Cannot advance to Implement stage

**Gate 3: Implement → Verify**
- **Purpose:** Ensure implementation complete with tests
- **Checks:**
  - All tests pass (`npm test`)
  - `@spec SPEC-ID` tags present in code (`src/`)
  - `@spec SPEC-ID` tags present in tests (`tests/`)
  - No linting errors (`npm run lint`)
  - No typecheck errors (if TypeScript)
- **Script:** `scripts/gates/gate-3-verify.sh`
- **Failure:** Cannot advance to Verify stage

**Gate 4: Verify → Done**
- **Purpose:** Ensure complete, documented, traceable feature
- **Checks:**
  - All acceptance criteria met (manual verification)
  - Documentation updated (dirty flag cleared)
  - No TODO/console.log/placeholders (`grep` check)
  - Traceability complete (index.yaml has traces)
  - Feature doc exists (`docs/60-features/SPEC-ID.md`)
- **Script:** `scripts/gates/gate-4-done.sh`
- **Failure:** Cannot mark spec as done

### Enforcement Mechanism

**Blocking enforcement:**

```yaml
# .spec-drive/state.yaml
current_stage: "implement"
can_advance: false  # Set by gate scripts

# Behavior agent checks can_advance before allowing stage advancement
# If false, stops with message: "Gate failed, cannot advance"
```

**Automatic execution:**

Gates run automatically when workflow script requests stage advancement:

```bash
# scripts/workflows/feature.sh
scripts/gates/gate-3-verify.sh $SPEC_ID
if [ $? -eq 0 ]; then
  yq eval '.can_advance = true' -i .spec-drive/state.yaml
  yq eval '.current_stage = "verify"' -i .spec-drive/state.yaml
else
  yq eval '.can_advance = false' -i .spec-drive/state.yaml
  echo "❌ Gate 3 failed. Fix issues before advancing."
fi
```

---

## Consequences

### Positive

1. **Incremental validation**
   - Catch problems early (fail fast)
   - Small checkpoints easier to fix than big problems at end
   - Clear feedback: which gate failed tells you what's wrong

2. **Clear responsibilities**
   - Each gate has specific, well-defined checks
   - No ambiguity about what needs to pass
   - Gate scripts are reference implementation of quality criteria

3. **Prevent shortcuts**
   - Cannot skip stages (gates block advancement)
   - Cannot merge incomplete work (gate-4 ensures completeness)
   - Enforces discipline (todos must be resolved, tests must pass)

4. **Traceability enforcement**
   - Gate-3 requires @spec tags (no tags = no advance)
   - Gate-4 verifies traceability (index.yaml must have traces)
   - 100% coverage guaranteed by gate enforcement

5. **Documentation enforcement**
   - Gate-4 checks dirty flag (docs must be updated)
   - Gate-4 verifies feature doc exists
   - Docs-first enforced (can't complete without docs)

### Negative

1. **Development overhead**
   - 4 gate executions per feature (vs 0 without gates)
   - Gate-3 can be slow (runs test suite, ~10s typical)
   - **Mitigation:** Acceptable cost for quality assurance
   - **Optimization:** Gates run only at stage boundaries (not frequent)

2. **Friction if tests failing**
   - Cannot advance if tests fail (intentional, but feels slow)
   - Developer must fix tests before moving forward
   - **Mitigation:** This is the point - enforce test discipline
   - **Design:** Fail fast better than fail late

3. **Rigid workflow**
   - Cannot skip stages even if justified
   - Some features may not need all stages
   - **Mitigation:** v0.2 can add gate overrides (with justification)
   - **Reasoning:** v0.1 proves discipline value, flexibility later

4. **Gate script maintenance**
   - 4 scripts to maintain (vs 1 final check)
   - Changes to quality criteria require updating multiple gates
   - **Mitigation:** Scripts are simple, clear, well-documented
   - **Design:** One responsibility per gate (easy to understand/modify)

### Trade-offs

**Chose thoroughness over speed:**
- 4 gates slower than 1-2 gates
- Benefit: catch problems earlier (cheaper to fix)

**Chose enforcement over flexibility:**
- Cannot skip gates (vs advisory warnings)
- Benefit: consistent quality, no shortcuts

**Chose automation over manual:**
- Gates run automatically (vs user trigger)
- Benefit: cannot forget to run gates

---

## Alternatives Considered

### Three Gates (Discover Not Gated) - Rejected

**Gates:** Specify → Implement, Implement → Verify, Verify → Done

**Why rejected:**
- No check that spec is created before Specify stage
- User could jump straight to Specify without Discovery
- Inconsistent (why gate 3 transitions but not 1?)

### Two Gates (Plan + Execute) - Rejected

**Gates:** Specify → Implement (planning done), Verify → Done (execution done)

**Why rejected:**
- Too coarse (large gaps between validation)
- Implement → Verify not gated (no check that tests pass before verification)
- Misses opportunity for incremental feedback

### Five Gates (Including Mid-Stage) - Rejected

**Gates:** After Discover, mid-Specify, after Specify, mid-Implement, after Implement, Verify

**Why rejected:**
- Too granular (interrupts flow)
- Unclear what mid-stage gates would check
- Overhead without clear benefit

### Advisory Gates (Warnings Only) - Rejected

**Implementation:**
```bash
# Gate fails but doesn't block
echo "⚠️ WARNING: Tests failing, but continuing anyway"
yq eval '.can_advance = true' -i state.yaml  # Always allow advancement
```

**Why rejected:**
- Defeats purpose (developers will ignore warnings)
- Same problem as no gates (shortcuts happen)
- spec-drive value is enforcement, not advisories

---

## Implementation Notes

### Gate Script Pattern

All gates follow this pattern:

```bash
#!/bin/bash
# gate-N-stage.sh
# Purpose: [What this gate validates]
# Inputs: $1 = SPEC-ID
# Outputs: Exit 0 (pass) or 1 (fail)

SPEC_ID=$1

# Check 1: [Criteria]
if [condition]; then
  echo "❌ Gate N FAILED: [Specific failure message]"
  exit 1
fi

# Check 2: [Criteria]
# ...

echo "✅ Gate N PASSED: [Success message]"
exit 0
```

**Characteristics:**
- Single responsibility (one purpose per gate)
- Clear error messages (tell user exactly what's wrong)
- Exit code enforcement (0=pass, 1=fail, no ambiguity)
- Fast execution (<2s typical, <10s for gate-3 with tests)

### Gate Execution Context

Gates run in project root:

```bash
# pwd: /path/to/user/project
scripts/gates/gate-3-verify.sh AUTH-001

# Gate has access to:
# - .spec-drive/specs/AUTH-001.yaml
# - .spec-drive/state.yaml
# - src/ (code)
# - tests/ (test files)
# - package.json (for npm test, npm run lint)
```

### State Management

```yaml
# Before gate runs
current_stage: "implement"
can_advance: false  # Assume cannot advance until gate passes

# Gate script execution
scripts/gates/gate-3-verify.sh AUTH-001
# Returns: exit 0 (pass)

# Workflow updates state
yq eval '.can_advance = true' -i state.yaml
yq eval '.current_stage = "verify"' -i state.yaml

# Behavior agent checks state before allowing work in new stage
```

### Error Reporting

**Gate failure output:**

```
❌ Gate 3 FAILED: No @spec AUTH-001 tags found in tests/
Remediation: Add /** @spec AUTH-001 */ tags to test files

Found @spec tags in code:
  src/auth/login.ts:42
  src/auth/session.ts:18

Missing @spec tags in tests:
  tests/auth/ (no files tagged)

Run this to find test files:
  find tests/ -name "*.test.ts"

Then add tags:
  /** @spec AUTH-001 */
  describe('login', () => { ... });
```

**Design:** Clear, actionable error messages with remediation steps.

---

## Related Decisions

- **ADR-002:** SessionStart hook auto-injection (loads behavior that enforces gates)
- **ADR-003:** Stage-boundary autodocs (gates trigger autodocs)
- **ADR-006:** JSDoc-style @spec tags (what gate-3 validates)

---

## Future Evolution (v0.2+)

### Gate Overrides

```yaml
# config.yaml
gates:
  gate-3-verify:
    enabled: true
    checks:
      tests_pass: true
      spec_tags: true
      lint_clean: false  # Disable lint check for this project
```

Allow per-project gate customization.

### Custom Gates

```yaml
# config.yaml
gates:
  custom:
    - name: "security-scan"
      script: "scripts/gates/custom-security.sh"
      stage: "implement"  # Run after Implement stage
```

Allow projects to add domain-specific gates.

### Gate Analytics

```yaml
# Track gate pass/fail rates
.spec-drive/logs/gate-analytics.yaml:
  gate-1: {runs: 50, passes: 48, failures: 2, avg_time: 0.3s}
  gate-2: {runs: 48, passes: 47, failures: 1, avg_time: 0.5s}
  gate-3: {runs: 47, passes: 42, failures: 5, avg_time: 8.2s}
  gate-4: {runs: 42, passes: 42, failures: 0, avg_time: 1.1s}
```

Identify problematic gates, optimize slow gates.

---

## References

- [TDD.md Section 5.3](../TDD.md) - Quality gates detail
- [TDD.md Section 6.5](../TDD.md) - Gate script component breakdown
- [PRD.md](../PRD.md) - Quality gates design

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 4 (quality gates)
- Performance target: <2s per gate (except gate-3 with tests)
- Trade-off: Thoroughness over speed
