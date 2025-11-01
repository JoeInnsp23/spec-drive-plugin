# ADR-001: Agent-Orchestrator Delegation Protocol

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.1)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 1: Specialist Agents)

---

## Context

v0.2 introduces 3 specialist agents (spec-agent, impl-agent, test-agent) to automate 60%+ of workflow tasks. These agents must:

1. **Receive complex prompts** with stack-specific context (quality gates, patterns, conventions)
2. **Execute multi-step tasks** autonomously (e.g., create spec, generate code, write tests)
3. **Return deliverables** to orchestrator for validation
4. **Integrate with existing workflows** (feature.sh, bugfix.sh, research.sh)

**Problem:** How should workflow orchestrators (bash scripts) delegate tasks to specialist agents?

**Requirements:**
- Agents must receive stack profile variables dynamically
- Agents must execute within Claude Code session (no external services)
- Orchestrators must receive agent outputs synchronously
- Solution must be documented in plugin reference docs already provided

**User Feedback:**
> "claude code subagents is an actual implementation and functionality why are you trying to re-invent the wheel this is all in the docs we have already given you the plugin-reference docs multiple times why do you never reference them?"

This feedback clarified that Claude Code has built-in subagent functionality that we should use, rather than creating custom solutions.

---

## Decision

**Use Claude Code's Task tool with `subagent_type="general-purpose"` parameter for all specialist agent delegation.**

### Implementation

**Agent Interface:**
```bash
# In workflow orchestrator (feature.sh, bugfix.sh, etc.)

# Load stack profile variables
STACK_PROFILE=$(cat .spec-drive/stack-profiles/$DETECTED_STACK.yaml)
STACK_QUALITY_GATES=$(yq eval '.behaviors.quality_gates' <<< "$STACK_PROFILE")
STACK_PATTERNS=$(yq eval '.behaviors.patterns' <<< "$STACK_PROFILE")

# Prepare agent prompt with variables injected
export STACK_QUALITY_GATES STACK_PATTERNS REQUIREMENTS SPEC_ID
agent_prompt=$(cat .spec-drive/agents/spec-agent.md | envsubst)

# Delegate to Claude Code subagent
claude code task \
  --subagent-type="general-purpose" \
  --prompt="$agent_prompt" \
  --description="Create SPEC-${SPEC_ID}.yaml"

# Agent output appears in Claude Code session
# Orchestrator validates deliverable after agent completes
```

**Agent Prompt Template (spec-agent.md):**
```markdown
You are a spec-agent for the spec-drive workflow system.

**Task:** Create SPEC-${SPEC_ID}.yaml from user requirements.

**Stack:** ${DETECTED_STACK}

**Quality Gates:** ${STACK_QUALITY_GATES}

**Requirements:**
${REQUIREMENTS}

**Deliverable:**
- Complete SPEC-${SPEC_ID}.yaml file
- User stories clear and unambiguous
- All acceptance criteria in Given/When/Then format
- Mark ambiguities with [NEEDS CLARIFICATION]

**Template:**
${SPEC_TEMPLATE}
```

---

## Consequences

### Positive

1. ✅ **Uses built-in Claude Code functionality** - No custom agent framework needed
2. ✅ **Documented and supported** - Claude Code Task tool is official API
3. ✅ **Synchronous execution** - Orchestrator waits for agent completion
4. ✅ **Session context preserved** - Agent operates within same Claude Code session
5. ✅ **Stack-aware** - Variables injected via envsubst before delegation
6. ✅ **Simple orchestrator logic** - Standard bash pattern for all agents

### Negative

1. ⚠️ **Requires Claude Code CLI** - Dependency on Claude Code runtime
2. ⚠️ **Limited offline support** - Agents need Claude API access
3. ⚠️ **Performance depends on LLM** - Agent quality varies with model performance
4. ⚠️ **Debugging complexity** - Agent failures harder to trace than bash scripts

### Risks

- **RISK-002 (Agent Quality):** If agents produce low-quality outputs, tune prompts iteratively
- **Rate Limiting:** If Claude API rate limits hit, implement backoff or reduce agent usage
- **Cost:** Agent delegation incurs LLM API costs (mitigate: use Haiku for faster agents)

---

## Alternatives Considered

### Alternative 1: MCP Skills (Markdown Skills)

**Approach:** Implement agents as MCP skills with markdown prompt files

**Pros:**
- Skill system designed for this use case
- Skills can be installed/updated independently

**Cons:**
- User explicitly corrected this approach as "re-inventing the wheel"
- Claude Code subagents already exist for this purpose
- More complex setup (skill installation, dependencies)

**Rejected because:** Claude Code Task tool is the official, documented approach

---

### Alternative 2: Inline Bash Functions

**Approach:** Implement agent logic as bash functions within orchestrator scripts

**Pros:**
- No external dependencies
- Fast execution (no LLM calls)
- Fully deterministic

**Cons:**
- Cannot achieve 60% automation (requires hardcoded logic)
- Not stack-aware (would need massive switch/case for all stacks)
- Defeats purpose of v0.2 enhancement (specialist agents)

**Rejected because:** Cannot provide intelligent, context-aware automation

---

### Alternative 3: External Agent Service

**Approach:** Run agent process as separate service (HTTP API or gRPC)

**Pros:**
- Decoupled from Claude Code
- Could support offline mode with local LLM

**Cons:**
- Complex setup (service installation, networking)
- Not integrated with Claude Code session
- User would need to run separate process
- Violates "within Claude Code" requirement

**Rejected because:** Too complex for plugin users, not integrated with Claude Code

---

## Implementation Notes

### Agent Prompt Best Practices

1. **Clear deliverables** - Specify exact files/format expected
2. **Acceptance criteria** - Define validation rules (e.g., "no [NEEDS CLARIFICATION]")
3. **Stack context** - Inject quality gates, patterns, conventions via envsubst
4. **Examples** - Provide template or example output
5. **Constraints** - Specify what NOT to do (e.g., "no placeholder code")

### Validation After Delegation

```bash
# After agent completes, orchestrator validates deliverable
validate-spec.js "specs/SPEC-${SPEC_ID}.yaml"
if [ $? -ne 0 ]; then
  echo "ERROR: Agent output failed validation"
  # Option 1: Re-delegate with feedback
  # Option 2: Escalate to user
  # Option 3: Fall back to manual spec creation
fi
```

### Error Handling

- **Agent timeout** - Set max execution time (60s for spec-agent)
- **Validation failure** - Retry once with feedback, then escalate to user
- **API errors** - Fall back to manual workflow (v0.1 behavior)

---

## References

- Claude Code Plugin Reference Docs (provided by user)
- Claude Code Task Tool Documentation
- v0.2 PRD Section 4.1 (Specialist Agents)
- v0.2 TDD Section 3.1 (Agent Architecture)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
