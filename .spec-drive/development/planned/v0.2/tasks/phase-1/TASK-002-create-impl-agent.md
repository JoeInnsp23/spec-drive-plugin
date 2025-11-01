# Task TASK-002: Create impl-agent.md

**Status:** Not Started
**Phase:** Phase 1 (Specialist Agents)
**Duration:** 8 hours
**Created:** 2025-11-01

---

## Overview

Create impl-agent.md for stack-aware code generation from specs.

## Dependencies

- [ ] TASK-001 - Create spec-agent.md (learn from spec-agent pattern)

## Acceptance Criteria

- [ ] impl-agent.md created with stack profile variables
- [ ] Agent generates code following ${STACK_PATTERNS} and ${STACK_CONVENTIONS}
- [ ] Agent injects @spec tags for traceability
- [ ] Tested on TypeScript AND Python projects

## Implementation Details

Agent delegates code implementation based on SPEC-XXX.yaml acceptance criteria, following stack-specific patterns.

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.1)
- ADR-001, ADR-002
