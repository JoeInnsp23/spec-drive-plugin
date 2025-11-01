#!/bin/bash
#
# spec-drive initialization script
# Called by: /spec-drive:init command via !bash
#
# This script orchestrates the initialization process

set -e  # Exit on error
set -u  # Exit on undefined variable

# Derive plugin root from script location
# This script is in <plugin-root>/scripts/init.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Export for child processes (Python scripts)
export CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}"

# Source utilities
source "${SCRIPT_DIR}/utils.sh"

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
echo "Next steps:"
echo "  1. Review: .spec-drive/config.yaml"
echo "  2. Check: docs/ structure"
echo "  3. Run: /spec-drive:status"
