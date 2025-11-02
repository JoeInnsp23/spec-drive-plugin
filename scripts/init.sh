#!/bin/bash
#
# spec-drive initialization script
# Called by: /spec-drive:init command via !bash
#
# This script orchestrates the initialization process
#
# Usage: init.sh [--setup-alias]

set -e  # Exit on error
set -u  # Exit on undefined variable

# Parse arguments
SETUP_ALIAS="no"
if [[ "${1:-}" == "--setup-alias" ]]; then
  SETUP_ALIAS="yes"
  shift || true
fi

# Derive plugin root from script location
# This script is in <plugin-root>/scripts/init.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Export for child processes (Python scripts)
export CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}"

# Source utilities
source "${SCRIPT_DIR}/utils.sh"

# Setup strict-concise alias
setup_strict_concise_alias() {
  local BEHAVIOR_FILE="${HOME}/.claude/strict-concise-behavior.md"
  local CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
  local SOURCE_FILE="${PLUGIN_ROOT}/assets/strict-concise-behavior.md"

  echo ""
  log_info "Setting up strict-concise behavior..."

  # 1. Copy behavior file to ~/.claude/
  if [[ -f "${SOURCE_FILE}" ]]; then
    mkdir -p "${HOME}/.claude"
    cp "${SOURCE_FILE}" "${BEHAVIOR_FILE}"
    log_success "✓ Copied strict-concise-behavior.md to ~/.claude/"
  else
    log_warning "⚠️  Source file not found: ${SOURCE_FILE}"
    return 1
  fi

  # 2. Skip CLAUDE.md if exists (leave untouched per requirement)
  if [[ -f "${CLAUDE_MD}" ]]; then
    log_info "✓ CLAUDE.md exists (leaving untouched)"
  fi

  # 3. Detect shell and rc file
  local SHELL_NAME=$(basename "${SHELL}")
  local RC_FILE=""

  case "${SHELL_NAME}" in
    bash)
      RC_FILE="${HOME}/.bashrc"
      ;;
    zsh)
      RC_FILE="${HOME}/.zshrc"
      ;;
    *)
      log_warning "⚠️  Unknown shell: ${SHELL_NAME}, skipping alias setup"
      return 0
      ;;
  esac

  # 4. Check current alias
  local EXPECTED_ALIAS="alias claude-sc='claude --append-system-prompt \"\$(cat ${BEHAVIOR_FILE})\"'"
  local CURRENT_ALIAS=""

  if [[ -f "${RC_FILE}" ]]; then
    CURRENT_ALIAS=$(grep "^alias claude-sc=" "${RC_FILE}" 2>/dev/null || echo "")
  fi

  # 5. Add alias if requested and missing
  if [[ -z "${CURRENT_ALIAS}" ]]; then
    # Alias doesn't exist
    if [[ "${SETUP_ALIAS}" == "yes" ]]; then
      echo "" >> "${RC_FILE}"
      echo "# spec-drive: claude-sc alias for strict-concise behavior" >> "${RC_FILE}"
      echo "${EXPECTED_ALIAS}" >> "${RC_FILE}"
      log_success "✓ Added claude-sc alias to ${RC_FILE}"
      log_info "  Run: source ${RC_FILE}  # to activate"
    else
      log_info "✓ Alias setup skipped (not requested)"
    fi
  else
    # Alias exists - respect user's existing setup
    log_success "✓ claude-sc alias already configured"
  fi
}

# Banner
echo "======================================"
echo "spec-drive initialization"
echo "======================================"
echo ""

# Detect project type
echo "🔍 Detecting project type..."
PROJECT_TYPE=$(python3 "${SCRIPT_DIR}/detect-project.py")

log_info "Project type: ${PROJECT_TYPE}"
echo ""

# Route to appropriate path
case "${PROJECT_TYPE}" in
  initialized)
    log_success "Project already initialized!"
    echo ""
    echo "Configuration: .spec-drive/config.yaml"
    echo "Run: /spec-drive:status"
    exit 0
    ;;

  new)
    log_info "New project detected"
    echo ""
    python3 "${SCRIPT_DIR}/init-new-project.py"
    ;;

  existing)
    log_info "Existing project detected"
    echo ""
    python3 "${SCRIPT_DIR}/init-existing-project.py"
    ;;

  *)
    log_error "Unknown project type: ${PROJECT_TYPE}"
    exit 1
    ;;
esac

echo ""
log_success "Initialization complete!"
echo ""
echo "📁 Directory structure created:"
echo "  .spec-drive/          # Configuration, state, specs, and planning"
echo "    ├── development/    # Workflow planning (current/planned/completed/archive)"
echo "    ├── templates/      # Planning templates (PRD, TDD, tasks, etc.)"
echo "    └── specs/          # Spec YAML files"
echo "  docs/                 # Documentation (11 templates)"
echo ""

# Setup strict-concise alias (non-blocking)
setup_strict_concise_alias || log_warning "⚠️  Strict-concise setup had issues (non-fatal)"

echo ""
echo "Next steps:"
echo "  1. Review: .spec-drive/config.yaml"
echo "  2. Check: docs/ structure"
echo "  3. Run: /spec-drive:status"
