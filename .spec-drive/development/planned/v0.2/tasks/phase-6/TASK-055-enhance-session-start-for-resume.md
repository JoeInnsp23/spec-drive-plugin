# Task TASK-055: Enhance session-start.sh for Resume

**Status:** Not Started | **Phase:** Phase 6 | **Duration:** 10 hours

## Overview
Add interrupted workflow detection and resume prompt to session-start hook.

## Dependencies
- [ ] TASK-051 - Snapshots available for resume

## Acceptance Criteria
- [ ] Detect interrupted workflows (interrupted: true flag)
- [ ] Prompt user: "Resume SPEC-ID from 'stage'? (y/N)"
- [ ] Restore workflow state from snapshot
- [ ] Clear interrupted flag

**Related:** TDD Section 3.6, IMPLEMENTATION-PLAN Phase 6
