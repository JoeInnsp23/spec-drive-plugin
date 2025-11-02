---
name: project-discovery
description: "Conducts comprehensive discovery interviews for new software projects. This skill should be used when initializing new projects via /spec-drive:app-new. Guides through structured 6-phase discovery to gather project context, user needs, features, technical requirements, constraints, and success criteria using AskUserQuestion tool and conversational follow-ups."
allowed-tools: AskUserQuestion, Write, Bash, Read
---

# Project Discovery Skill

## Purpose

Conduct comprehensive discovery interviews for new software projects, gathering all context needed to generate rich specifications and documentation.

## When to Use

Automatically invoke during `/spec-drive:app-new` workflow initialization.

## Duration

30-45 minutes for thorough discovery.

## Output

Structured JSON containing all project context, which generates comprehensive YAML specs and AI-navigable index.

---

## Discovery Process

Conduct a 6-phase interview combining structured questions (via AskUserQuestion tool) with conversational follow-ups for deeper exploration.

### Interview Principles

- **Use AskUserQuestion tool for ALL questions** - Every question goes through AskUserQuestion tool. For open-ended questions, use a single "Enter manually" option. For multiple-choice questions, provide the actual options.
- **Ask "why"** - Uncover motivations and value, not just features
- **Be curious** - Follow interesting threads, explore edge cases
- **Validate assumptions** - Confirm understanding with user
- **Surface risks early** - Identify technical and business uncertainties
- **Document open questions** - Track unknowns for later resolution

---

## Phase 1: Project Context (3-5 min)

**Goal:** Understand the project at a high level - what, why, and success criteria.

### Questions to Ask

Use AskUserQuestion tool for each question below (each with single "Enter manually" option):

1. Project name (header "Name")
2. What are you building? (header "Description", ask for 1-2 sentence description)
3. Why are you building it? What problem does it solve? (header "Problem")
4. What sparked this idea? (header "Inspiration")
5. How will you measure success? What metrics matter? (header "Metrics")

### Follow-Up Prompts

- "Can you give me a concrete example of this problem in action?"
- "What happens if this doesn't exist - what's the workaround?"
- "Is this replacing something existing, or entirely new?"

### Data to Capture

- project.name
- project.vision (1-2 sentences)
- project.problem_statement
- project.inspiration
- project.success_metrics (array)

---

## Phase 2: Users Deep Dive (5-10 min)

**Goal:** Deeply understand WHO will use this and WHY they need it.

### Questions to Ask

Use AskUserQuestion tool to ask: "Who will use this? List all user types/personas" (header "Users", single "Enter manually" option).

For EACH user type identified, use AskUserQuestion tool for these questions (each with single "Enter manually" option unless specified):

1. What is their role/context? (header "Role")
2. What are they trying to accomplish? (header "Goals")
3. What frustrates them today? (header "Pain Points")
4. What do they need from this tool? (header "Needs")
5. How/when/where will they use this? (header "Usage Context")
6. What alternatives are they using now? (header "Alternatives")
7. Technical level (header "Tech Level", options: Beginner/Intermediate/Advanced/Expert with descriptions)

### Follow-Up Prompts

- "Walk me through a typical day for this user - where does your tool fit?"
- "What would delight this user? What would frustrate them?"
- "Are there conflicts between different user types' needs?"

### Data to Capture

For each user:
- users[].type
- users[].role_context
- users[].goals (array)
- users[].pain_points (array)
- users[].needs (array)
- users[].interaction_patterns
- users[].technical_level
- users[].current_alternatives (array)

---

## Phase 3: Features Exploration (10-15 min)

**Goal:** Understand WHAT to build - features, workflows, and priorities.

### Questions to Ask

Use AskUserQuestion tool to ask: "What are the key features? List 5-10 core features" (header "Features", single "Enter manually" option).

For EACH feature identified, use AskUserQuestion tool for these questions:

1. Priority (header "Priority", options: Critical/High/Medium/Nice-to-have with descriptions)
2. Complexity (header "Complexity", options: Simple/Moderate/Complex with descriptions)
3. Why is this feature important? What user value does it deliver? (header "Value", single "Enter manually" option)
4. Describe the functionality (header "Functionality", single "Enter manually" option)
5. Walk me through the user flow step-by-step (header "User Flow", single "Enter manually" option)
6. What does this feature depend on? (header "Dependencies", single "Enter manually" option)
7. What could go wrong? Any risks? (header "Risks", single "Enter manually" option)
8. Any edge cases to consider? (header "Edge Cases", single "Enter manually" option)

### Follow-Up Prompts

- "Can you show me a concrete example of using this feature?"
- "What happens if this feature fails - how critical is it?"
- "Does this feature integrate with anything external?"
- "What's the simplest version of this (MVP)?"
- "What would the 'deluxe' version include?"

### Feature Categories to Probe

- Core workflows (critical path)
- Data management (CRUD, import/export)
- User management (auth, permissions)
- Integration (APIs, webhooks, third-party)
- Reporting/analytics (dashboards, exports)
- Admin/ops (config, monitoring, logs)

### Data to Capture

For each feature:
- features[].title
- features[].description
- features[].user_value (the "why")
- features[].user_flow (step-by-step)
- features[].priority
- features[].complexity
- features[].dependencies (array)
- features[].risks (array)
- features[].edge_cases (array)
- features[].mvp_scope
- features[].future_enhancements (array)

---

## Phase 4: Technical Context (5-10 min)

**Goal:** Understand technical stack, architecture, constraints, and integration needs.

### Questions to Ask

Use AskUserQuestion tool for these tech stack questions (can be in one call or separate):

1. Language (header "Language", options: TypeScript/Python/Go/Rust/Java with descriptions)
2. Framework (header "Framework", options: Next.js/FastAPI/Express/Django/Spring Boot with descriptions)
3. Database (header "Database", options: PostgreSQL/MongoDB/MySQL/SQLite/Redis with descriptions)

Then use AskUserQuestion tool for each of these (each with single "Enter manually" option):

4. Why did you choose [LANGUAGE]? (header "Language Rationale")
5. Why [FRAMEWORK]? (header "Framework Rationale")
6. Why [DATABASE]? (header "Database Rationale")
7. What's the high-level architecture? (header "Architecture", mention monolith/microservices/serverless)
8. Any architectural constraints or compliance requirements? (header "Compliance", mention HIPAA/SOC2/GDPR)
9. What data needs to be stored? Any sensitive/PII data? (header "Data")
10. Expected scale - users, data volume, traffic? (header "Scale")
11. Authentication approach? (header "Auth", mention OAuth/JWT/email/SSO)
12. Any role-based permissions needed? What roles? (header "Permissions")
13. Does this integrate with other systems? Which ones and how? (header "Integrations")
14. Where will this run? (header "Hosting", mention cloud/on-prem)
15. Any performance requirements? (header "Performance")

### Follow-Up Prompts

- "Have you used this stack before, or is it new?"
- "Any legacy systems to work with?"
- "Any vendor lock-in concerns?"
- "What about offline/degraded mode?"

### Data to Capture

- technical.stack.language, language_rationale
- technical.stack.framework, framework_rationale
- technical.stack.database, database_rationale
- technical.stack.hosting, hosting_rationale
- technical.stack.other_tools (array)
- technical.architecture.style
- technical.architecture.architectural_constraints (array)
- technical.architecture.compliance_requirements (array)
- technical.data.storage_needs (array)
- technical.data.scale_expectations
- technical.data.sensitive_data (boolean)
- technical.data.sensitive_data_types (array)
- technical.data.backup_requirements
- technical.auth.approach
- technical.auth.methods (array)
- technical.auth.role_based_access (boolean)
- technical.auth.roles (array)
- technical.integrations[] (system, purpose, data_exchanged, frequency, api_available, notes)
- technical.infrastructure.hosting_platform
- technical.infrastructure.cicd_preference
- technical.infrastructure.monitoring_needs (array)
- technical.infrastructure.performance_requirements

---

## Phase 5: Constraints & Risks (5 min)

**Goal:** Surface limitations, risks, and potential blockers early.

### Questions to Ask

Use AskUserQuestion tool for these questions:

1. Timeline (header "Timeline", options: Hard deadline/Soft target/No deadline with descriptions)

Then use AskUserQuestion tool for each of these (each with single "Enter manually" option):

2. When is the target date? (header "Target Date", if deadline exists)
3. What's driving this timeline? (header "Timeline Drivers")
4. Are there milestones or phases? (header "Milestones")
5. Who's working on this? Team size and roles? (header "Team")
6. Any skill gaps on the team? (header "Skill Gaps")
7. Any budget constraints? (header "Budget")
8. What technical unknowns worry you? (header "Technical Unknowns")
9. What could derail this project? (header "Derailers")
10. What's the biggest uncertainty? (header "Biggest Uncertainty")

### Follow-Up Prompts

- "What happens if we miss the deadline?"
- "Are there phases/milestones, or all-or-nothing?"
- "What's the fallback if this doesn't work?"
- "Any political/organizational risks?"
- "What keeps you up at night about this?"

### Data to Capture

- constraints.timeline.target_date
- constraints.timeline.hard_deadline (boolean)
- constraints.timeline.drivers (array)
- constraints.timeline.milestones (array)
- constraints.team.size
- constraints.team.roles (array)
- constraints.team.skill_gaps (array)
- constraints.budget.constraints (array)
- constraints.budget.infrastructure_budget
- constraints.budget.service_budget
- risks[] (type, description, likelihood, impact, mitigation)

---

## Phase 6: Success Criteria (3-5 min)

**Goal:** Define what "done" looks like and future vision.

### Questions to Ask

Use AskUserQuestion tool for each of these questions (each with single "Enter manually" option):

1. What's the minimum viable product? What can you cut and still deliver value? (header "MVP")
2. What must be in v1? (header "V1 Must-Haves")
3. How will you measure success? What KPIs? (header "Success Metrics")
4. What would make this a home run? (header "Home Run")
5. What's the long-term vision? (header "Long-term Vision")
6. What comes after MVP? (header "Post-MVP")
7. Any blue-sky features for later? (header "Future Features")

### Follow-Up Prompts

- "If you could only ship 3 features, which ones?"
- "What would make users love this vs. just use it?"
- "What's the 1-year vision? 3-year?"

### Data to Capture

- success.mvp_scope (array)
- success.must_have_features (array)
- success.metrics (array)
- success.definition_of_done
- success.future_vision.long_term_goals (array)
- success.future_vision.future_phases (array)
- success.future_vision.blue_sky_features (array)

---

## Interview Techniques

### Active Listening
- Paraphrase: "So what I'm hearing is..."
- Confirm: "Did I understand that correctly?"
- Probe deeper: "Tell me more about that"

### Uncover Assumptions
- "What are we assuming about users?"
- "What are we assuming about technology?"
- "What hasn't been discussed yet?"

### Validate Understanding
- Summarize periodically: "Let me summarize what we've covered..."
- Ask: "Does this accurately represent your vision?"
- Ask: "What did I miss?"

### Surface Unknowns
- Track "I don't know" answers → add to open_questions
- Note contradictions or conflicts
- Identify areas needing research

### Adaptive Follow-Ups
- Follow interesting threads
- Ask for concrete examples when user is abstract
- Always probe "why" for features and tech choices
- Explore edge cases and failure modes

---

## Execution Steps

### 1. Conduct Interview

Work through all 6 phases, using AskUserQuestion tool for structured questions and conversational follow-ups for depth.

Throughout the interview, track:
- Questions the user couldn't answer (add to open_questions with context and priority)
- Areas of uncertainty
- Contradictions or conflicts
- Technical unknowns requiring research

### 2. Structure Data as JSON

After completing all phases, build a complete JSON object with this structure:

```json
{
  "project": {...},
  "users": [{...}],
  "features": [{...}],
  "technical": {...},
  "constraints": {...},
  "risks": [{...}],
  "success": {...},
  "open_questions": [{...}],
  "metadata": {
    "interview_date": "ISO-8601 timestamp",
    "interview_duration_minutes": 0,
    "interviewer": "Claude",
    "completeness": "complete|partial"
  }
}
```

Include all fields captured during the interview. For array fields, include all items gathered. For missing data, use empty arrays or note in open_questions.

### 3. Validate Data

Before proceeding, confirm:
- All 6 phases completed
- At least 3 user types identified
- At least 5 features detailed
- Tech stack choices include rationale (not just selections)
- Risks identified and assessed
- MVP scope clearly defined
- Open questions documented

If time-constrained or user prefers shorter session, mark completeness as "partial" and document what's missing in open_questions.

### 4. Write JSON to Temp File

Use Write tool to save the JSON:
- file_path: "/tmp/discovery-data.json"
- content: the complete JSON string

### 5. Run Initialization Script

Use Bash tool to run:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh --discovery-json "$(cat /tmp/discovery-data.json)"
```

### 6. Cleanup Temp File

Use Bash tool to delete:
```bash
rm -f /tmp/discovery-data.json
```

### 7. Report Results

Show the user:
- What was created (spec, index, workspace)
- Next steps (review spec, resolve open questions, advance workflow)
- Any open questions that need resolution

---

## Tips for Success

1. **Take time** - Don't rush through phases; thorough discovery prevents rework
2. **Ask for examples** - Concrete examples beat abstract descriptions
3. **Explore the "why"** - Motivations matter more than features
4. **Surface tensions** - Identify conflicting needs or unrealistic timelines
5. **Document unknowns** - "I don't know" is valid; track it
6. **Validate often** - Summarize and confirm understanding throughout
7. **Stay curious** - Follow interesting threads
8. **Think like an architect** - Consider how everything fits together

---

## Common Pitfalls to Avoid

- **Feature-focused only** - Don't skip users, constraints, risks
- **Assuming user context** - Always ask about user goals and pain points
- **Tech stack without rationale** - Always ask "why this choice?"
- **Ignoring risks** - Surface uncertainties early
- **Vague success criteria** - Push for specific, measurable metrics
- **Skipping open questions** - Track what's unknown

---

## Example Interview Flow

Start: "Let's conduct a comprehensive discovery for your project. This will take 30-45 minutes. We'll cover project context, users, features, technical details, constraints, and success criteria. Ready to begin?"

Phase 1: "Let's start with the big picture. What are you building?"
→ Follow with why, inspiration, success metrics

Phase 2: "Great! Now who will use this?"
→ For each user type, explore goals, pain points, needs, technical level

Phase 3: "What are the key features?"
→ For each feature, get priority/complexity (AskUserQuestion), then explore value, flow, risks

Phase 4: "Let's talk technical details. What tech stack?"
→ Use AskUserQuestion for language/framework/database, then explore rationale, architecture, integrations

Phase 5: "What constraints and risks should we consider?"
→ Use AskUserQuestion for timeline, then explore team, budget, risks

Phase 6: "Finally, what does success look like?"
→ Explore MVP, metrics, future vision

Validate: "Let me summarize everything we've covered..."
→ Confirm understanding, fill gaps

Execute: Build JSON, write to file, run script, cleanup, report results

---

## Next Steps After Discovery

The initialization script creates:
1. Comprehensive APP-001 spec with all discovery context
2. AI-navigable index for project navigation
3. Development workspace with planning docs
4. Workflow state set to "discover" stage

The user should then:
- Review generated spec (.spec-drive/specs/APP-001.yaml)
- Check AI index (.spec-drive/index.yaml)
- Review workspace (.spec-drive/development/current/APP-001/)
- Resolve any open questions documented
- Advance to "specify" stage when ready
- Begin feature development
