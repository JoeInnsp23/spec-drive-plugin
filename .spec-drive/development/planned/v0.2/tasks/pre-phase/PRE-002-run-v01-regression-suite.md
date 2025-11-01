# Task PRE-002: Run v0.1 Regression Suite

**Status:** Not Started
**Phase:** Pre-Phase (v0.1 Validation)
**Created:** 2025-11-01
**Updated:** 2025-11-01

---

## Overview

Run all 4 v0.1 integration test scenarios to ensure v0.1 functionality works end-to-end before v0.2 development begins.

## Dependencies

**Prerequisite Tasks:**
- [ ] PRE-001 - Complete v0.1 Dependency Checklist

**Required Resources:**
- Test projects (TypeScript/React, Python/FastAPI)
- Claude Code CLI
- v0.1 integration test scenarios documented

## Acceptance Criteria

- [ ] Feature workflow (TypeScript/React project) completes successfully
- [ ] Feature workflow (Python/FastAPI project) completes successfully  
- [ ] App-new workflow (new project) completes successfully
- [ ] All 4 quality gates enforce correctly
- [ ] 100% pass rate on regression tests
- [ ] Test results documented

## Implementation Details

### Steps

1. **Test Feature Workflow (TypeScript)**
   ```bash
   cd test-projects/typescript-react
   /spec-drive:feature AUTH-001 "Add OAuth login"
   # Verify all 4 stages complete: discover → specify → implement → verify
   ```

2. **Test Feature Workflow (Python)**
   ```bash
   cd test-projects/python-fastapi
   /spec-drive:feature USER-001 "Add user endpoints"
   # Verify workflow completes
   ```

3. **Test App-New Workflow**
   ```bash
   /spec-drive:app-new my-new-app typescript-react
   # Verify project scaffolded correctly
   ```

4. **Test Quality Gates**
   ```bash
   # Intentionally fail gate, verify enforcement
   # (e.g., remove required field from spec → gate should fail)
   ```

## Testing Approach

### Manual Verification
```bash
# Run all scenarios, document results
echo "===== v0.1 REGRESSION TEST RESULTS ====="
echo "Feature (TypeScript): PASS/FAIL"
echo "Feature (Python): PASS/FAIL"
echo "App-New: PASS/FAIL"
echo "Quality Gates: PASS/FAIL"
```

---

**Related Documents:**
- Implementation Plan: `.spec-drive/development/planned/v0.2/IMPLEMENTATION-PLAN.md` (Pre-Phase)
