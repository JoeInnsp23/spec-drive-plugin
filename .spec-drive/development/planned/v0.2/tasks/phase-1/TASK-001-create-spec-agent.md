# Task TASK-001: Create spec-agent.md

**Status:** Not Started
**Phase:** Phase 1 (Specialist Agents)
**Created:** 2025-11-01
**Updated:** 2025-11-01

---

## Overview

Create spec-agent.md prompt template for automating spec creation from user requirements. This agent is the first of 3 specialist agents that will automate 60%+ of workflow tasks.

**Goal:** Given user requirements, agent generates complete SPEC-XXX.yaml file following spec-drive conventions.

## Dependencies

**Prerequisite Tasks:**
- [ ] PRE-004 - Bug Triage and Closure (Pre-Phase complete)

**Required Resources:**
- Claude Code Task tool (for subagent delegation)
- SPEC-TEMPLATE.yaml (from v0.1)
- Stack profile definitions (for variable injection)

## Acceptance Criteria

- [ ] spec-agent.md created with complete prompt template
- [ ] Agent uses Claude Code Task tool (not MCP skills or markdown files)
- [ ] Stack profile variables injected via envsubst (${STACK_QUALITY_GATES}, etc.)
- [ ] Agent validates: user stories clear, ACs in Given/When/Then format
- [ ] Agent marks ambiguities with [NEEDS CLARIFICATION]
- [ ] Test on sample requirements → generates valid spec
- [ ] validate-spec.js validates agent output

## Implementation Details

### Files to Create/Modify

- `.spec-drive/agents/spec-agent.md` - Agent prompt template

### Agent Prompt Structure

```markdown
# spec-agent.md

You are a spec-agent for the spec-drive workflow system.

**Task:** Create SPEC-${SPEC_ID}.yaml from user requirements.

**Stack:** ${DETECTED_STACK}

**Quality Gates to Pass:**
${STACK_QUALITY_GATES}

**Requirements:**
${REQUIREMENTS}

**Deliverable:**
- Complete SPEC-${SPEC_ID}.yaml file
- User stories clear and unambiguous
- All acceptance criteria in Given/When/Then format
- Mark ambiguities with [NEEDS CLARIFICATION]

**Template:**
${SPEC_TEMPLATE}

**Validation Rules:**
1. Every user story must have: As a [role], I want [feature], so that [benefit]
2. Every AC must have: Given [context], When [action], Then [outcome]
3. No placeholder text like "TBD" or "TODO"
4. Trace to parent specs if dependencies exist

**Examples:**
[Include example spec for reference]
```

### Steps

1. **Draft Agent Prompt**
   - What: Create initial spec-agent.md with variable placeholders
   - How: Use template above, add stack-specific guidance
   - Verification: Prompt includes all required sections

2. **Add Stack Profile Variable Placeholders**
   - What: Add ${STACK_QUALITY_GATES}, ${STACK_PATTERNS}, ${STACK_CONVENTIONS}
   - How: Reference stack profile YAML structure from Phase 3 planning
   - Verification: Variables match stack profile schema

3. **Add Validation Rules**
   - What: Define rules for spec quality (format, completeness)
   - How: List rules in prompt (user stories format, AC format, no TODOs)
   - Verification: Rules align with validate-spec.js checks

4. **Test Agent on Sample Requirements**
   - What: Delegate to agent via Task tool
   - How:
     ```bash
     export SPEC_ID="AUTH-001"
     export REQUIREMENTS="Add OAuth 2.0 login with Google provider"
     export DETECTED_STACK="typescript-react"
     export STACK_QUALITY_GATES="npm run lint\nnpm test"
     
     agent_prompt=$(cat .spec-drive/agents/spec-agent.md | envsubst)
     
     claude code task \
       --subagent-type="general-purpose" \
       --prompt="$agent_prompt" \
       --description="Create SPEC-AUTH-001.yaml"
     ```
   - Verification: Agent generates SPEC-AUTH-001.yaml

5. **Validate Agent Output**
   - What: Run validate-spec.js on generated spec
   - How: `node .spec-drive/scripts/tools/validate-spec.js specs/SPEC-AUTH-001.yaml`
   - Verification: Validation passes (exit code 0)

## Testing Approach

### Unit Tests
- validate-spec.js tests (TASK-004 dependency)

### Integration Tests
- TS-004 (Agent Coordination scenario) in TEST-PLAN.md

### Manual Verification
```bash
# Test spec-agent end-to-end
cd test-projects/typescript-react

# Set up test environment
export SPEC_ID="TEST-001"
export REQUIREMENTS="Add user registration with email verification"
export DETECTED_STACK="typescript-react"
export STACK_QUALITY_GATES="npm run lint\nnpm run typecheck\nnpm test"

# Generate agent prompt
agent_prompt=$(cat .spec-drive/agents/spec-agent.md | envsubst)

# Delegate to agent
claude code task \
  --subagent-type="general-purpose" \
  --prompt="$agent_prompt" \
  --description="Create SPEC-TEST-001.yaml" \
  --timeout=60000

# Validate output
node .spec-drive/scripts/tools/validate-spec.js specs/SPEC-TEST-001.yaml

# Expected: Validation passes, spec has user stories + ACs
```

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| RISK-002: Agent too generic | Medium (50%) | Critical - 60% automation not achieved | Test on real TypeScript AND Python projects, tune prompts |
| Agent output invalid YAML | Low (20%) | Medium - Validation fails | Add YAML syntax guidance in prompt |
| Agent includes placeholders | Medium (30%) | Medium - Spec not complete | Add rule: "No TODOs/TBDs/placeholders allowed" |

## Completion Checklist

- [ ] spec-agent.md created with all required sections
- [ ] Stack profile variables use ${VAR} syntax for envsubst
- [ ] Tested on ≥2 sample requirements (different domains)
- [ ] validate-spec.js validates agent output successfully
- [ ] Agent prompt committed to repo
- [ ] Documented in TDD.md Section 3.1

## Notes

**ADR-001:** This agent uses Claude Code Task tool with subagent_type="general-purpose" per user feedback correction. NOT MCP skills or standalone markdown files.

**ADR-002:** Stack profile variables injected via envsubst (string replacement) per technical decision.

---

**Related Documents:**
- PRD: `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 1: Specialist Agents)
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.1)
- Implementation Plan: `.spec-drive/development/planned/v0.2/IMPLEMENTATION-PLAN.md` (Phase 1)
- ADR-001: `.spec-drive/development/planned/v0.2/adrs/ADR-001-agent-orchestrator-delegation-protocol.md`
- ADR-002: `.spec-drive/development/planned/v0.2/adrs/ADR-002-stack-profile-variable-injection.md`
