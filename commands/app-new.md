---
name: spec-drive:app-new
description: Initialize new project with comprehensive discovery interview and spec generation
allowed-tools: "*"
---

# app-new: Initialize New Project

Initialize a new project through comprehensive discovery interview, generating rich specifications and AI-navigable documentation.

**What it does:**
1. Conducts 6-phase discovery interview (via `project-discovery` skill)
2. Creates comprehensive APP-001 spec with all project context
3. Generates AI-navigable index for project navigation
4. Initializes development workspace
5. Sets workflow state (workflow=app-new, spec=APP-001, stage=discover)

**Prerequisites:**
- No active workflow (must complete or abandon current workflow first)
- spec-drive plugin initialized in project

**Duration:** 30-45 minutes for thorough discovery

---

## Execution Instructions

### The `project-discovery` Skill Will Guide You

When this command is invoked, the **project-discovery** skill will automatically activate and guide you through a comprehensive 6-phase discovery interview:

1. **Project Context** (3-5 min) - What, why, success criteria
2. **Users Deep Dive** (5-10 min) - User types, goals, pain points, needs
3. **Features Exploration** (10-15 min) - Features, workflows, priorities, risks
4. **Technical Context** (5-10 min) - Stack, architecture, integrations, data
5. **Constraints & Risks** (5 min) - Timeline, team, budget, risks
6. **Success Criteria** (3-5 min) - MVP definition, metrics, future vision

### Interview Approach

- Ask thoughtful questions following the skill's framework
- Be curious - probe "why" and ask for examples
- Surface risks and unknowns early
- Validate understanding throughout
- Document all context, decisions, and open questions

### After Discovery Completes

The skill will:
1. Structure all discovery data as JSON
2. Write to `/tmp/discovery-data.json`
3. Execute the initialization script
4. Report what was created and next steps

---

## What Gets Created

**Specifications:**
- `.spec-drive/specs/APP-001.yaml` - Comprehensive project spec with all discovery context
- `.spec-drive/index.yaml` - AI-navigable index with entry points and references

**Development Workspace:**
- `.spec-drive/development/current/APP-001/` - Independent planning workspace
  - `CONTEXT.md` - Development context and decisions
  - `PLAN.md` - Implementation plan
  - `TASKS.md` - Task tracking

**Workflow State:**
- `.spec-drive/state.yaml` - Updated with workflow=app-new, spec=APP-001, stage=discover

---

## Quality Gates

The discovery process ensures:
- [ ] All 6 phases completed
- [ ] Multiple user types identified with goals/needs
- [ ] Features detailed with user value and priorities
- [ ] Tech stack choices justified (not just listed)
- [ ] Risks identified and assessed
- [ ] MVP scope clearly defined
- [ ] Open questions documented

---

## Next Steps

After app-new completes:

1. **Review generated spec:** `.spec-drive/specs/APP-001.yaml`
2. **Check AI index:** `.spec-drive/index.yaml`
3. **Review development workspace:** `.spec-drive/development/current/APP-001/`
4. **Resolve open questions** if any were documented
5. **Start building features:** `/spec-drive:feature` when ready

---

## Tips for Success

- **Take your time** - Thorough discovery prevents rework later
- **Ask for concrete examples** - Abstract descriptions lead to gaps
- **Explore the "why"** - Motivations matter more than features
- **Surface tensions** - Conflicting needs or unrealistic timeline?
- **Document unknowns** - "I don't know" is valid, track it
- **Validate often** - Summarize and confirm understanding

---

## Troubleshooting

**If discovery feels incomplete:**
- Mark `completeness: "partial"` in metadata
- Document what's missing in `open_questions`
- Can refine spec later before advancing workflow

**If time-constrained:**
- Focus on critical/high priority features
- Document lower priority items in `future_vision`
- Schedule follow-up session for deeper dive

**If technical unknowns exist:**
- Document in `risks` with type="technical"
- Note research needed in `open_questions`
- Can resolve during specify/implement stages
