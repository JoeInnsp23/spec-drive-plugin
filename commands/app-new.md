---
name: spec-drive:app-new
description: Initialize new project with planning session and documentation
allowed-tools: "*"
argument_hint: "[project-name]"
---

# app-new: Initialize New Project

This command starts a new project with a guided planning session and generates
the initial documentation structure following spec-drive workflows.

**What it does:**
1. Runs an interactive planning session to gather:
   - Project vision and goals
   - Key features
   - Target users
   - Tech stack
2. Creates the APP-001 spec capturing planning decisions
3. Generates initial documentation suite (README, ARCHITECTURE, etc.)
4. Initializes workflow state (workflow=app-new, spec=APP-001, stage=discover)

**Usage:**
```
/spec-drive:app-new [project-name]
```

**Example:**
```
/spec-drive:app-new my-awesome-app
```

**Prerequisites:**
- No active workflow (must complete or abandon current workflow first)
- spec-drive plugin initialized in project

**Next Steps:**
After app-new completes, use `/spec-drive:feature` to start building features.

---

!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh "$@"
