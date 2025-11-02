---
name: project-discovery
description: "Conduct comprehensive discovery interview for new software projects. Guides through structured 6-phase discovery process to gather project context, user needs, features, technical requirements, constraints, and success criteria. Use when initializing new projects via /spec-drive:app-new."
allowed-tools: AskUserQuestion, Write, Bash, Read
---

# Project Discovery Skill

**Purpose:** Guide comprehensive discovery interview for new software projects, gathering all context needed to generate rich specifications and documentation.

**When to Use:** Automatically invoked during `/spec-drive:app-new` workflow initialization.

**Duration:** 30-45 minutes for thorough discovery

**Output:** Structured JSON containing all project context, which generates comprehensive YAML specs and AI-navigable index.

---

## Discovery Interview Framework

### Overview

This skill guides you through a **6-phase discovery interview** designed to uncover the full context of a new software project. Each phase has core questions and adaptive follow-ups.

**Interview Principles:**
- **Ask "why"** - Uncover motivations and value, not just features
- **Be curious** - Follow interesting threads, explore edge cases
- **Validate assumptions** - Confirm understanding with user
- **Surface risks early** - Identify technical and business uncertainties
- **Document open questions** - Track unknowns for later resolution

---

## Phase 1: Project Context (3-5 min)

**Goal:** Understand the project at a high level - what, why, and success criteria.

### Core Questions

1. **What are you building?**
   - Get 1-2 sentence description
   - Ask for project name

2. **Why are you building it?**
   - What problem does it solve?
   - What gap in the market/workflow?
   - What sparked this idea?

3. **What does success look like?**
   - How will you know it's working?
   - What metrics matter?
   - What's the ultimate goal?

### Follow-Up Prompts

- "Can you give me a concrete example of this problem in action?"
- "What happens if this doesn't exist - what's the workaround?"
- "Is this replacing something existing, or entirely new?"
- "What inspired this - personal pain point, market research, client request?"

### Data to Capture

```yaml
project:
  name: string
  vision: string (1-2 sentences)
  problem_statement: string
  inspiration: string
  success_metrics: [strings]
```

---

## Phase 2: Users Deep Dive (5-10 min)

**Goal:** Deeply understand WHO will use this and WHY they need it.

### Core Questions

1. **Who will use this?**
   - List all user types/personas
   - For each: "What's their role/context?"

2. **For EACH user type, explore:**
   - **Goals:** "What are they trying to accomplish?"
   - **Pain Points:** "What frustrates them today?"
   - **Needs:** "What do they need from this tool?"
   - **Interaction:** "How/when/where will they use this?"
   - **Skills:** "What's their technical level?"

### Follow-Up Prompts

- "Walk me through a typical day for this user - where does your tool fit?"
- "What alternatives are they using now? Why insufficient?"
- "What would delight this user? What would frustrate them?"
- "How tech-savvy are they? CLI comfortable? API familiar?"
- "Are there conflicts between different user types' needs?"

### Data to Capture

```yaml
users:
  - type: string
    role_context: string
    goals: [strings]
    pain_points: [strings]
    needs: [strings]
    interaction_patterns: string
    technical_level: string (beginner|intermediate|advanced|expert)
    current_alternatives: [strings]
```

---

## Phase 3: Features Exploration (10-15 min)

**Goal:** Understand WHAT to build - features, workflows, and priorities.

### Core Questions

1. **What are the key features?**
   - List 5-10 core features
   - Get rough priority (critical, high, medium, nice-to-have)

2. **For EACH feature (especially critical/high):**
   - **Why important?** "What user value does this deliver?"
   - **What does it do?** "Describe the functionality"
   - **How does it work?** "Walk me through the user flow"
   - **Complexity?** "Simple, moderate, or complex?"
   - **Dependencies?** "What does this depend on?"
   - **Risks?** "What could go wrong?"

### Follow-Up Prompts

- "Can you show me a concrete example of using this feature?"
- "What happens if this feature fails - how critical is it?"
- "Are there edge cases we should consider?"
- "Does this feature integrate with anything external?"
- "What's the simplest version of this (MVP)?"
- "What would the 'deluxe' version include?"

### Feature Categories to Probe

- **Core workflows** (critical path)
- **Data management** (CRUD, import/export)
- **User management** (auth, permissions)
- **Integration** (APIs, webhooks, third-party)
- **Reporting/analytics** (dashboards, exports)
- **Admin/ops** (config, monitoring, logs)

### Data to Capture

```yaml
features:
  - title: string
    description: string
    user_value: string (the "why")
    user_flow: string (step-by-step)
    priority: string (critical|high|medium|nice-to-have)
    complexity: string (simple|moderate|complex)
    dependencies: [strings]
    risks: [strings]
    edge_cases: [strings]
    mvp_scope: string
    future_enhancements: [strings]
```

---

## Phase 4: Technical Context (5-10 min)

**Goal:** Understand technical stack, architecture, constraints, and integration needs.

### Core Questions

1. **Tech Stack**
   - "What technologies do you want to use?"
   - **For each:** "Why this choice?"
   - Language, framework, database, hosting, etc.

2. **Architecture**
   - "What's the high-level architecture?" (monolith, microservices, serverless, etc.)
   - "Any architectural constraints or requirements?"
   - "Any compliance needs?" (HIPAA, SOC2, GDPR, etc.)

3. **Data & Storage**
   - "What data needs to be stored?"
   - "How much data? Scale expectations?"
   - "Any sensitive/PII data?"
   - "Backup/disaster recovery needs?"

4. **Authentication & Authorization**
   - "Who can access what?"
   - "Auth approach?" (email/password, OAuth, SSO, API keys, etc.)
   - "Role-based permissions needed?"

5. **Integrations**
   - "Does this need to integrate with other systems?"
   - **For each:** "What's exchanged? How often? APIs available?"
   - "Any webhooks or real-time data?"

6. **Infrastructure**
   - "Where will this run?" (cloud provider, on-prem, hybrid)
   - "Any DevOps/CI-CD preferences?"
   - "Monitoring/observability needs?"

### Follow-Up Prompts

- "Have you used this stack before, or is it new?"
- "Any performance requirements (response time, throughput)?"
- "Expected scale - users, data volume, traffic?"
- "Any legacy systems to work with?"
- "Any vendor lock-in concerns?"
- "What about offline/degraded mode?"

### Data to Capture

```yaml
technical:
  stack:
    language: string
    language_rationale: string
    framework: string
    framework_rationale: string
    database: string
    database_rationale: string
    hosting: string
    hosting_rationale: string
    other_tools: [strings]

  architecture:
    style: string (monolith|microservices|serverless|hybrid)
    architectural_constraints: [strings]
    compliance_requirements: [strings]

  data:
    storage_needs: [strings]
    scale_expectations: string
    sensitive_data: boolean
    sensitive_data_types: [strings]
    backup_requirements: string

  auth:
    approach: string
    methods: [strings]
    role_based_access: boolean
    roles: [strings]

  integrations:
    - system: string
      purpose: string
      data_exchanged: string
      frequency: string
      api_available: boolean
      notes: string

  infrastructure:
    hosting_platform: string
    cicd_preference: string
    monitoring_needs: [strings]
    performance_requirements: string
```

---

## Phase 5: Constraints & Risks (5 min)

**Goal:** Surface limitations, risks, and potential blockers early.

### Core Questions

1. **Timeline**
   - "When do you need this?"
   - "Any hard deadlines?"
   - "What's driving the timeline?"

2. **Team**
   - "Who's working on this?"
   - "Team size and skills?"
   - "Any skill gaps?"

3. **Budget**
   - "Any budget constraints?"
   - "Infrastructure costs a concern?"
   - "Third-party service costs?"

4. **Technical Risks**
   - "What technical unknowns worry you?"
   - "Any unproven technology choices?"
   - "Any integration risks?"

5. **Business Risks**
   - "What could derail this project?"
   - "What assumptions are we making?"
   - "What's the biggest uncertainty?"

### Follow-Up Prompts

- "What happens if we miss the deadline?"
- "Are there phases/milestones, or all-or-nothing?"
- "What's the fallback if this doesn't work?"
- "Any political/organizational risks?"
- "What keeps you up at night about this?"

### Data to Capture

```yaml
constraints:
  timeline:
    target_date: string
    hard_deadline: boolean
    drivers: [strings]
    milestones: [strings]

  team:
    size: number
    roles: [strings]
    skill_gaps: [strings]

  budget:
    constraints: [strings]
    infrastructure_budget: string
    service_budget: string

risks:
  - type: string (technical|business|team|timeline)
    description: string
    likelihood: string (low|medium|high)
    impact: string (low|medium|high)
    mitigation: string
```

---

## Phase 6: Success Criteria (3-5 min)

**Goal:** Define what "done" looks like and future vision.

### Core Questions

1. **MVP Definition**
   - "What's the minimum viable product?"
   - "What can we cut and still deliver value?"
   - "What must be in v1?"

2. **Success Metrics**
   - "How will you measure success?"
   - "What KPIs matter?"
   - "What would make this a home run?"

3. **Future Vision**
   - "What's the long-term vision?"
   - "What comes after MVP?"
   - "Any blue-sky features for later?"

### Follow-Up Prompts

- "If you could only ship 3 features, which ones?"
- "What would make users love this vs. just use it?"
- "What's the 1-year vision? 3-year?"
- "How will you know it's time to add more features?"

### Data to Capture

```yaml
success:
  mvp_scope: [strings]
  must_have_features: [strings]
  metrics: [strings]
  definition_of_done: string

  future_vision:
    long_term_goals: [strings]
    future_phases: [strings]
    blue_sky_features: [strings]
```

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
- "Let me summarize what we've covered..."
- "Does this accurately represent your vision?"
- "What did I miss?"

### Surface Unknowns
- Track "I don't know" answers → open questions
- Note contradictions or conflicts
- Identify areas needing research

### Adaptive Follow-Ups
- Follow interesting threads
- Ask for examples when abstract
- Probe "why" for features/tech choices
- Explore edge cases and failure modes

---

## Output Format

After completing the interview, structure all gathered information as JSON:

```json
{
  "project": {
    "name": "string",
    "vision": "string",
    "problem_statement": "string",
    "inspiration": "string",
    "success_metrics": ["string"]
  },
  "users": [
    {
      "type": "string",
      "role_context": "string",
      "goals": ["string"],
      "pain_points": ["string"],
      "needs": ["string"],
      "interaction_patterns": "string",
      "technical_level": "string",
      "current_alternatives": ["string"]
    }
  ],
  "features": [
    {
      "title": "string",
      "description": "string",
      "user_value": "string",
      "user_flow": "string",
      "priority": "string",
      "complexity": "string",
      "dependencies": ["string"],
      "risks": ["string"],
      "edge_cases": ["string"],
      "mvp_scope": "string",
      "future_enhancements": ["string"]
    }
  ],
  "technical": {
    "stack": {
      "language": "string",
      "language_rationale": "string",
      "framework": "string",
      "framework_rationale": "string",
      "database": "string",
      "database_rationale": "string",
      "hosting": "string",
      "hosting_rationale": "string",
      "other_tools": ["string"]
    },
    "architecture": {
      "style": "string",
      "architectural_constraints": ["string"],
      "compliance_requirements": ["string"]
    },
    "data": {
      "storage_needs": ["string"],
      "scale_expectations": "string",
      "sensitive_data": false,
      "sensitive_data_types": ["string"],
      "backup_requirements": "string"
    },
    "auth": {
      "approach": "string",
      "methods": ["string"],
      "role_based_access": false,
      "roles": ["string"]
    },
    "integrations": [
      {
        "system": "string",
        "purpose": "string",
        "data_exchanged": "string",
        "frequency": "string",
        "api_available": true,
        "notes": "string"
      }
    ],
    "infrastructure": {
      "hosting_platform": "string",
      "cicd_preference": "string",
      "monitoring_needs": ["string"],
      "performance_requirements": "string"
    }
  },
  "constraints": {
    "timeline": {
      "target_date": "string",
      "hard_deadline": false,
      "drivers": ["string"],
      "milestones": ["string"]
    },
    "team": {
      "size": 0,
      "roles": ["string"],
      "skill_gaps": ["string"]
    },
    "budget": {
      "constraints": ["string"],
      "infrastructure_budget": "string",
      "service_budget": "string"
    }
  },
  "risks": [
    {
      "type": "string",
      "description": "string",
      "likelihood": "string",
      "impact": "string",
      "mitigation": "string"
    }
  ],
  "success": {
    "mvp_scope": ["string"],
    "must_have_features": ["string"],
    "metrics": ["string"],
    "definition_of_done": "string",
    "future_vision": {
      "long_term_goals": ["string"],
      "future_phases": ["string"],
      "blue_sky_features": ["string"]
    }
  },
  "open_questions": [
    {
      "question": "string",
      "context": "string",
      "priority": "string"
    }
  ],
  "metadata": {
    "interview_date": "ISO-8601 timestamp",
    "interview_duration_minutes": 0,
    "interviewer": "Claude",
    "completeness": "string (partial|complete)"
  }
}
```

---

## Execution Instructions

### After Interview Completion

1. **Validate Data**
   - Confirm all required fields populated
   - Check for contradictions or gaps
   - Review open questions with user

2. **Write Discovery JSON**
   ```javascript
   Write the structured JSON to: /tmp/discovery-data.json
   ```

3. **Run Initialization Script**
   ```bash
   !bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh \
     --discovery-json "$(cat /tmp/discovery-data.json)"
   ```

4. **Report Results**
   - Show user what was created
   - Highlight next steps
   - Note any open questions to resolve

---

## Quality Gates

**Before running script, confirm:**
- [ ] All 6 phases completed
- [ ] At least 3 user types identified
- [ ] At least 5 features detailed
- [ ] Tech stack justified (not just listed)
- [ ] Risks identified and assessed
- [ ] MVP scope clearly defined
- [ ] Open questions documented

**Incomplete discovery:**
If time-constrained or user prefers shorter session, document what's missing in `open_questions` and note `completeness: "partial"` in metadata.

---

## Tips for Success

1. **Take your time** - Don't rush through phases
2. **Ask for examples** - Concrete beats abstract
3. **Explore the "why"** - Motivations matter more than features
4. **Surface tensions** - Conflicting needs? Timeline vs. scope?
5. **Document unknowns** - "I don't know" is valid, track it
6. **Validate often** - Summarize and confirm understanding
7. **Stay curious** - Follow interesting threads
8. **Think like an architect** - How does this all fit together?

---

## Common Pitfalls to Avoid

- **Feature-focused only** - Don't skip users, constraints, risks
- **Assuming user context** - Always ask about user goals/pain points
- **Tech stack without rationale** - Always ask "why this choice?"
- **Ignoring risks** - Surface uncertainties early
- **Vague success criteria** - Push for specific, measurable metrics
- **Skipping open questions** - Track what's unknown

---

## Example Interview Flow

```
You: Let's start with the big picture. What are you building?

User: A task management app for developers

You: Interesting! Why are you building this - what problem does it solve?

User: Existing tools don't integrate with git workflows

You: Can you give me a concrete example of that frustration?

User: [explains git issue tracking pain point]

You: What does success look like for this tool?

User: [describes metrics]

You: Great! Now let's talk about who will use this. What types of users?

User: Individual developers and team leads

You: Let's start with individual developers. What are their goals when using this?

[Continue through all 6 phases...]

You: Let me summarize what we've covered to make sure I have it right...
[Validate understanding]

You: What did I miss or get wrong?

[Final adjustments]

You: Perfect! I'll now generate the comprehensive project spec based on everything we discussed.

[Write JSON, run script]
```

---

## Next Steps After Discovery

The initialization script will:
1. Generate comprehensive APP-001 spec with all discovery context
2. Create AI-navigable index for project
3. Initialize development workspace
4. Set workflow state to "discover" stage
5. Provide user with next steps

**User can then:**
- Review generated spec
- Add/refine acceptance criteria
- Advance to "specify" stage when ready
- Begin feature development
