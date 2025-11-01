---
name: feature
description: Start or advance feature development workflow (4-stage process)
allowed-tools: "*"
argument_hint: "[start|advance|status] [SPEC-ID]"
---

# feature: Feature Development Workflow

Manage feature development through a 4-stage workflow:
1. **Discover** - Requirements gathering, create spec
2. **Specify** - Define acceptance criteria
3. **Implement** - Write code and tests
4. **Verify** - Run quality gates, update docs

**Commands:**

**Start a new feature:**
```
/spec-drive:feature start <title>
```

**Advance to next stage:**
```
/spec-drive:feature advance
```

**Check workflow status:**
```
/spec-drive:feature status
```

**Examples:**
```
/spec-drive:feature start "User authentication"
/spec-drive:feature advance
/spec-drive:feature status
```

**Stage Details:**

1. **Discover**: Create spec YAML with requirements
   - Prompts for feature description
   - Generates unique SPEC-ID (e.g., AUTH-001)
   - Creates spec file in .spec-drive/specs/

2. **Specify**: Define acceptance criteria
   - Add testable acceptance criteria
   - Define success metrics
   - Advance when criteria complete

3. **Implement**: Write code and tests
   - Implement against acceptance criteria
   - Add @spec tags to code
   - Write tests for all criteria
   - Advance when tests pass

4. **Verify**: Quality gates and documentation
   - Run quality gate checks
   - Update documentation
   - Complete traceability
   - Mark workflow complete

**Prerequisites:**
- spec-drive initialized (/spec-drive:spec-init)
- For app-new projects: Complete /spec-drive:app-new first

---

!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh "$@"
