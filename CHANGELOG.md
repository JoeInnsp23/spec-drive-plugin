# Changelog

All notable changes to the spec-drive plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned for v0.2
- Existing project initialization with code analysis
- Stack-specific profiles (TypeScript React, Python FastAPI, Go, Rust)
- Interactive stack selection
- Advanced project detection

### Planned for v0.3+
- Workflow commands (/spec-drive:feature, :bugfix, :research)
- Quality gates and constitutional checks
- Documentation drift detection
- AI-optimized indexing and context management

## [0.1.0] - 2025-10-31

### Added
- Initial plugin infrastructure
- `/spec-drive:init` command for project initialization
- Project type detection (initialized, new, existing)
- New project scaffolding with standard folder structure
- 11 documentation templates:
  - SYSTEM-OVERVIEW.md
  - GLOSSARY.md
  - ARCHITECTURE.md
  - COMPONENT-CATALOG.md
  - DATA-FLOWS.md
  - RUNTIME-&-DEPLOYMENT.md
  - OBSERVABILITY.md
  - BUILD-&-RELEASE.md
  - CI-&-QUALITY-GATES.md
  - PRODUCT-BRIEF.md
  - ADR-TEMPLATE.md
- SPEC-TEMPLATE.yaml for specification files
- Configuration system (.spec-drive/config.yaml, state.yaml, index.yaml)
- Generic stack profile with baseline quality gates
- Automatic .gitignore management
- Template variable substitution ({{PROJECT_NAME}}, {{DATE}}, {{STACK}})
- Bash orchestration with Python modules
- Detection logic for project types
- Plugin manifest (plugin.json)
- Marketplace metadata (marketplace.json)
- Complete documentation (README.md)

### Known Limitations
- Existing project initialization is stubbed (coming in v0.2)
- Only generic stack profile available
- No workflow commands yet
- No quality gates enforcement
- No documentation drift detection

### Technical Details
- Plugin follows Claude Code plugin specification
- Uses `!bash` command invocation pattern
- Modular Python scripts for extensibility
- YAML-based configuration
- Executable permissions set on all scripts

### Testing
- ✅ New project initialization
- ✅ Already initialized detection
- ✅ Existing project detection (stub warning)
- ✅ Template variable substitution
- ✅ Config file creation
- ✅ .gitignore updates

### File Structure
```
11 core files:
- .claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- commands/init.md
- scripts/utils.sh
- scripts/init.sh
- scripts/detect-project.py
- scripts/init-new-project.py
- scripts/init-existing-project.py
- templates/config.yaml.template
- templates/SPEC-TEMPLATE.yaml
- stack-profiles/generic.yaml

Plus 11 doc templates in templates/docs/
```

## Version Numbering

- **0.x.x**: Pre-1.0 development versions
- **0.1.x**: Initial infrastructure and new project support
- **0.2.x**: Existing project support and stack profiles
- **0.3.x**: Workflow commands and quality gates
- **1.0.0**: Full MVP with all core features

---

**Changelog Format:**
- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
