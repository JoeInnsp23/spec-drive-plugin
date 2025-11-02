---
name: spec-drive:feature
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

**Prerequisites:**
- spec-drive initialized (/spec-drive:init)
- For app-new projects: Complete /spec-drive:app-new first

---

## Commands

### 1. Start a New Feature

**IMPORTANT:** For the `start` command, gather ALL information BEFORE running the script.

#### Step 1: Gather Feature Information

Ask the user for the following (use AskUserQuestion or natural conversation):

1. **Feature title** (required)
   - Clear, descriptive name for the feature

2. **Feature description** (optional)
   - Detailed description of what this feature does
   - If not provided, will default to the title

3. **Priority** (optional)
   - Options: low, medium, high, critical
   - If not provided, will default to "medium"

#### Step 2: Run Non-Interactive Script

Once you have the information, run:

```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh start "<title>" \
  [--description "<detailed description>"] \
  [--priority <low|medium|high|critical>]
```

**Examples:**
```bash
# Minimal (uses defaults)
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh start "User authentication"

# With all options
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh start "User authentication" \
  --description "OAuth2-based authentication with Google and GitHub providers" \
  --priority "high"
```

---

### 2. Advance to Next Stage

No data gathering needed - runs directly:

```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh advance
```

---

### 3. Check Workflow Status

No data gathering needed - runs directly:

```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/feature/run.sh status
```

---

## Stage Details

1. **Discover**: Create spec YAML with requirements
   - Generates unique SPEC-ID (e.g., AUTH-001)
   - Creates spec file in .spec-drive/specs/
   - Creates development structure in .spec-drive/development/current/

2. **Specify**: Define acceptance criteria
   - Add testable acceptance criteria to spec
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
   - Archive to .spec-drive/development/completed/
   - Mark workflow complete
