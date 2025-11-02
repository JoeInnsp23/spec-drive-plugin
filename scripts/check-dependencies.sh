#!/bin/bash
# check-dependencies.sh
# Validate required dependencies for spec-drive workflows

set -eo pipefail

MISSING_DEPS=()
WARNINGS=()

# Check for required tools
check_command() {
  local cmd="$1"
  local install_hint="$2"
  
  if ! command -v "$cmd" &>/dev/null; then
    MISSING_DEPS+=("$cmd: $install_hint")
    return 1
  fi
  return 0
}

# Required dependencies
check_command "python3" "Install Python 3: https://www.python.org/downloads/ or 'brew install python3'"
check_command "yq" "Install yq: 'brew install yq' (macOS) or see https://github.com/mikefarah/yq"

# Optional but recommended
if ! check_command "git" "Install Git: https://git-scm.com/downloads"; then
  WARNINGS+=("git: Recommended for version control")
fi

# Report results
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
  echo "❌ Missing required dependencies:" >&2
  for dep in "${MISSING_DEPS[@]}"; do
    echo "  - $dep" >&2
  done
  echo "" >&2
  exit 1
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo "⚠️  Optional dependencies not found:"
  for warn in "${WARNINGS[@]}"; do
    echo "  - $warn"
  done
  echo ""
fi

echo "✅ All required dependencies found"
exit 0
