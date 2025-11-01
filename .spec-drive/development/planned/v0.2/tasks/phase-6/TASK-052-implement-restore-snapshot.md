# Task TASK-052: Implement restore-snapshot.sh

**Status:** Not Started | **Phase:** Phase 6 | **Duration:** 8 hours

## Overview
Implement snapshot restoration for rollback.

## Dependencies
- [ ] TASK-051 - create-snapshot.sh ready

## Acceptance Criteria
- [ ] Load snapshot for target stage
- [ ] Validate git commit exists
- [ ] Restore git state (git reset --hard)
- [ ] Update workflow stage in state.yaml
- [ ] User confirmation required (destructive)

**Related:** TDD Section 3.6, ADR-005, IMPLEMENTATION-PLAN Phase 6
