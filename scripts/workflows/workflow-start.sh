#!/bin/bash
# workflow-start.sh
# Purpose: Start a new workflow
# Usage: ./workflow-start.sh --workflow <type> --spec <SPEC-ID>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/workflow-engine.sh"

# Parse arguments
WORKFLOW_TYPE=""
SPEC_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --workflow)
      WORKFLOW_TYPE="$2"
      shift 2
      ;;
    --spec)
      SPEC_ID="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 --workflow <app-new|feature> --spec <SPEC-ID>"
      echo ""
      echo "Example:"
      echo "  $0 --workflow feature --spec AUTH-001"
      exit 0
      ;;
    *)
      echo "❌ ERROR: Unknown argument: $1" >&2
      echo "Run with --help for usage" >&2
      exit 1
      ;;
  esac
done

# Validate arguments
if [[ -z "$WORKFLOW_TYPE" ]] || [[ -z "$SPEC_ID" ]]; then
  echo "❌ ERROR: --workflow and --spec are required" >&2
  echo "Run with --help for usage" >&2
  exit 1
fi

# Call workflow_start function
workflow_start "$WORKFLOW_TYPE" "$SPEC_ID"
