# {{PROJECT_NAME}} {{VERSION}} TEST PLAN

**Version:** {{DOC_VERSION}}
**Date:** {{DATE}}
**Status:** Draft | Active | Complete
**Related PRD:** {{PRD_PATH}}
**Related TDD:** {{TDD_PATH}}

---

## 1. TEST OVERVIEW

### Scope

**In Scope:**
- {{Feature/component to test}}
- {{Feature/component to test}}

**Out of Scope:**
- {{Feature/component not tested}}
- {{Feature/component not tested}}

### Test Objectives

1. {{Objective 1}}
2. {{Objective 2}}
3. {{Objective 3}}

### Success Criteria

- ✅ {{Success criterion 1}}
- ✅ {{Success criterion 2}}
- ✅ {{Success criterion 3}}

---

## 2. TEST STRATEGY

### Test Levels

| Level | Coverage | Responsibility | When |
|-------|----------|----------------|------|
| Unit | {{percentage}}% | {{Who}} | {{When}} |
| Integration | {{scenarios}} | {{Who}} | {{When}} |
| End-to-End | {{scenarios}} | {{Who}} | {{When}} |
| Manual | {{scenarios}} | {{Who}} | {{When}} |

### Test Approach

**Unit Testing:**
- {{Approach for unit tests}}

**Integration Testing:**
- {{Approach for integration tests}}

**End-to-End Testing:**
- {{Approach for E2E tests}}

---

## 3. TEST SCENARIOS

### Scenario 1: {{Scenario Name}}

**ID:** TS-001
**Priority:** Critical | High | Medium | Low
**Type:** Unit | Integration | E2E | Manual

**Objective:** {{What this tests}}

**Preconditions:**
- {{Precondition 1}}
- {{Precondition 2}}

**Test Steps:**
1. {{Step 1}}
2. {{Step 2}}
3. {{Step 3}}

**Expected Results:**
- {{Expected result 1}}
- {{Expected result 2}}

**Actual Results:** [To be filled during execution]

**Status:** Not Run | Passed | Failed | Blocked

**Notes:** {{Any additional notes}}

---

### Scenario 2: {{Scenario Name}}

{{Similar structure}}

---

## 4. TEST CASES

### TC-001: {{Test Case Name}}

**Scenario:** TS-001
**Component:** {{Component being tested}}
**Type:** Positive | Negative | Edge Case

**Input:**
```
{{Input data}}
```

**Steps:**
1. {{Step}}
2. {{Step}}

**Expected Output:**
```
{{Expected output}}
```

**Actual Output:** [Filled during execution]

**Pass/Fail:** [Filled during execution]

---

### TC-002: {{Test Case Name}}

{{Similar structure}}

---

## 5. EDGE CASES & ERROR SCENARIOS

### Edge Case 1: {{Description}}

**What happens:** {{Scenario}}

**Expected behavior:** {{How system should respond}}

**Test case:** TC-XXX

---

### Error Scenario 1: {{Description}}

**Error condition:** {{What causes error}}

**Expected handling:** {{How error should be handled}}

**Test case:** TC-XXX

---

## 6. PERFORMANCE TESTS

### Performance Test 1: {{Test Name}}

**Metric:** {{What we're measuring}}

**Target:** {{Target value}}

**Maximum Acceptable:** {{Max value}}

**Test Method:**
```
{{How to measure}}
```

**Results:** [Filled during execution]

---

## 7. REGRESSION TESTS

### Regression Suite

**Components to regression test:**
- {{Component 1}} - {{Why}}
- {{Component 2}} - {{Why}}

**Regression test cases:**
- TC-XXX - {{Description}}
- TC-XXX - {{Description}}

---

## 8. TEST DATA

### Test Data Set 1: {{Name}}

**Purpose:** {{What this data tests}}

**Data:**
```
{{Test data}}
```

**Location:** `{{file path if external}}`

---

## 9. TEST ENVIRONMENT

### Environment Setup

**Requirements:**
- {{Requirement 1}}
- {{Requirement 2}}

**Setup Steps:**
1. {{Step 1}}
2. {{Step 2}}

**Verification:**
```bash
# Commands to verify environment ready
command1
command2
```

---

## 10. TEST EXECUTION

### Execution Schedule

| Phase | Tests | Start Date | End Date | Owner |
|-------|-------|------------|----------|-------|
| Unit Testing | TC-001 to TC-050 | {{DATE}} | {{DATE}} | {{OWNER}} |
| Integration | TS-001 to TS-010 | {{DATE}} | {{DATE}} | {{OWNER}} |
| E2E | TS-011 to TS-020 | {{DATE}} | {{DATE}} | {{OWNER}} |

### Execution Log

| Date | Test ID | Result | Notes | Executed By |
|------|---------|--------|-------|-------------|
| {{DATE}} | TC-001 | Pass | {{Notes}} | {{NAME}} |
| {{DATE}} | TC-002 | Fail | {{Bug ID}} | {{NAME}} |

---

## 11. DEFECT TRACKING

### Defects Found

| ID | Severity | Component | Description | Status | Assigned To |
|----|----------|-----------|-------------|--------|-------------|
| BUG-001 | Critical | {{Component}} | {{Description}} | Open | {{OWNER}} |
| BUG-002 | High | {{Component}} | {{Description}} | Fixed | {{OWNER}} |

---

## 12. TEST COVERAGE

### Unit Test Coverage

| Component | Lines | Branches | Functions | Coverage % |
|-----------|-------|----------|-----------|------------|
| {{Component}} | {{N/M}} | {{N/M}} | {{N/M}} | {{%}} |

**Overall Coverage:** {{percentage}}%

### Feature Coverage

| Feature | Test Cases | Pass | Fail | Coverage |
|---------|-----------|------|------|----------|
| {{Feature}} | {{Count}} | {{Count}} | {{Count}} | {{%}} |

---

## 13. ENTRY & EXIT CRITERIA

### Entry Criteria

Before testing can begin:
- [ ] {{Criterion 1}}
- [ ] {{Criterion 2}}
- [ ] {{Criterion 3}}

### Exit Criteria

Testing is complete when:
- [ ] {{Criterion 1}}
- [ ] {{Criterion 2}}
- [ ] {{Criterion 3}}

---

## 14. RISKS

| Risk | Impact | Mitigation |
|------|--------|------------|
| {{Risk}} | {{Impact}} | {{Mitigation}} |

---

## 15. TEST RESULTS SUMMARY

**Execution Date:** {{DATE}}

**Results:**
- Total Test Cases: {{COUNT}}
- Passed: {{COUNT}} ({{%}}%)
- Failed: {{COUNT}} ({{%}}%)
- Blocked: {{COUNT}} ({{%}}%)
- Not Run: {{COUNT}} ({{%}}%)

**Defects:**
- Critical: {{COUNT}}
- High: {{COUNT}}
- Medium: {{COUNT}}
- Low: {{COUNT}}

**Recommendation:** {{Pass | Fail | Conditional Pass}}

**Reason:** {{Justification}}

---

## 16. LESSONS LEARNED

- {{Lesson 1}}
- {{Lesson 2}}
- {{Lesson 3}}

---

**Document Status:** {{Status}}
**Next Steps:** {{What happens next}}

---

**Reviewed By:** [Pending]
**Approved By:** [Pending]
**Date:** [Pending]
