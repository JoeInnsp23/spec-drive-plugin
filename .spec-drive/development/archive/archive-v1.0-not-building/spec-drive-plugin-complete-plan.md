# Spec-Drive Plugin - Complete Implementation Plan

**Version:** 1.0
**Date:** 2025-10-31
**Type:** Personal Plugin (like strict-concise)
**Estimated Effort:** ~32 hours

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Complete Feature Set](#complete-feature-set)
4. [Phase 1: Plugin Foundation](#phase-1-plugin-foundation)
5. [Phase 2: Workflow Definitions](#phase-2-workflow-definitions)
6. [Phase 3: Skills](#phase-3-skills)
7. [Phase 4: MCP Server](#phase-4-mcp-server)
8. [Phase 5: Commands](#phase-5-commands)
9. [Phase 6: Scripts & Utilities](#phase-6-scripts--utilities)
10. [Phase 7: Templates](#phase-7-templates)
11. [Phase 8: Documentation](#phase-8-documentation)
12. [Phase 9: Testing](#phase-9-testing)
13. [Implementation Checklist](#implementation-checklist)
14. [Open Questions](#open-questions)

---

## Executive Summary

**What:** A personal Claude Code plugin for spec-driven development with enforcing quality gates, unified multi-language documentation, and comprehensive project auditing.

**Key Decisions:**
- ✅ **Personal plugin** (installed to `~/.claude/plugins/spec-drive/`)
- ✅ **Full MCP server** included (6 tools: index_code, lint_spec, weave_docs, trace_spec, check_coverage, audit_project)
- ✅ **Enforcing gates by default** (blocks CI on violations)
- ✅ **No team marketplace** (direct install like strict-concise)
- ✅ **Multi-language support** (TypeScript, Python, Go, Rust)

**Components:**
- 11 slash commands
- 4 Skills (model-invoked)
- 6 MCP tools
- 4 YAML workflows
- 2 hooks (PostToolUse, SessionStart)
- Complete test suite

---

## Architecture Overview

### Directory Structure

```
~/.claude/plugins/spec-drive/
├── .claude-plugin/
│   └── plugin.json              # Minimal manifest (name, version, author, description)
├── commands/                     # 11 slash commands
│   ├── new-project.md
│   ├── feature.md
│   ├── bugfix.md
│   ├── research.md
│   ├── spec-init.md
│   ├── spec-lint.md
│   ├── spec-trace.md
│   ├── spec-check.md            # Enforcing by default
│   ├── docs-weave.md
│   ├── audit.md
│   ├── cleanup.md
│   └── status.md
├── skills/                       # 4 model-invoked Skills
│   ├── orchestrator/
│   │   ├── SKILL.md
│   │   └── workflows/           # YAML workflow definitions
│   │       ├── feature.yaml
│   │       ├── bugfix.yaml
│   │       ├── research.yaml
│   │       ├── app-new.yaml
│   │       └── schema.json
│   ├── specs/
│   │   └── SKILL.md
│   ├── docs/
│   │   └── SKILL.md
│   └── audit/
│       └── SKILL.md
├── hooks/
│   └── hooks.json               # PostToolUse, SessionStart
├── servers/
│   └── spec-drive-mcp/          # MCP server implementation
│       ├── src/
│       │   ├── index.ts
│       │   ├── tools/
│       │   │   ├── indexCode.ts
│       │   │   ├── lintSpec.ts
│       │   │   ├── weaveDocs.ts
│       │   │   ├── traceSpec.ts
│       │   │   ├── checkCoverage.ts
│       │   │   └── auditProject.ts
│       │   ├── parsers/
│       │   │   ├── typescript.ts
│       │   │   ├── python.ts
│       │   │   ├── go.ts
│       │   │   └── rust.ts
│       │   ├── schema/
│       │   │   └── specSchema.ts
│       │   └── utils/
│       ├── dist/                # Compiled JS
│       ├── package.json
│       ├── tsconfig.json
│       └── README.md
├── scripts/                      # Utilities
│   ├── attach.sh
│   ├── mark-dirty.sh
│   ├── session-status.sh
│   ├── validate.js
│   └── shared/
│       └── utils.js
├── templates/
│   ├── spec-template.yaml
│   ├── feature-workflow.yaml
│   └── reader-page.md
├── docs/
│   ├── README.md
│   ├── DEVELOPMENT.md
│   ├── WORKFLOWS.md
│   ├── MCP_TOOLS.md
│   └── SECURITY.md
├── tests/
│   ├── commands/
│   ├── skills/
│   ├── mcp/
│   └── integration/
├── .mcp.json                    # MCP server config
├── package.json                 # For MCP server dependencies
├── LICENSE
└── CHANGELOG.md
```

### Key Architecture Principles

1. **Convention-based discovery**: Directories discovered automatically, no manifest declarations
2. **MCP for heavy lifting**: Tree-sitter parsing, multi-language doc generation
3. **Skills for intelligence**: Model-invoked capabilities (orchestrator, specs, docs, audit)
4. **Commands for explicit actions**: User-invoked workflows
5. **Hooks for automation**: PostToolUse (mark dirty), SessionStart (status board)
6. **Enforcing gates**: Block CI by default, advisory mode optional

---

## Complete Feature Set

[Due to length, the complete detailed plan has been provided in the conversation above]

**Summary of all 9 phases:**

1. **Plugin Foundation** - Manifests, directory structure, hooks, MCP config
2. **Workflow Definitions** - 4 YAML workflows (feature, bugfix, research, app-new)
3. **Skills** - 4 model-invoked capabilities (orchestrator, specs, docs, audit)
4. **MCP Server** - 6 tools with TypeScript implementation
5. **Commands** - 11 slash commands for explicit workflows
6. **Scripts & Utilities** - Shell/JS utilities for hooks and commands
7. **Templates** - Spec and reader page templates
8. **Documentation** - README, DEVELOPMENT, WORKFLOWS, MCP_TOOLS, SECURITY guides
9. **Testing** - Command, Skill, MCP, and integration tests

---

## Quick Reference

### Installation
```bash
# Direct install (recommended for personal plugin)
/plugin install ~/.claude/plugins/spec-drive

# Or via user marketplace
/plugin marketplace add ~/.claude/plugins/
/plugin install spec-drive@user-plugins
```

### Key Commands
- `/spec-drive:feature AUTH-001 "User login"` - Start feature workflow
- `/spec-drive:spec-check --enforcing` - Run quality gates (blocks on failure)
- `/spec-drive:audit` - Full project health snapshot
- `/spec-drive:docs-weave typescript,python` - Generate multi-language docs
- `/spec-drive:spec-trace` - Rebuild trace index from @spec tags

### MCP Tools (auto-available when plugin loads)
1. **index_code** - Find @spec tags via tree-sitter
2. **lint_spec** - Validate YAML against schema
3. **weave_docs** - Multi-language doc harvesting
4. **trace_spec** - Build trace-index.yaml
5. **check_coverage** - Run 6 quality gates
6. **audit_project** - Generate AUDIT.md

### Quality Gates (enforcing by default)
1. ✅ spec-approved-has-code
2. ✅ spec-approved-has-tests
3. ✅ spec-approved-has-docs
4. ✅ spec-has-acceptance-criteria
5. ⚠️ code-has-spec-tag (warning only)
6. ✅ orphaned-spec-tags

---

## Open Questions for Joe

Before implementation begins, please answer:

1. **MCP Language Parsers**: Start with TS + Python only, or include Go + Rust from v1.0?
   - **Recommendation**: Start TS + Python (faster initial delivery), add Go/Rust in v1.1

2. **Workflow Timebox Enforcement**: Timer mechanism or honor system?
   - **Recommendation**: Honor system initially (user-tracked), add timer in v1.1

3. **Cleanup --apply Safety**: Require backup first, or just --dry-run default sufficient?
   - **Recommendation**: Just --dry-run default + confirmation prompt is sufficient

4. **Pre-commit Hook**: Auto-install or optional?
   - **Recommendation**: Auto-install but make it lightweight (mark-dirty only, not full trace)

5. **CI Examples**: Include GitHub Actions workflow template?
   - **Recommendation**: Yes - include `.github/workflows/spec-gates.yml` template

---

## Estimated Effort Breakdown

| Phase | Complexity | Hours | Dependencies |
|-------|-----------|-------|--------------|
| 1. Plugin Foundation | Low | 1 | None |
| 2. Workflow Definitions | Medium | 3 | Phase 1 |
| 3. Skills | Medium | 4 | Phases 1, 2 |
| 4. MCP Server | **High** | 12 | Phase 1 |
| 5. Commands | Low | 3 | Phases 1, 3, 4 |
| 6. Scripts | Low | 2 | Phases 1, 4 |
| 7. Templates | Low | 1 | Phase 1 |
| 8. Documentation | Low | 2 | All phases |
| 9. Testing | Medium | 4 | All phases |
| **Total** | | **32 hours** | |

**Critical Path**: Phase 4 (MCP Server) is the bottleneck - most complex component.

---

## Success Criteria

Plugin is ready when:
- ✅ Installs cleanly via `/plugin install`
- ✅ All 11 commands work
- ✅ All 4 Skills invoke correctly
- ✅ MCP server starts and all 6 tools respond
- ✅ Hooks fire on PostToolUse and SessionStart
- ✅ Gates enforce correctly (exit 1 on violations)
- ✅ Docs complete and accurate
- ✅ Tests pass (commands, Skills, MCP, integration)
- ✅ Tested in 2+ real projects

---

## Next Steps

1. **Answer the 5 open questions above**
2. **Confirm approval of overall architecture**
3. **Begin implementation starting with Phase 1**
4. **Iterate phase-by-phase with validation at each step**

---

**For the complete detailed implementation plan for all 9 phases**, please refer to the conversation above where each phase is broken down with:
- Step-by-step instructions (in/do/out/check/risk/needs format)
- Complete code samples
- File contents
- Validation steps

This summary document serves as your quick reference and decision checkpoint before proceeding with the full 32-hour implementation.

**Ready to build, Joe?** 🚀
