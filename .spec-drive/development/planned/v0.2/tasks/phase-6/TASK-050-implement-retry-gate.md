# Task TASK-050: Implement retry-gate.sh

**Status:** Not Started
**Phase:** Phase 6 (Error Recovery)
**Duration:** 10 hours
**Created:** 2025-11-01

---

## Overview

Implement retry-gate.sh with max 3 retries and exponential backoff (1s, 5s, 15s).

## Dependencies

- [ ] Phase 5 complete (state v2.0 for retry_history)

## Acceptance Criteria

- [ ] Max 3 retries enforced (no infinite loops)
- [ ] Exponential backoff: 1s, 5s, 15s delays
- [ ] Only retries recoverable errors (lint, format)
- [ ] Logs retry history to state.yaml
- [ ] Escalates to user after max retries
- [ ] ≥80% auto-recovery rate measured

## Implementation Details

### Files to Create

- `.spec-drive/scripts/tools/retry-gate.sh`
- `tests/unit/retry-gate.test.sh`

### Retry Logic

```bash
MAX_RETRIES=3
DELAYS=(1 5 15)

for attempt in 0 1 2; do
  run_gate
  if [ $? -eq 0 ]; then return 0; fi
  
  if is_recoverable; then
    apply_auto_fix
    sleep ${DELAYS[$attempt]}
  else
    escalate_to_user
    return 1
  fi
done
```

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.6)
- ADR-006: `.spec-drive/development/planned/v0.2/adrs/ADR-006-auto-retry-backoff-strategy.md`
- Risk Assessment: `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-005)
