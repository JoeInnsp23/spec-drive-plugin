# Task TASK-005: Integrate Agents into Feature Workflow

**Status:** Not Started
**Phase:** Phase 1 (Specialist Agents)
**Duration:** 12 hours
**Created:** 2025-11-01

---

## Overview

Modify feature.sh orchestrator to delegate to specialist agents at stage boundaries.

## Dependencies

- [ ] TASK-001 - Create spec-agent.md
- [ ] TASK-002 - Create impl-agent.md
- [ ] TASK-003 - Create test-agent.md

## Acceptance Criteria

- [ ] feature.sh delegates to spec-agent in specify stage
- [ ] feature.sh delegates to impl-agent in implement stage
- [ ] feature.sh delegates to test-agent in implement stage
- [ ] TS-004 test scenario passes (Agent Coordination)
- [ ] Automation ≥60% measured

## Implementation Details

### Modified feature.sh Flow

```bash
# Stage: Specify
echo "Delegating spec creation to spec-agent..."
export SPEC_ID REQUIREMENTS DETECTED_STACK
agent_prompt=$(cat .spec-drive/agents/spec-agent.md | envsubst)
claude code task --subagent-type="general-purpose" --prompt="$agent_prompt"

# Validate spec
validate-spec.js "specs/SPEC-${SPEC_ID}.yaml"

# Stage: Implement
echo "Delegating implementation to impl-agent..."
# ... delegate to impl-agent

# Delegate to test-agent
# ... delegate to test-agent
```

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.1)
- Test Plan: `.spec-drive/development/planned/v0.2/TEST-PLAN.md` (TS-004)
