# ADR-002: Stack Profile Variable Injection

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.3)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 3: Stack Profiles)

---

## Context

v0.2 adds stack profiles (TypeScript/React, Python/FastAPI, Go, Rust) that define:

1. **Detection rules** - How to identify the stack (package.json, requirements.txt, etc.)
2. **Quality gates** - Stack-specific commands (npm test, pytest, go test, cargo test)
3. **Patterns** - Common code patterns (React hooks, async/await, error handling)
4. **Conventions** - Naming, formatting, structure rules

**Problem:** How should stack profile variables be injected into:
- Agent prompts (spec-agent, impl-agent, test-agent)
- Quality gate scripts (gate-1-*.sh, gate-2-*.sh)
- Workflow orchestrators (feature.sh, bugfix.sh)

**Requirements:**
- Variables must be replaced at runtime (not build time)
- Solution must work in bash scripts
- Must support complex multi-line values (quality gates can be multi-command)
- Must handle special characters (quotes, backticks, $, etc.)
- Keep it simple (avoid heavyweight template engines)

---

## Decision

**Use `envsubst` (GNU gettext) for string replacement with environment variable export.**

### Implementation

**Stack Profile YAML:**
```yaml
# .spec-drive/stack-profiles/typescript-react.yaml
detection:
  files:
    - package.json
    - tsconfig.json
  content_patterns:
    - "react"
    - "typescript"

behaviors:
  quality_gates: |
    npm run lint
    npm run typecheck
    npm test

  patterns: |
    - React hooks (useState, useEffect)
    - Async/await for promises
    - TypeScript interfaces for props

  conventions: |
    - PascalCase for components
    - camelCase for functions
    - Type all props and state
```

**Variable Injection in Orchestrator:**
```bash
# Load stack profile
STACK_PROFILE=$(cat .spec-drive/stack-profiles/$DETECTED_STACK.yaml)

# Extract variables using yq
STACK_QUALITY_GATES=$(yq eval '.behaviors.quality_gates' <<< "$STACK_PROFILE")
STACK_PATTERNS=$(yq eval '.behaviors.patterns' <<< "$STACK_PROFILE")
STACK_CONVENTIONS=$(yq eval '.behaviors.conventions' <<< "$STACK_PROFILE")

# Export for envsubst
export STACK_QUALITY_GATES STACK_PATTERNS STACK_CONVENTIONS

# Inject into agent prompt
agent_prompt=$(cat .spec-drive/agents/impl-agent.md | envsubst)

# Inject into quality gate script
gate_script=$(cat .spec-drive/scripts/gates/gate-2-implement.sh | envsubst)
eval "$gate_script"
```

**Agent Prompt with Placeholders:**
```markdown
# .spec-drive/agents/impl-agent.md

You are an impl-agent for the spec-drive workflow system.

**Stack:** ${DETECTED_STACK}

**Quality Gates to Pass:**
${STACK_QUALITY_GATES}

**Follow these patterns:**
${STACK_PATTERNS}

**Follow these conventions:**
${STACK_CONVENTIONS}

**Task:** Implement features from SPEC-${SPEC_ID}.yaml
```

**After envsubst:**
```markdown
You are an impl-agent for the spec-drive workflow system.

**Stack:** typescript-react

**Quality Gates to Pass:**
npm run lint
npm run typecheck
npm test

**Follow these patterns:**
- React hooks (useState, useEffect)
- Async/await for promises
- TypeScript interfaces for props

**Follow these conventions:**
- PascalCase for components
- camelCase for functions
- Type all props and state

**Task:** Implement features from SPEC-AUTH-001.yaml
```

---

## Consequences

### Positive

1. ✅ **Simple and standard** - `envsubst` is part of GNU gettext (widely available)
2. ✅ **Bash-native** - Works in bash scripts without dependencies
3. ✅ **Handles special characters** - Properly escapes quotes, $, backticks
4. ✅ **Multi-line support** - YAML multi-line strings work correctly
5. ✅ **No compilation step** - Runtime replacement, dynamic
6. ✅ **Easy to debug** - `echo "$agent_prompt"` shows final result

### Negative

1. ⚠️ **Requires environment variables** - Must export variables before envsubst
2. ⚠️ **No conditionals** - Cannot do if/else logic (use bash for that)
3. ⚠️ **Variable scope** - Exported variables persist in shell session

### Risks

- **Variable conflicts:** If $STACK_QUALITY_GATES already set in user's environment, use namespaced vars: `$SPEC_DRIVE_STACK_QUALITY_GATES`
- **Injection attacks:** Validate stack profile YAML before loading (schema validation)

---

## Alternatives Considered

### Alternative 1: Jinja2 Template Engine

**Approach:** Use Python Jinja2 for template rendering

**Pros:**
- Full template language (conditionals, loops, filters)
- Well-documented, widely used
- Can validate templates before rendering

**Cons:**
- Requires Python dependency
- Slower than envsubst (subprocess invocation)
- Overkill for simple variable substitution
- More complex syntax ({% %}, {{ }})

**Rejected because:** Too heavyweight for simple variable injection

---

### Alternative 2: sed/awk Manual Replacement

**Approach:** Use sed or awk to replace placeholders

**Pros:**
- No dependencies (bash built-ins)
- Maximum control over replacement logic

**Cons:**
- Complex escaping for special characters
- Error-prone for multi-line values
- Hard to maintain (regex complexity)

**Example:**
```bash
# Fragile, breaks with quotes/backticks
sed "s/\${STACK_QUALITY_GATES}/$STACK_QUALITY_GATES/g" agent-prompt.md
```

**Rejected because:** envsubst handles edge cases better

---

### Alternative 3: Hardcoded Per-Stack Agent Files

**Approach:** Create separate agent files per stack (impl-agent-typescript.md, impl-agent-python.md)

**Pros:**
- No variable injection needed
- Clear separation per stack
- Easy to customize per stack

**Cons:**
- Code duplication (agent logic repeated)
- Hard to maintain (update 4 files for one change)
- Doesn't scale to new stacks (need new file each time)
- Violates DRY principle

**Rejected because:** Not scalable, duplicates logic

---

### Alternative 4: JSON/YAML Embedding

**Approach:** Embed stack profile directly in agent prompt as JSON

**Example:**
```markdown
**Stack Profile:**
```json
{
  "quality_gates": ["npm run lint", "npm test"],
  "patterns": ["React hooks", "Async/await"]
}
```
```

**Pros:**
- No variable injection needed
- Structured data in prompt

**Cons:**
- Agent must parse JSON (less readable)
- Wastes tokens (full JSON structure vs rendered text)
- More complex for agent to interpret

**Rejected because:** Less readable, wastes tokens

---

## Implementation Notes

### Best Practices

1. **Always export before envsubst:**
```bash
export STACK_QUALITY_GATES STACK_PATTERNS STACK_CONVENTIONS
agent_prompt=$(cat agent-template.md | envsubst)
```

2. **Validate stack profile before loading:**
```bash
yq validate .spec-drive/stack-profiles/typescript-react.yaml
if [ $? -ne 0 ]; then
  echo "ERROR: Invalid stack profile"
  exit 1
fi
```

3. **Use descriptive variable names:**
```bash
# Good
export STACK_QUALITY_GATES

# Bad
export GATES  # Unclear, could conflict
```

4. **Clean up exports after use:**
```bash
unset STACK_QUALITY_GATES STACK_PATTERNS STACK_CONVENTIONS
```

### Fallback Behavior

If stack profile missing or invalid:
```bash
# Fallback to generic profile
STACK_PROFILE=$(cat .spec-drive/stack-profiles/generic.yaml)
```

### Testing

Test variable injection with edge cases:
```yaml
# Test profile with special characters
behaviors:
  quality_gates: |
    echo "test with 'quotes'"
    echo "test with $dollar"
    echo "test with `backtick`"
```

Verify envsubst handles correctly:
```bash
export STACK_QUALITY_GATES="$(yq eval '.behaviors.quality_gates' <<< "$test_profile")"
result=$(echo '${STACK_QUALITY_GATES}' | envsubst)
# Should preserve quotes, escape $, handle backticks
```

---

## References

- GNU gettext envsubst documentation
- YAML multi-line string syntax
- yq (YAML processor) documentation
- v0.2 TDD Section 3.3 (Stack Profiles)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
