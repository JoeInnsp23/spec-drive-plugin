# Task TASK-043: Implement /spec-drive:switch Command

**Status:** Not Started | **Phase:** Phase 5 | **Duration:** 12 hours

## Overview
Implement workflow switching with conflict detection.

## Dependencies
- [ ] TASK-041, TASK-042 - Queue and conflict detection ready

## Acceptance Criteria
- [ ] Detect conflicts before switch
- [ ] Warn user if conflicts exist
- [ ] Require commit or --force flag for conflict switch
- [ ] Update current_spec in state.yaml
- [ ] Context switching time <1s (PT-003 target)

**Related:** TDD Section 3.5, ADR-003, TEST-PLAN PT-003
