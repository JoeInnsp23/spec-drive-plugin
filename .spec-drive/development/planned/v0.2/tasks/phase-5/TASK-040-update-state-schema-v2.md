# Task TASK-040: Update state.yaml Schema to v2.0

**Status:** Not Started | **Phase:** Phase 5 | **Duration:** 6 hours

## Overview
Update state.yaml to v2.0 with workflows{} map for multi-workflow support.

## Acceptance Criteria
- [ ] Add workflows{} map (id → workflow object)
- [ ] Add priority, files_locked[], snapshots[], retry_history[] per workflow
- [ ] Maintain backward compatibility (current_* fields)
- [ ] Schema validation passes

**Related:** TDD Section 3.5, ADR-005, IMPLEMENTATION-PLAN Phase 5
