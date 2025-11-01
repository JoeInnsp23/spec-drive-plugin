#!/bin/bash
# workflow-status.sh
# Purpose: Display current workflow status
# Usage: ./workflow-status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/workflow-engine.sh"

# Call workflow_status function
workflow_status
