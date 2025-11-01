# Task TASK-041: Implement workflow-queue.js

**Status:** Not Started
**Phase:** Phase 5 (Multi-Workflow State)
**Duration:** 12 hours
**Created:** 2025-11-01

---

## Overview

Implement workflow-queue.js for CRUD operations on workflows{} map in state.yaml v2.0.

## Dependencies

- [ ] TASK-040 - Update state.yaml schema to v2.0

## Acceptance Criteria

- [ ] CRUD operations: add, list, remove, prioritize
- [ ] Priority sorting (0=highest, 9=lowest)
- [ ] Atomic updates (file locking)
- [ ] Max 10 workflows validation
- [ ] Unit tests ≥90% coverage

## Implementation Details

### Files to Create

- `.spec-drive/scripts/tools/workflow-queue.js`
- `tests/unit/workflow-queue.test.js`

### API

```javascript
// Add workflow
addWorkflow(spec_id, type, priority)

// List workflows
listWorkflows() // Returns sorted by priority

// Remove workflow
removeWorkflow(spec_id)

// Prioritize workflow
prioritizeWorkflow(spec_id, new_priority)
```

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.5)
- Test Plan: `.spec-drive/development/planned/v0.2/TEST-PLAN.md` (TS-001)
