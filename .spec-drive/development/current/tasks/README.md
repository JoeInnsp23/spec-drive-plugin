# Tasks Directory

Individual task files for implementation tracking.

## Structure

```
tasks/
├── phase-1-foundation/     # Plugin setup, templates, directories
├── phase-2-workflows/      # Workflow engine, app-new, feature
├── phase-3-autodocs/       # Documentation auto-update system
└── phase-4-quality-gates/  # Quality gate scripts
```

## Task File Format

Each task file (`task-XXX-name.md`) contains:
- Task ID and title
- Status (not-started, in-progress, blocked, completed)
- Dependencies (what tasks must complete first)
- Acceptance criteria (testable conditions)
- Implementation details (steps, files, code snippets)
- Testing approach (how to verify)
- Risks and mitigations
- Completion checklist

## Benefits

- **Readable:** Each task is self-contained and focused
- **Trackable:** Clear status per task
- **Parallelizable:** Independent tasks can be worked concurrently
- **Reviewable:** Easy to review individual tasks
- **AI-friendly:** Claude can read one task file at a time

## Template

See `.spec-drive/templates/planning/TASK-TEMPLATE.md` for the standard template.

## Status

Current implementation uses `IMPLEMENTATION-PLAN.md` for high-level planning.
Individual task files can be created as needed for complex tasks.
