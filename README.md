# spec-drive Plugin

**Version:** 0.1.0

Spec-driven development system for Claude Code that provides project initialization, standardized documentation templates, and consistent development workflows.

## Overview

spec-drive helps you start new projects or organize existing ones with a consistent, repeatable structure. It creates a standard documentation framework and configuration system that keeps your projects clean and maintainable.

## Features (v0.1)

- **Smart Project Detection:** Automatically detects if project is new, existing, or already initialized
- **Standard Folder Structure:** Creates organized docs/, specs/, and tests/ directories
- **11 Documentation Templates:** Pre-configured templates for architecture, build, API, decisions, and more
- **Configuration Management:** YAML-based config for project settings and stack profiles
- **Generic Stack Profile:** Baseline quality gates and conventions for any project type
- **.gitignore Management:** Automatically configures version control exclusions

## Installation

### Via Private Marketplace

1. **Configure Claude Code settings** (`~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "joe-personal": {
      "type": "github",
      "url": "https://github.com/JoeInnsp23/spec-drive-plugin",
      "private": true
    }
  },
  "enabledPlugins": {
    "spec-drive@joe-personal": true
  }
}
```

2. **Install the plugin:**

```bash
claude /plugin install spec-drive@joe-personal
```

3. **Verify installation:**

```bash
claude /plugin list
```

### Manual Installation

```bash
# Clone to Claude plugins directory
git clone https://github.com/JoeInnsp23/spec-drive-plugin.git ~/.claude/plugins/spec-drive

# Restart Claude Code
```

## Usage

### Initialize a New Project

```bash
# Navigate to your project directory
cd /path/to/my-new-project

# Run initialization
/spec-drive:init
```

**What happens:**
- Detects project type (new, existing, or already initialized)
- Creates standard folder structure:
  - `docs/` - Documentation organized by category
  - `specs/` - Specification files
  - `tests/` - Test files
  - `.spec-drive/` - Configuration and state
- Populates 11 documentation templates with project info
- Creates config files (config.yaml, state.yaml, index.yaml)
- Updates .gitignore

### Initialize an Existing Project

```bash
# Navigate to existing project
cd /path/to/existing-project

# Run initialization
/spec-drive:init
```

**Note:** Full existing project support (code analysis, doc extraction, regeneration) is coming in v0.2. For now, you'll see instructions for manual setup.

### Re-initialization Detection

If you run `/spec-drive:init` on an already initialized project, it will detect this and skip gracefully.

## Documentation Structure

After initialization, your project will have:

```
project/
├── docs/
│   ├── 00-overview/
│   │   ├── SYSTEM-OVERVIEW.md
│   │   └── GLOSSARY.md
│   ├── 10-architecture/
│   │   ├── ARCHITECTURE.md
│   │   ├── COMPONENT-CATALOG.md
│   │   ├── DATA-FLOWS.md
│   │   ├── RUNTIME-&-DEPLOYMENT.md
│   │   └── OBSERVABILITY.md
│   ├── 20-build/
│   │   ├── BUILD-&-RELEASE.md
│   │   └── CI-&-QUALITY-GATES.md
│   ├── 40-api/
│   ├── 50-decisions/
│   │   └── ADR-TEMPLATE.md
│   ├── 60-features/
│   └── PRODUCT-BRIEF.md
├── specs/
│   └── SPEC-TEMPLATE.yaml
├── tests/
└── .spec-drive/
    ├── config.yaml          # Project configuration
    ├── state.yaml          # Workflow state (gitignored)
    └── index.yaml          # AI-optimized index
```

## Configuration

### Project Config (`.spec-drive/config.yaml`)

```yaml
project:
  name: my-project
  description: Project description
  type: new
  initialized: 2025-10-31T10:00:00

stack:
  profile: generic
  languages: []
  frameworks: []
  tools: []

mode:
  enforcement: advisory
  autodocs: true
  traceability: true

workflows:
  active: null
  history: []
```

### Stack Profiles

v0.1 includes a **generic** profile with baseline quality gates. Future versions will add:
- typescript-react
- python-fastapi
- go-standard
- rust-cargo

## Roadmap

### v0.1 (Current)
- ✅ Project initialization (new projects)
- ✅ Standard documentation templates
- ✅ Generic stack profile
- ✅ Basic configuration system

### v0.2 (Planned)
- Existing project initialization (code analysis, doc extraction)
- Stack-specific profiles (TypeScript, Python, Go, Rust)
- Interactive stack selection
- Advanced detection logic

### v0.3+ (Future)
- Workflow commands (feature, bugfix, research)
- Quality gates and constitutional checks
- Documentation drift detection
- AI-optimized indexing

## Commands

### v0.1 Commands

- `/spec-drive:init` - Initialize spec-drive in project (new or existing)

### Future Commands (v0.2+)

- `/spec-drive:status` - Show project health and workflow status
- `/spec-drive:feature` - Start feature development workflow
- `/spec-drive:bugfix` - Start bugfix workflow
- `/spec-drive:research` - Start research workflow

## Architecture

### Components

1. **Slash Commands** (`commands/`)
   - User-facing entry points
   - Use `!bash` to invoke scripts

2. **Scripts** (`scripts/`)
   - Bash orchestrator (init.sh)
   - Python modules (detect, init-new, init-existing)
   - Utility functions (utils.sh)

3. **Templates** (`templates/`)
   - Documentation templates with variable substitution
   - Spec template (YAML)
   - Config template

4. **Stack Profiles** (`stack-profiles/`)
   - Stack-aware quality gates and conventions
   - Generic profile for any project type

### Design Principles

- **Repeatable:** Same structure every time
- **Non-invasive:** Doesn't modify existing code
- **Documentation-first:** Always up-to-date docs
- **Stack-aware:** Adapts to your technology choices
- **Quality-focused:** Built-in gates and best practices

## Development

### File Structure

```
spec-drive-plugin/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace metadata
├── commands/
│   └── init.md                  # /spec-drive:init command
├── scripts/
│   ├── utils.sh                 # Bash utilities
│   ├── init.sh                  # Main orchestrator
│   ├── detect-project.py        # Project type detection
│   ├── init-new-project.py      # New project initialization
│   └── init-existing-project.py # Existing project initialization (stub in v0.1)
├── stack-profiles/
│   └── generic.yaml             # Generic stack profile
├── templates/
│   ├── config.yaml.template     # Config template
│   ├── SPEC-TEMPLATE.yaml       # Spec template
│   └── docs/                    # 11 doc templates
├── README.md                    # This file
├── CHANGELOG.md                 # Version history
├── LICENSE                      # MIT License
└── .gitignore                   # Git exclusions
```

### Testing

Test initialization on different project types:

```bash
# Test new project
mkdir /tmp/test-new && cd /tmp/test-new
CLAUDE_PLUGIN_ROOT=/path/to/spec-drive-plugin ./scripts/init.sh

# Test existing project
mkdir /tmp/test-existing && cd /tmp/test-existing
echo '{"name": "test"}' > package.json
CLAUDE_PLUGIN_ROOT=/path/to/spec-drive-plugin ./scripts/init.sh

# Test already initialized
cd /tmp/test-new
CLAUDE_PLUGIN_ROOT=/path/to/spec-drive-plugin ./scripts/init.sh
```

## Contributing

This is a personal plugin for multi-server deployment. If you have access and want to suggest improvements:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit PR with clear description

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Check the documentation in `docs/` (after initialization)
- Review CHANGELOG.md for recent changes
- File an issue on GitHub

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

**Generated by:** spec-drive v0.1.0
**Last Updated:** 2025-10-31
