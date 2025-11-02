---
name: project-discovery
description: "Conduct comprehensive discovery interview for new software projects using AskUserQuestion tool. Use when initializing new projects via /spec-drive:app-new."
allowed-tools: AskUserQuestion, Write, Bash
---

# Project Discovery Skill

**Purpose:** Conduct comprehensive discovery interview using AskUserQuestion tool to gather all context for new software project.

**Duration:** 30-45 minutes for thorough discovery

**Output:** Structured JSON containing all project context

---

## Execution Instructions

When this skill is invoked, conduct the discovery interview by calling AskUserQuestion for each phase below. After all phases complete, structure the data as JSON and run the initialization script.

---

## Phase 1: Project Context

Use AskUserQuestion to gather basic project information:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "What is the name of your project?",
      header: "Project Name",
      options: [
        {label: "Enter manually", description: "Type the project name"}
      ],
      multiSelect: false
    }
  ]
})
```

Then ask about the project vision and purpose through natural conversation:
- "What are you building? (1-2 sentence description)"
- "Why are you building it? What problem does it solve?"
- "What inspired this project?"
- "How will you measure success?"

**Capture:**
- `project.name`
- `project.vision`
- `project.problem_statement`
- `project.inspiration`
- `project.success_metrics[]`

---

## Phase 2: Users

Ask about user types through conversation:
- "Who will use this? List all user types/personas"

For EACH user type identified, ask:
- "What is their role/context?"
- "What are their goals?"
- "What pain points do they have today?"
- "What do they need from this tool?"
- "How will they interact with it?"
- "What's their technical skill level?"
- "What alternatives are they using now?"

**Capture for each user:**
- `users[].type`
- `users[].role_context`
- `users[].goals[]`
- `users[].pain_points[]`
- `users[].needs[]`
- `users[].interaction_patterns`
- `users[].technical_level`
- `users[].current_alternatives[]`

---

## Phase 3: Features

Ask about features through conversation:
- "What are the key features? List 5-10 core features"

For EACH feature, use AskUserQuestion:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "What is the priority of this feature: [FEATURE_NAME]?",
      header: "Priority",
      options: [
        {label: "Critical", description: "Must have for MVP, blocks everything"},
        {label: "High", description: "Important for MVP, high user value"},
        {label: "Medium", description: "Nice to have in MVP, can defer"},
        {label: "Nice-to-have", description: "Future enhancement"}
      ],
      multiSelect: false
    }
  ]
})
```

Then ask through conversation for each feature:
- "Why is this feature important? What user value does it deliver?"
- "Describe the functionality"
- "Walk me through the user flow"
- "Is this simple, moderate, or complex to build?"
- "What does this feature depend on?"
- "What could go wrong? Any risks?"
- "Any edge cases to consider?"

**Capture for each feature:**
- `features[].title`
- `features[].description`
- `features[].user_value`
- `features[].user_flow`
- `features[].priority`
- `features[].complexity`
- `features[].dependencies[]`
- `features[].risks[]`
- `features[].edge_cases[]`
- `features[].mvp_scope`
- `features[].future_enhancements[]`

---

## Phase 4: Technical Context

Use AskUserQuestion for tech stack:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "What programming language will you use?",
      header: "Language",
      options: [
        {label: "TypeScript", description: "Type-safe JavaScript"},
        {label: "Python", description: "General purpose, data science"},
        {label: "Go", description: "Fast, concurrent"},
        {label: "Rust", description: "Safe, performant systems language"}
      ],
      multiSelect: false
    },
    {
      question: "What framework will you use?",
      header: "Framework",
      options: [
        {label: "Next.js", description: "React framework with SSR"},
        {label: "FastAPI", description: "Modern Python API framework"},
        {label: "Express", description: "Minimal Node.js framework"},
        {label: "Django", description: "Full-featured Python framework"}
      ],
      multiSelect: false
    },
    {
      question: "What database will you use?",
      header: "Database",
      options: [
        {label: "PostgreSQL", description: "Relational, ACID compliant"},
        {label: "MongoDB", description: "Document database, flexible schema"},
        {label: "SQLite", description: "Lightweight, embedded"},
        {label: "Redis", description: "In-memory cache/data store"}
      ],
      multiSelect: false
    }
  ]
})
```

Then ask through conversation:
- "Why did you choose [LANGUAGE]?"
- "Why [FRAMEWORK]?"
- "Why [DATABASE]?"
- "What's the high-level architecture? (monolith, microservices, serverless)"
- "Any architectural constraints or compliance requirements?"
- "What data needs to be stored? Any sensitive/PII data?"
- "Expected scale - users, data volume, traffic?"
- "Authentication approach? (OAuth, JWT, email/password, SSO)"
- "Any role-based permissions needed?"
- "Does this integrate with other systems? Which ones and how?"
- "Where will this run? (cloud provider, on-prem)"
- "Any performance requirements?"

**Capture:**
- `technical.stack.language`, `language_rationale`
- `technical.stack.framework`, `framework_rationale`
- `technical.stack.database`, `database_rationale`
- `technical.stack.hosting`, `hosting_rationale`
- `technical.stack.other_tools[]`
- `technical.architecture.style`
- `technical.architecture.architectural_constraints[]`
- `technical.architecture.compliance_requirements[]`
- `technical.data.storage_needs[]`
- `technical.data.scale_expectations`
- `technical.data.sensitive_data` (boolean)
- `technical.data.sensitive_data_types[]`
- `technical.data.backup_requirements`
- `technical.auth.approach`
- `technical.auth.methods[]`
- `technical.auth.role_based_access` (boolean)
- `technical.auth.roles[]`
- `technical.integrations[].system`, `purpose`, `data_exchanged`, `frequency`, `api_available`, `notes`
- `technical.infrastructure.hosting_platform`
- `technical.infrastructure.cicd_preference`
- `technical.infrastructure.monitoring_needs[]`
- `technical.infrastructure.performance_requirements`

---

## Phase 5: Constraints & Risks

Use AskUserQuestion:

```javascript
AskUserQuestion({
  questions: [
    {
      question: "Do you have a target launch date?",
      header: "Timeline",
      options: [
        {label: "Yes, hard deadline", description: "Must launch by specific date"},
        {label: "Yes, soft target", description: "Preferred date, flexible"},
        {label: "No deadline", description: "When it's ready"}
      ],
      multiSelect: false
    }
  ]
})
```

Then ask through conversation:
- "When is the target date?"
- "What's driving this timeline?"
- "Are there milestones or phases?"
- "Who's working on this? Team size and roles?"
- "Any skill gaps on the team?"
- "Any budget constraints?"
- "What technical unknowns worry you?"
- "What could derail this project?"
- "What's the biggest uncertainty?"

**Capture:**
- `constraints.timeline.target_date`
- `constraints.timeline.hard_deadline` (boolean)
- `constraints.timeline.drivers[]`
- `constraints.timeline.milestones[]`
- `constraints.team.size`
- `constraints.team.roles[]`
- `constraints.team.skill_gaps[]`
- `constraints.budget.constraints[]`
- `constraints.budget.infrastructure_budget`
- `constraints.budget.service_budget`
- `risks[].type`, `description`, `likelihood`, `impact`, `mitigation`

---

## Phase 6: Success Criteria

Ask through conversation:
- "What's the minimum viable product? What can you cut and still deliver value?"
- "What must be in v1?"
- "How will you measure success? What KPIs?"
- "What would make this a home run?"
- "What's the long-term vision?"
- "What comes after MVP?"

**Capture:**
- `success.mvp_scope[]`
- `success.must_have_features[]`
- `success.metrics[]`
- `success.definition_of_done`
- `success.future_vision.long_term_goals[]`
- `success.future_vision.future_phases[]`
- `success.future_vision.blue_sky_features[]`

---

## Validation & Open Questions

Throughout the interview, track any:
- Questions the user couldn't answer
- Areas of uncertainty
- Contradictions or conflicts
- Technical unknowns requiring research

**Capture:**
- `open_questions[].question`, `context`, `priority`

---

## Output JSON Format

After completing all phases, structure the data as JSON:

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
      "technical_level": "beginner|intermediate|advanced|expert",
      "current_alternatives": ["string"]
    }
  ],
  "features": [
    {
      "title": "string",
      "description": "string",
      "user_value": "string",
      "user_flow": "string",
      "priority": "critical|high|medium|nice-to-have",
      "complexity": "simple|moderate|complex",
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
      "style": "monolith|microservices|serverless|hybrid",
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
      "type": "technical|business|team|timeline",
      "description": "string",
      "likelihood": "low|medium|high",
      "impact": "low|medium|high",
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
      "priority": "high|medium|low"
    }
  ],
  "metadata": {
    "interview_date": "ISO-8601 timestamp",
    "interview_duration_minutes": 0,
    "interviewer": "Claude",
    "completeness": "complete|partial"
  }
}
```

---

## Final Step: Run Initialization

After structuring the JSON:

1. Write JSON to file:
```javascript
Write({
  file_path: "/tmp/discovery-data.json",
  content: "<json-string>"
})
```

2. Run initialization script:
```bash
!bash ${CLAUDE_PLUGIN_ROOT}/scripts/workflows/app-new/run.sh \
  --discovery-json "$(cat /tmp/discovery-data.json)"
```

3. Report results to user:
- What was created
- Next steps
- Any open questions to resolve
