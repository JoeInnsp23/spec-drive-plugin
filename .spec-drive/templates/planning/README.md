# Planning Templates

Templates for all planning documents used in spec-drive development.

## Available Templates

- **TASK-TEMPLATE.md** - Individual task file format for detailed implementation tracking

## Usage

These templates ensure consistent structure across all planning documents.

### Task Template

The TASK-TEMPLATE.md provides a standard format for breaking down implementation work into trackable tasks:

- Clear status tracking
- Dependency management
- Acceptance criteria
- Implementation steps
- Testing approach
- Risk assessment
- Completion checklist

### Variables

Templates use `{{VARIABLE}}` placeholders that can be replaced with actual values when creating new documents.

Common variables:
- `{{TASK_ID}}` - Unique task identifier (e.g., 001, 002)
- `{{TASK_TITLE}}` - Brief task description
- `{{STATUS}}` - not-started, in-progress, blocked, completed
- `{{PHASE}}` - phase-1-foundation, phase-2-workflows, etc.
- `{{DATE}}` - Creation date (YYYY-MM-DD)

## Future Templates

Additional templates will be added as needed:
- PRD-TEMPLATE.md
- TDD-TEMPLATE.md
- TEST-PLAN-TEMPLATE.md
- RISK-ASSESSMENT-TEMPLATE.md
- STATUS-TEMPLATE.md

These can be created when there's a need to generate new planning documents following a consistent format.
