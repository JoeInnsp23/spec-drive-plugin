# Task TASK-030: Implement generate-summaries.js

**Status:** Not Started
**Phase:** Phase 4 (Index Optimizations)
**Duration:** 12 hours
**Created:** 2025-11-01

---

## Overview

Implement generate-summaries.js to create AI summaries of all index entries for ≥90% context reduction.

## Dependencies

- [ ] Phase 3 complete (stack profiles needed for context)

## Acceptance Criteria

- [ ] Generates summaries for all components, specs, docs, code
- [ ] Uses Claude Haiku via Task tool
- [ ] Summary generation <10s per file (PT-001 target)
- [ ] Context reduction ≥90% measured (PT-002)
- [ ] Timeout handling (skip on timeout)
- [ ] Batch processing (10 files at a time)
- [ ] Unit tests ≥90% coverage

## Implementation Details

### Files to Create

- `.spec-drive/scripts/tools/generate-summaries.js`
- `tests/unit/generate-summaries.test.js`

### Summary Generation Algorithm

1. Read file content (first 2000 chars)
2. Generate prompt: "Summarize in 1-2 sentences (max 200 chars)"
3. Delegate to Claude Haiku via Task tool
4. Validate summary length ≤200 chars
5. Update index.yaml with summary

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.4)
- ADR-004: `.spec-drive/development/planned/v0.2/adrs/ADR-004-ai-summary-generation-strategy.md`
- Test Plan: `.spec-drive/development/planned/v0.2/TEST-PLAN.md` (PT-001, PT-002)
