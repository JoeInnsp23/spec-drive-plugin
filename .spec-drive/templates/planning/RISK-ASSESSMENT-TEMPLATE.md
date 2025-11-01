# {{PROJECT_NAME}} {{VERSION}} RISK ASSESSMENT

**Version:** {{DOC_VERSION}}
**Date:** {{DATE}}
**Status:** Draft | Active | Complete
**Related PRD:** {{PRD_PATH}}

---

## 1. OVERVIEW

### Purpose

Identify, assess, and plan mitigation strategies for risks in {{VERSION}} development.

### Risk Assessment Matrix

| Impact / Likelihood | Low | Medium | High |
|---------------------|-----|--------|------|
| **High** | Medium Risk | High Risk | Critical Risk |
| **Medium** | Low Risk | Medium Risk | High Risk |
| **Low** | Low Risk | Low Risk | Medium Risk |

---

## 2. CRITICAL RISKS

### RISK-001: {{Risk Name}}

**Category:** Technical | Schedule | Resource | Quality | External

**Description:**
{{Detailed description of the risk}}

**Impact:** High | Medium | Low
{{Specific impact if risk occurs}}

**Likelihood:** High (>60%) | Medium (30-60%) | Low (<30%)
{{Why this likelihood}}

**Risk Score:** {{Impact × Likelihood}} (1-9 scale)

**Current Status:** {{Status}}

**Mitigation Strategy:**
1. {{Mitigation action 1}}
2. {{Mitigation action 2}}
3. {{Mitigation action 3}}

**Contingency Plan:**
If mitigation fails:
1. {{Contingency action 1}}
2. {{Contingency action 2}}

**Owner:** {{Who is responsible}}

**Timeline:** {{When to implement mitigation}}

**Monitoring:**
- {{What to monitor}}
- {{Frequency of monitoring}}

**Triggers:**
- {{Condition that indicates risk is occurring}}
- {{Threshold for activating contingency}}

**Related Tasks:** TASK-XXX, TASK-YYY

---

### RISK-002: {{Risk Name}}

{{Similar structure}}

---

## 3. HIGH RISKS

### RISK-003: {{Risk Name}}

{{Similar structure but perhaps less detail than critical risks}}

---

## 4. MEDIUM RISKS

### RISK-005: {{Risk Name}}

{{Similar structure}}

---

## 5. LOW RISKS

### RISK-008: {{Risk Name}}

**Description:** {{Brief description}}

**Impact:** Low

**Likelihood:** Low

**Mitigation:** {{Simple mitigation if needed}}

---

## 6. RISK SUMMARY

### Risk Distribution

| Category | Critical | High | Medium | Low | Total |
|----------|----------|------|--------|-----|-------|
| Technical | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |
| Schedule | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |
| Resource | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |
| Quality | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |
| External | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |
| **Total** | {{N}} | {{N}} | {{N}} | {{N}} | {{N}} |

### Top 5 Risks (by score)

1. RISK-XXX: {{Risk name}} (Score: {{N}})
2. RISK-XXX: {{Risk name}} (Score: {{N}})
3. RISK-XXX: {{Risk name}} (Score: {{N}})
4. RISK-XXX: {{Risk name}} (Score: {{N}})
5. RISK-XXX: {{Risk name}} (Score: {{N}})

---

## 7. DEPENDENCY RISKS

### External Dependencies

| Dependency | Risk | Impact | Mitigation |
|------------|------|--------|------------|
| {{Dependency}} | {{Risk}} | {{Impact}} | {{Mitigation}} |

### Internal Dependencies

| Component | Dependency | Risk | Mitigation |
|-----------|------------|------|------------|
| {{Component}} | {{Depends on}} | {{Risk}} | {{Mitigation}} |

---

## 8. ASSUMPTION TRACKING

### Critical Assumptions

| Assumption | Impact if Wrong | Validation Method | Status |
|------------|-----------------|-------------------|--------|
| {{Assumption}} | {{Impact}} | {{How to validate}} | Valid | Invalid | Unknown |

---

## 9. RISK MITIGATION STATUS

### Mitigation Progress

| Risk ID | Mitigation Actions | Progress | Target Date | Owner |
|---------|-------------------|----------|-------------|-------|
| RISK-001 | {{Actions}} | {{%}} | {{DATE}} | {{OWNER}} |
| RISK-002 | {{Actions}} | {{%}} | {{DATE}} | {{OWNER}} |

---

## 10. ESCALATION PROCEDURES

### When to Escalate

Escalate to {{STAKEHOLDER}} if:
- {{Condition 1}}
- {{Condition 2}}

### Escalation Path

1. {{Level 1}} - {{Role}} - {{Timeframe}}
2. {{Level 2}} - {{Role}} - {{Timeframe}}
3. {{Level 3}} - {{Role}} - {{Timeframe}}

---

## 11. RISK MONITORING

### Monitoring Schedule

| Frequency | Activities | Owner |
|-----------|-----------|-------|
| Daily | {{What to check}} | {{Who}} |
| Weekly | {{What to review}} | {{Who}} |
| Sprint End | {{What to assess}} | {{Who}} |

### Risk Indicators

**Leading Indicators** (predict future risks):
- {{Indicator 1}}
- {{Indicator 2}}

**Lagging Indicators** (show risk occurred):
- {{Indicator 1}}
- {{Indicator 2}}

---

## 12. RISK HISTORY

### Risks Realized

| Risk ID | Date Occurred | Impact | Resolution | Lessons Learned |
|---------|--------------|--------|------------|-----------------|
| RISK-XXX | {{DATE}} | {{Impact}} | {{How resolved}} | {{Lesson}} |

### Risks Retired

| Risk ID | Date Retired | Reason |
|---------|-------------|--------|
| RISK-XXX | {{DATE}} | {{Why no longer a risk}} |

---

## 13. CHANGE LOG

| Date | Risk ID | Change | Reason | Updated By |
|------|---------|--------|--------|------------|
| {{DATE}} | RISK-001 | Added | {{Reason}} | {{NAME}} |
| {{DATE}} | RISK-003 | Increased likelihood | {{Reason}} | {{NAME}} |
| {{DATE}} | RISK-005 | Retired | {{Reason}} | {{NAME}} |

---

**Document Status:** {{Status}}
**Next Review Date:** {{DATE}}

---

**Reviewed By:** [Pending]
**Approved By:** [Pending]
**Date:** [Pending]
