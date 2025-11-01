# Task TASK-053: Implement rollback-workflow.sh

**Status:** Not Started | **Phase:** Phase 6 | **Duration:** 12 hours

## Overview
Implement workflow rollback to previous stage.

## Dependencies
- [ ] TASK-052 - restore-snapshot.sh ready

## Acceptance Criteria
- [ ] Wrapper around restore-snapshot.sh
- [ ] Confirmation prompt (destructive operation)
- [ ] Clear future snapshots (stages after target)
- [ ] Works for all workflow types (feature, bugfix, research)

**Related:** TDD Section 3.6, ADR-005, IMPLEMENTATION-PLAN Phase 6
