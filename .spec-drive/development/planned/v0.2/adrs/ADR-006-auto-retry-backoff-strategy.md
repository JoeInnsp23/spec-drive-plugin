# ADR-006: Auto-Retry Backoff Strategy

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.6)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 6: Error Recovery)
- `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-005)

---

## Context

v0.2 adds auto-retry for quality gate failures. When a gate fails due to recoverable errors (linting, formatting, simple test failures), the system applies auto-fixes and retries.

**Problem:** How should we implement retry logic to avoid infinite loops while maximizing recovery rate?

**Requirements:**
1. **Bounded retries** - Must not loop infinitely (RISK-005)
2. **High recovery rate** - Target ≥80% auto-recovery for simple errors
3. **Fast first retry** - Don't delay unnecessarily
4. **Escalate on repeated failures** - User intervention after max retries
5. **Track retry history** - Log attempts for debugging

**Recoverable Error Examples:**
- Linting errors (can fix with `npm run lint --fix`)
- Formatting errors (can fix with `prettier --write`)
- Simple test failures (can retry after code fix)

**Non-Recoverable Errors:**
- Logic errors (incorrect implementation)
- Missing dependencies (cannot auto-install)
- Compilation errors (syntax errors)

---

## Decision

**Use exponential backoff with max 3 retries: 1s, 5s, 15s delays.**

### Implementation

**Retry Logic (retry-gate.sh):**
```bash
#!/bin/bash

MAX_RETRIES=3
DELAYS=(1 5 15)  # Exponential backoff: 1s, 5s, 15s

retry_gate() {
  local gate_script=$1
  local workflow=$2
  local attempt=0

  while [ $attempt -lt $MAX_RETRIES ]; do
    echo "Running gate (attempt $((attempt + 1))/$MAX_RETRIES)..."

    # Run quality gate
    output=$($gate_script 2>&1)
    exit_code=$?

    # If passed, return success
    if [ $exit_code -eq 0 ]; then
      echo "✓ Gate passed"
      return 0
    fi

    # Gate failed - check if recoverable
    if is_recoverable "$output"; then
      echo "⚠ Gate failed (recoverable), applying auto-fix..."

      # Apply auto-fix
      apply_auto_fix "$output"

      # Log retry attempt
      log_retry "$workflow" "$attempt" "$output"

      # Wait before retry (exponential backoff)
      delay=${DELAYS[$attempt]}
      echo "Retrying in ${delay}s..."
      sleep "$delay"

      attempt=$((attempt + 1))
    else
      echo "✗ Gate failed (non-recoverable)"
      escalate_to_user "$workflow" "$output"
      return 1
    fi
  done

  # Max retries exceeded
  echo "✗ Gate failed after $MAX_RETRIES attempts"
  escalate_to_user "$workflow" "$output"
  return 1
}

is_recoverable() {
  local output=$1

  # Check for recoverable error patterns
  if echo "$output" | grep -qi "lint error"; then
    return 0  # Recoverable
  elif echo "$output" | grep -qi "format"; then
    return 0  # Recoverable
  elif echo "$output" | grep -qi "prettier"; then
    return 0  # Recoverable
  else
    return 1  # Non-recoverable
  fi
}

apply_auto_fix() {
  local output=$1

  # Apply fixes based on error type
  if echo "$output" | grep -qi "lint error"; then
    npm run lint --fix
  elif echo "$output" | grep -qi "format"; then
    npm run format
  elif echo "$output" | grep -qi "prettier"; then
    npx prettier --write .
  fi
}

log_retry() {
  local workflow=$1
  local attempt=$2
  local error=$3

  # Log to state.yaml retry_history
  timestamp=$(date -Iseconds)
  yq eval -i "
    .workflows.$workflow.retry_history += [{
      \"attempt\": $attempt,
      \"timestamp\": \"$timestamp\",
      \"error\": \"$error\"
    }]
  " .spec-drive/state.yaml
}

escalate_to_user() {
  local workflow=$1
  local error=$2

  echo ""
  echo "==============================================="
  echo "GATE FAILURE - USER INTERVENTION REQUIRED"
  echo "==============================================="
  echo "Workflow: $workflow"
  echo "Error: $error"
  echo ""
  echo "Options:"
  echo "  1. Fix manually and re-run gate"
  echo "  2. Skip gate (--force flag, risky)"
  echo "  3. Rollback to previous stage"
  echo "==============================================="
}

# Usage in quality gate scripts
retry_gate "gate-2-implement.sh" "AUTH-001"
```

**State Schema (retry_history):**
```yaml
workflows:
  AUTH-001:
    retry_history:
      - attempt: 0
        timestamp: 2025-11-01T11:00:00Z
        error: "Lint error: missing semicolon"
      - attempt: 1
        timestamp: 2025-11-01T11:01:05Z
        error: "Test failure: auth.test.ts"
      - attempt: 2
        timestamp: 2025-11-01T11:01:20Z
        error: "Test failure: auth.test.ts (timeout)"
    # After 3 attempts, escalate to user
```

---

## Consequences

### Positive

1. ✅ **Bounded retries** - Max 3 attempts prevents infinite loops (RISK-005 mitigated)
2. ✅ **Fast first retry** - 1s delay doesn't slow workflow unnecessarily
3. ✅ **Exponential backoff** - Gives time for fixes to take effect (5s, 15s)
4. ✅ **High recovery rate** - ≥80% target achievable for lint/format errors
5. ✅ **Logged history** - retry_history provides debugging info
6. ✅ **User escalation** - Clear options after max retries

### Negative

1. ⚠️ **Max 21s total delay** - 1s + 5s + 15s = 21s overhead on failure
2. ⚠️ **Auto-fix may break code** - lint --fix can change logic (rare)
3. ⚠️ **False recoverable detection** - May retry non-recoverable errors

### Risks

- **RISK-005 (Infinite Loops):** Fully mitigated by max 3 retries
- **Auto-fix damage:** Mitigate with git snapshots (rollback if auto-fix breaks)
- **Retry thrashing:** If retries fail frequently, reduce max to 2 or 1

---

## Alternatives Considered

### Alternative 1: Linear Backoff (1s, 2s, 3s)

**Approach:** Increase delay linearly instead of exponentially

**Pros:**
- Faster total retry time (1+2+3=6s vs 1+5+15=21s)
- Simpler to understand

**Cons:**
- **Insufficient time** - 3s may not be enough for test re-runs
- **Less standard** - Exponential backoff is industry standard

**Rejected because:** Exponential backoff gives more time for fixes to take effect

---

### Alternative 2: Unlimited Retries with Timeout

**Approach:** Retry until timeout (e.g., 60s total) instead of max attempts

**Pros:**
- Maximizes recovery attempts
- Simple implementation (while loop with time check)

**Cons:**
- **Risk of loops** - Could retry 20+ times in 60s (thrashing)
- **Unpredictable** - User doesn't know when retries will stop
- **Violates requirement** - Bounded retries required (RISK-005)

**Rejected because:** Violates bounded retry requirement

---

### Alternative 3: No Auto-Retry (Manual Only)

**Approach:** Never auto-retry, always escalate to user

**Pros:**
- No risk of loops
- User always in control
- Simpler implementation

**Cons:**
- **Low recovery rate** - 0% auto-recovery (fails v0.2 goal)
- **Poor UX** - User must manually re-run gates
- **Defeats v0.2 enhancement** - Error recovery not automated

**Rejected because:** Fails v0.2 goal of ≥80% auto-recovery

---

### Alternative 4: Adaptive Backoff (Success Rate Based)

**Approach:** Adjust delays based on historical success rate

**Example:**
- If 80% of retries succeed on attempt 1, use 0.5s delay
- If 20% success rate, increase to 2s delay

**Pros:**
- Optimizes for observed patterns
- Minimizes delay for fast fixes

**Cons:**
- **Complex** - Requires tracking success rates, tuning algorithm
- **Unpredictable** - Delay changes over time (confusing)
- **Overkill** - Simple exponential backoff sufficient for v0.2

**Rejected because:** Too complex for v0.2, diminishing returns

---

## Implementation Notes

### Best Practices

1. **Only retry recoverable errors:**
```bash
# Before retry, validate error is recoverable
if ! is_recoverable "$output"; then
  escalate_to_user "$workflow" "$output"
  return 1  # Do not retry
fi
```

2. **Log all retry attempts:**
```bash
# Enables debugging: "Why did gate fail 3 times?"
log_retry "$workflow" "$attempt" "$error"
```

3. **Show progress to user:**
```bash
echo "Retrying in ${delay}s... (attempt $((attempt + 1))/$MAX_RETRIES)"
# User knows system is working, not hanging
```

4. **Snapshot before auto-fix:**
```bash
# If auto-fix breaks code, can rollback
create_snapshot "$workflow" "before-auto-fix"
apply_auto_fix "$output"
```

### Recoverable Error Patterns

Extend `is_recoverable()` for more error types:
```bash
is_recoverable() {
  local output=$1

  # Lint errors
  if echo "$output" | grep -qi "eslint\|tslint\|pylint"; then return 0; fi

  # Format errors
  if echo "$output" | grep -qi "prettier\|black\|gofmt"; then return 0; fi

  # Simple test failures (timeout, flakiness)
  if echo "$output" | grep -qi "ETIMEDOUT\|connection refused"; then return 0; fi

  # Non-recoverable (logic errors, missing deps)
  return 1
}
```

### Auto-Fix Strategies

```bash
apply_auto_fix() {
  local output=$1

  # Lint errors
  if echo "$output" | grep -qi "eslint"; then
    npx eslint --fix .
  elif echo "$output" | grep -qi "pylint"; then
    autopep8 --in-place --aggressive .
  fi

  # Format errors
  if echo "$output" | grep -qi "prettier"; then
    npx prettier --write .
  elif echo "$output" | grep -qi "black"; then
    black .
  fi

  # Commit auto-fixes
  git add .
  git commit -m "Auto-fix: lint/format corrections"
}
```

### Testing

```bash
# Test retry logic with intentional lint error
echo "missing semicolon" > src/test.ts
retry_gate "gate-2-implement.sh" "TEST-001"

# Expected behavior:
# Attempt 1: Fail → auto-fix (eslint --fix) → wait 1s
# Attempt 2: Pass → ✓

# Test max retries exceeded
# (Create non-recoverable error)
echo "syntax error" > src/test.ts
retry_gate "gate-2-implement.sh" "TEST-001"

# Expected behavior:
# Attempt 1: Fail → not recoverable → escalate to user
```

### Monitoring

Track retry success rate:
```bash
# After v0.2 launch, measure:
# - Total retries: 1000
# - Successful auto-recovery: 850
# - Recovery rate: 85% (exceeds ≥80% target)
```

---

## References

- Exponential backoff best practices (Google SRE Handbook)
- Circuit breaker patterns
- v0.2 TDD Section 3.6 (Error Recovery)
- v0.2 RISK-ASSESSMENT RISK-005 (Auto-Retry Infinite Loops)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
