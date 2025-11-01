# Task TASK-034: Enhance post-tool-use.sh Hook

**Status:** Not Started | **Phase:** Phase 4 | **Duration:** 8 hours

## Overview
Enhance hook to trigger summary generation and changes tracking.

## Dependencies
- [ ] TASK-030, TASK-033 - Summary and changes tools ready

## Acceptance Criteria
- [ ] Trigger generate-summaries.js on file writes (if dirty flag)
- [ ] Trigger update-index-changes.js on git commits
- [ ] Async execution (non-blocking)
- [ ] Performance impact <500ms

**Related:** TDD Section 3.4, IMPLEMENTATION-PLAN Phase 4
