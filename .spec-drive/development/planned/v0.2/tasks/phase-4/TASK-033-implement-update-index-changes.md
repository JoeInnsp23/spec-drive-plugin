# Task TASK-033: Implement update-index-changes.js

**Status:** Not Started | **Phase:** Phase 4 | **Duration:** 8 hours

## Overview
Implement tool to track last 20 git commits in changes[] array.

## Dependencies
- [ ] TASK-031 - Update index schema to v2.0

## Acceptance Criteria
- [ ] Parse git log (last 20 commits)
- [ ] Extract: timestamp, commit_hash, message, files, diff stats, spec_id
- [ ] Update changes[] array (FIFO)
- [ ] Integration with post-tool-use hook

**Related:** TDD Section 3.4, IMPLEMENTATION-PLAN Phase 4
