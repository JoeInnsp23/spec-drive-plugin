---
name: spec-drive:app-new
description: Initialize new project with planning session and documentation
allowed-tools: "*"
argument_hint: "[project-name]"
---

# app-new: Initialize New Project

This command initializes a new project with planning session and documentation.

**What it does:**
1. Gathers project planning information via conversation
2. Creates the APP-001 spec capturing planning decisions
3. Generates initial documentation suite (README, ARCHITECTURE, etc.)
4. Initializes workflow state (workflow=app-new, spec=APP-001, stage=discover)

**Prerequisites:**
- No active workflow (must complete or abandon current workflow first)
- spec-drive plugin initialized in project

---

## Step 1: Gather Project Information

**IMPORTANT:** Gather ALL information BEFORE running the script. Do NOT run the script until you have all answers.

Ask the user for the following (use AskUserQuestion or natural conversation):

1. **Project name** (if not provided as argument)
   - Must be alphanumeric with dashes/underscores only

2. **Project vision** (required)
   - What are you building? (1-2 sentences)

3. **Key features** (required, 1-5 features)
   - What are the main features of this project?
   - Collect as comma-separated or list, then join with pipes (|)

4. **Target users** (required)
   - Who are the primary user personas?

5. **Tech stack** (required)
   - What technologies will you use? (e.g., Node.js, React, PostgreSQL)

## Step 2: Run Non-Interactive Script

Once you have ALL answers, run:

```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh \
  --name "<project-name>" \
  --vision "<project vision>" \
  --features "<feature1>|<feature2>|<feature3>" \
  --users "<target users>" \
  --stack "<tech stack>"
```

**Example:**
```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh \
  --name "page-ivy" \
  --vision "Modern accountancy firm website combining best elements from foxi and blackspike sites" \
  --features "Modern design system|Responsive layout|SEO optimization|Blog system|Landing pages" \
  --users "Accountancy firm clients seeking professional services, SEO-focused for Google Ads" \
  --stack "Astro, TypeScript, Tailwind CSS"
```

**Next Steps:**
After app-new completes, use `/spec-drive:feature` to start building features.
