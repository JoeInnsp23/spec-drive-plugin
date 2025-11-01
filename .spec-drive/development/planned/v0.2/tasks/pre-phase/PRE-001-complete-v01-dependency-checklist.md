# Task PRE-001: Complete v0.1 Dependency Checklist

**Status:** Not Started
**Phase:** Pre-Phase (v0.1 Validation)
**Created:** 2025-11-01
**Updated:** 2025-11-01

---

## Overview

**CRITICAL BLOCKER:** Validate that v0.1 is 100% complete and tested before ANY v0.2 work begins. This task executes the entire v0.1 dependency checklist (150+ items from PRD Section 3) to ensure v0.2 builds on a solid foundation.

**RISK-001:** v0.1 incomplete blocks ALL v0.2 development (Critical, Score 9/9). This task mitigates that risk.

## Dependencies

**Prerequisite Tasks:**
- [x] v0.2 Planning complete (all planning documents created)

**Required Resources:**
- v0.1 codebase in `.spec-drive/development/current/`
- v0.1 PRD at `.spec-drive/development/current/PRD.md`
- v0.2 PRD with checklist at `.spec-drive/development/planned/v0.2/PRD.md` (Section 3)

## Acceptance Criteria

- [ ] All 150+ checklist items verified (100% complete)
- [ ] v0.1 behavior agent functional (SessionStart hook works)
- [ ] v0.1 autodocs functional (PostToolUse hook works)
- [ ] v0.1 spec-driven workflows functional (feature, app-new)
- [ ] v0.1 quality gates enforce correctly (4 gates implemented)
- [ ] TypeScript/React stack profile functional
- [ ] All v0.1 integration test scenarios documented
- [ ] Validation report generated (pass/fail per item)

## Implementation Details

### Files to Create/Modify

- `.spec-drive/development/planned/v0.2/PRE-VALIDATION-REPORT.md` - Checklist results
- `.spec-drive/development/planned/v0.2/v0.1-gaps.md` - Outstanding items (if any)

### Steps

1. **Load v0.1 Dependency Checklist**
   - What: Extract checklist from v0.2 PRD Section 3
   - How: Read `.spec-drive/development/planned/v0.2/PRD.md` lines with `- [ ]` checklist items
   - Verification: Count items (should be 150+)

2. **Verify Core Infrastructure**
   - What: Check SessionStart and PostToolUse hooks exist and execute
   - How:
     ```bash
     test -f .spec-drive/hooks/handlers/session-start.sh
     test -f .spec-drive/hooks/handlers/post-tool-use.sh
     claude code --version  # Verify Claude Code CLI works
     ```
   - Verification: Both files exist, both executable

3. **Verify Behavior Agent**
   - What: Confirm behavior agent loads on session start
   - How:
     ```bash
     # Start Claude Code session, check for behavior injection
     # Should see "Strict Concise" behavior loaded
     grep -q "strict-concise" .spec-drive/hooks/handlers/session-start.sh
     ```
   - Verification: Behavior agent prompt appears in session

4. **Verify Autodocs**
   - What: Confirm PostToolUse hook updates index.yaml
   - How:
     ```bash
     # Trigger PostToolUse (write test file)
     echo "test" > test.txt
     # Check index.yaml updated
     grep -q "test.txt" .spec-drive/index.yaml
     ```
   - Verification: index.yaml contains new file entry

5. **Verify Spec-Driven Workflows**
   - What: Confirm `/spec-drive:feature` and `/spec-drive:app-new` commands exist
   - How:
     ```bash
     test -f .spec-drive/commands/feature.md
     test -f .spec-drive/commands/app-new.md
     test -f .spec-drive/scripts/workflows/feature.sh
     test -f .spec-drive/scripts/workflows/app-new.sh
     ```
   - Verification: All workflow files exist

6. **Verify Quality Gates**
   - What: Confirm 4 quality gates implemented for feature workflow
   - How:
     ```bash
     test -f .spec-drive/scripts/gates/gate-1-discover.sh
     test -f .spec-drive/scripts/gates/gate-2-specify.sh
     test -f .spec-drive/scripts/gates/gate-3-implement.sh
     test -f .spec-drive/scripts/gates/gate-4-verify.sh
     ```
   - Verification: All gate scripts exist and executable

7. **Verify TypeScript/React Stack Profile**
   - What: Confirm typescript-react.yaml profile exists
   - How:
     ```bash
     test -f .spec-drive/stack-profiles/typescript-react.yaml
     yq validate .spec-drive/stack-profiles/typescript-react.yaml
     ```
   - Verification: Profile valid YAML

8. **Generate Validation Report**
   - What: Create PRE-VALIDATION-REPORT.md with pass/fail per checklist item
   - How: Iterate checklist, mark each item ✅ (pass) or ❌ (fail)
   - Verification: Report shows 100% pass rate

## Testing Approach

### Unit Tests
- N/A (validation task, not code implementation)

### Integration Tests
- Run manual verification commands above
- Document any failures in v0.1-gaps.md

### Manual Verification
```bash
# Complete validation script
cd .spec-drive/development/current

# Check core files exist
test -f PRD.md && echo "✓ PRD exists" || echo "✗ PRD missing"
test -f hooks/handlers/session-start.sh && echo "✓ SessionStart hook exists" || echo "✗ Missing"
test -f hooks/handlers/post-tool-use.sh && echo "✓ PostToolUse hook exists" || echo "✗ Missing"

# Check commands exist
ls -1 .spec-drive/commands/*.md | wc -l
# Expected: ≥2 (feature.md, app-new.md)

# Check gates exist
ls -1 .spec-drive/scripts/gates/gate-*.sh | wc -l
# Expected: 4 (4 gates)

# Check stack profiles exist
ls -1 .spec-drive/stack-profiles/*.yaml | wc -l
# Expected: ≥1 (typescript-react.yaml)

# Generate summary
echo "===== v0.1 VALIDATION SUMMARY ====="
echo "Hooks: $(ls .spec-drive/hooks/handlers/*.sh 2>/dev/null | wc -l)/2"
echo "Commands: $(ls .spec-drive/commands/*.md 2>/dev/null | wc -l)/2"
echo "Gates: $(ls .spec-drive/scripts/gates/gate-*.sh 2>/dev/null | wc -l)/4"
echo "Profiles: $(ls .spec-drive/stack-profiles/*.yaml 2>/dev/null | wc -l)/1"
```

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| v0.1 checklist <100% complete | Medium (50%) | Critical - Blocks v0.2 | STOP v0.2, complete v0.1 first |
| Missing v0.1 components | Medium (40%) | High - Rework required | Document gaps, prioritize completion |
| Checklist interpretation ambiguity | Low (20%) | Medium - Re-verification needed | Clarify with v0.1 PRD author |

## Completion Checklist

- [ ] All 150+ checklist items verified
- [ ] PRE-VALIDATION-REPORT.md created
- [ ] If gaps found, v0.1-gaps.md created
- [ ] 100% pass rate achieved (or v0.2 start delayed)
- [ ] Report reviewed by Development Lead
- [ ] Stakeholders notified of validation result
- [ ] Proceed to PRE-002 (regression testing) only if 100% pass

## Notes

**HARD BLOCKER:** If this task shows <100% pass rate, v0.2 Phase 1 CANNOT BEGIN. All outstanding v0.1 items must be completed first.

**Timeline Impact:** If v0.1 incomplete, accept timeline delay. Better to delay v0.2 than build on broken foundation.

---

**Related Documents:**
- PRD: `.spec-drive/development/planned/v0.2/PRD.md` (Section 3: v0.1 Dependency Checklist)
- TDD: `.spec-drive/development/planned/v0.2/TDD.md`
- Implementation Plan: `.spec-drive/development/planned/v0.2/IMPLEMENTATION-PLAN.md` (Pre-Phase)
- Risk Assessment: `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-001)
