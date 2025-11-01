#!/bin/bash
# workflow-complete.sh
# Purpose: Mark workflow complete
# Usage: ./workflow-complete.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/workflow-engine.sh"

# Call workflow_complete function
workflow_complete
