# Task TASK-004: Implement validate-spec.js

**Status:** Not Started
**Phase:** Phase 1 (Specialist Agents)
**Duration:** 4 hours
**Created:** 2025-11-01

---

## Overview

Implement validate-spec.js tool to validate agent-generated specs.

## Dependencies

- [ ] TASK-001 - Create spec-agent.md (need validation rules)

## Acceptance Criteria

- [ ] validate-spec.js validates YAML syntax
- [ ] Validates user stories format (As a..., I want..., so that...)
- [ ] Validates ACs in Given/When/Then format
- [ ] Flags [NEEDS CLARIFICATION] markers
- [ ] Exit code 0=pass, 1=fail
- [ ] Unit tests ≥90% coverage

## Implementation Details

### Files to Create

- `.spec-drive/scripts/tools/validate-spec.js`
- `tests/unit/validate-spec.test.js`

### Validation Rules

1. Valid YAML syntax
2. Required fields: spec_id, user_stories, acceptance_criteria
3. User story format: "As a [role], I want [feature], so that [benefit]"
4. AC format: "Given [context], When [action], Then [outcome]"
5. No [NEEDS CLARIFICATION] markers (indicates incomplete spec)

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.1)
