---
name: spec-drive:init
description: Initialize spec-drive in project (new or existing)
allowed-tools: "*"
---

# Initialize spec-drive

Initializes spec-drive development system in current project.

Detects project type and runs appropriate initialization:
- **New project:** Scaffold structure + templates
- **Existing project:** Analyze + archive + regenerate docs

## Pre-Initialization: Check claude-sc Alias

**Before running initialization, check if claude-sc alias exists:**

Check for existing alias by running:
```bash
alias claude-sc 2>/dev/null || grep -h "alias claude-sc" ~/.bashrc ~/.zshrc 2>/dev/null || echo "NOT_FOUND"
```

**If alias NOT found:**
- Ask user: "Would you like to set up the claude-sc alias for strict-concise behavior? (y/n)"
- If yes: Pass `--setup-alias` flag to init script below
- If no: Run init script without flag

**If alias found:**
- Skip alias setup (respect existing configuration)
- Run init script without flag

## Running Initialization

Based on alias check above, run one of:

**With alias setup:**
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/init.sh --setup-alias

**Without alias setup:**
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/init.sh

## Next Steps

Based on the initialization results above, proceed with:

- **New projects:** Define vision and scope with research workflows
- **Existing projects:** Review generated documentation for accuracy

Run `/spec-drive:status` to check project health.
