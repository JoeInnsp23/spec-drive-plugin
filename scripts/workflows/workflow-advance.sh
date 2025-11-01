#!/bin/bash
# workflow-advance.sh
# Purpose: Advance workflow to next stage
# Usage: ./workflow-advance.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/workflow-engine.sh"

# Call workflow_advance function
workflow_advance
