#!/usr/bin/env python3
"""
Detect project type: initialized, new, or existing

Outputs one of:
  - initialized: Has .spec-drive/config.yaml
  - new: No code, no packages
  - existing: Has code or package files
"""

import sys
from pathlib import Path
import glob

def file_exists(path):
    """Check if file exists"""
    return Path(path).exists()

def has_files_matching(pattern):
    """Check if any files match glob pattern"""
    return len(glob.glob(pattern, recursive=False)) > 0

def detect_project_type():
    """Detect project type"""

    # Check 1: Already initialized?
    if file_exists('.spec-drive/config.yaml'):
        return 'initialized'

    # Check 2: Has code directories?
    has_code_dirs = any([
        Path('src').is_dir(),
        Path('lib').is_dir(),
        Path('app').is_dir(),
        Path('packages').is_dir(),
    ])

    # Check 3: Has source files?
    has_source_files = any([
        has_files_matching('*.py'),
        has_files_matching('*.ts'),
        has_files_matching('*.tsx'),
        has_files_matching('*.js'),
        has_files_matching('*.jsx'),
        has_files_matching('*.go'),
        has_files_matching('*.rs'),
        has_files_matching('*.java'),
    ])

    # Check 4: Has package manifests?
    has_packages = any([
        file_exists('package.json'),
        file_exists('requirements.txt'),
        file_exists('pyproject.toml'),
        file_exists('Cargo.toml'),
        file_exists('go.mod'),
        file_exists('pom.xml'),
        file_exists('build.gradle'),
        file_exists('composer.json'),
    ])

    # Decision
    if has_code_dirs or has_source_files or has_packages:
        return 'existing'
    else:
        return 'new'

if __name__ == '__main__':
    try:
        project_type = detect_project_type()
        print(project_type)
        sys.exit(0)
    except Exception as e:
        print(f"Error detecting project type: {e}", file=sys.stderr)
        sys.exit(1)
