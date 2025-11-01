#!/usr/bin/env python3
"""
Initialize new project (Path A)

Steps:
1. Gather project info
2. Detect/select tech stack
3. Scaffold folder structure
4. Populate doc templates
5. Create config files
6. Update .gitignore
"""

import os
import sys
from pathlib import Path
from datetime import datetime
import yaml

PLUGIN_ROOT = os.environ.get('CLAUDE_PLUGIN_ROOT')
if not PLUGIN_ROOT:
    print("Error: CLAUDE_PLUGIN_ROOT environment variable not set", file=sys.stderr)
    sys.exit(1)

TEMPLATES_DIR = Path(PLUGIN_ROOT) / 'templates'

def gather_project_info():
    """Gather basic project information"""
    # For v0.1: Use defaults, no interactive prompts

    cwd = Path.cwd()
    project_name = cwd.name

    return {
        'name': project_name,
        'description': f'{project_name} project',
        'type': 'new',
    }

def detect_stack():
    """Detect or select tech stack"""
    # For v0.1: Default to generic
    # v0.2 will add interactive selection

    return 'generic'

def scaffold_folders():
    """Create folder structure"""

    folders = [
        '.spec-drive',
        'specs',
        'docs/00-overview',
        'docs/10-architecture',
        'docs/20-build',
        'docs/40-api',
        'docs/50-decisions',
        'docs/60-features',
        'tests',
    ]

    for folder in folders:
        Path(folder).mkdir(parents=True, exist_ok=True)
        print(f"✓ Created: {folder}/")

def populate_templates(project_info, stack):
    """Populate doc templates with project info"""

    template_files = [
        ('docs/SYSTEM-OVERVIEW.md.template', 'docs/00-overview/SYSTEM-OVERVIEW.md'),
        ('docs/GLOSSARY.md.template', 'docs/00-overview/GLOSSARY.md'),
        ('docs/ARCHITECTURE.md.template', 'docs/10-architecture/ARCHITECTURE.md'),
        ('docs/COMPONENT-CATALOG.md.template', 'docs/10-architecture/COMPONENT-CATALOG.md'),
        ('docs/DATA-FLOWS.md.template', 'docs/10-architecture/DATA-FLOWS.md'),
        ('docs/RUNTIME-DEPLOYMENT.md.template', 'docs/10-architecture/RUNTIME-&-DEPLOYMENT.md'),
        ('docs/OBSERVABILITY.md.template', 'docs/10-architecture/OBSERVABILITY.md'),
        ('docs/BUILD-RELEASE.md.template', 'docs/20-build/BUILD-&-RELEASE.md'),
        ('docs/CI-QUALITY-GATES.md.template', 'docs/20-build/CI-&-QUALITY-GATES.md'),
        ('docs/PRODUCT-BRIEF.md.template', 'docs/PRODUCT-BRIEF.md'),
        ('docs/ADR-TEMPLATE.md.template', 'docs/50-decisions/ADR-TEMPLATE.md'),
        ('SPEC-TEMPLATE.yaml', 'specs/SPEC-TEMPLATE.yaml'),
    ]

    for template_name, output_path in template_files:
        template_path = TEMPLATES_DIR / template_name

        if not template_path.exists():
            print(f"⚠️  Template not found: {template_name}")
            continue

        # Read template
        template_content = template_path.read_text()

        # Simple variable substitution
        content = template_content.replace('{{PROJECT_NAME}}', project_info['name'])
        content = content.replace('{{PROJECT_DESCRIPTION}}', project_info['description'])
        content = content.replace('{{STACK}}', stack)
        content = content.replace('{{DATE}}', datetime.now().strftime('%Y-%m-%d'))

        # Write output
        Path(output_path).write_text(content)
        print(f"✓ Created: {output_path}")

def create_config(project_info, stack):
    """Create .spec-drive/config.yaml"""

    config = {
        'project': {
            'name': project_info['name'],
            'description': project_info['description'],
            'type': 'new',
            'initialized': datetime.now().isoformat(),
        },
        'stack': {
            'profile': stack,
            'languages': [],
            'frameworks': [],
            'tools': [],
        },
        'mode': {
            'enforcement': 'advisory',
            'autodocs': True,
            'traceability': True,
        },
        'workflows': {
            'active': None,
            'history': [],
        },
    }

    config_path = Path('.spec-drive/config.yaml')
    with open(config_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

    print(f"✓ Created: {config_path}")

def create_state():
    """Create .spec-drive/state.yaml"""

    state = {
        'current_workflow': None,
        'current_stage': None,
        'current_spec': None,
        'workflows': {},
    }

    state_path = Path('.spec-drive/state.yaml')
    with open(state_path, 'w') as f:
        yaml.dump(state, f, default_flow_style=False, sort_keys=False)

    print(f"✓ Created: {state_path}")

def create_index(project_info):
    """Create .spec-drive/index.yaml"""

    index = {
        'meta': {
            'generated': datetime.now().isoformat(),
            'version': '1.0',
            'project': project_info['name'],
        },
        'components': {},
        'specs': {},
        'docs': {},
        'code': {},
    }

    index_path = Path('.spec-drive/index.yaml')
    with open(index_path, 'w') as f:
        yaml.dump(index, f, default_flow_style=False, sort_keys=False)

    print(f"✓ Created: {index_path}")

def create_gitignore_entry():
    """Add .spec-drive/state.yaml to .gitignore"""

    gitignore_path = Path('.gitignore')

    entry = "\n# spec-drive\n.spec-drive/state.yaml\n"

    if gitignore_path.exists():
        content = gitignore_path.read_text()
        if 'spec-drive' not in content:
            with open(gitignore_path, 'a') as f:
                f.write(entry)
            print(f"✓ Updated: .gitignore")
        else:
            print(f"✓ .gitignore already contains spec-drive entry")
    else:
        gitignore_path.write_text(entry)
        print(f"✓ Created: .gitignore")

def create_spec_drive_gitignore():
    """Create .spec-drive/.gitignore"""

    gitignore_path = Path('.spec-drive/.gitignore')
    gitignore_path.write_text('state.yaml\n')
    print(f"✓ Created: {gitignore_path}")

def main():
    """Main initialization for new project"""

    print("🚀 Initializing new project...")
    print("")

    try:
        # 1. Gather info
        project_info = gather_project_info()
        print(f"Project: {project_info['name']}")

        # 2. Detect stack
        stack = detect_stack()
        print(f"Stack: {stack}")
        print("")

        # 3. Scaffold
        print("Creating folder structure...")
        scaffold_folders()
        print("")

        # 4. Templates
        print("Populating templates...")
        populate_templates(project_info, stack)
        print("")

        # 5. Config
        print("Creating configuration...")
        create_config(project_info, stack)
        create_state()
        create_index(project_info)
        print("")

        # 6. .gitignore
        print("Updating .gitignore...")
        create_gitignore_entry()
        create_spec_drive_gitignore()
        print("")

        print("✅ New project initialized!")
        print("")
        print("Next steps:")
        print("  1. Review docs/PRODUCT-BRIEF.md")
        print("  2. Define vision with: /spec-drive:research 'product vision' 30m")
        print("  3. Check status with: /spec-drive:status")

    except Exception as e:
        print(f"❌ Error initializing project: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
