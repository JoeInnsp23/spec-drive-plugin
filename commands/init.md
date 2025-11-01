---
name: init
description: Initialize spec-drive in project (new or existing)
allowed-tools: "*"
---

# Initialize spec-drive

Initializes spec-drive development system in current project.

Detects project type and runs appropriate initialization:
- **New project:** Scaffold structure + templates
- **Existing project:** Analyze + archive + regenerate docs

## Running Initialization

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/init.sh`

## Next Steps

Based on the initialization results above, proceed with:

- **New projects:** Define vision and scope with research workflows
- **Existing projects:** Review generated documentation for accuracy

Run `/spec-drive:status` to check project health.
