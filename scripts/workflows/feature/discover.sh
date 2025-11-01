#!/bin/bash
# discover.sh
# Purpose: Discover stage - requirements gathering and spec creation
# Usage: ./discover.sh <feature-title>

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
INDEX_FILE="$SPEC_DRIVE_DIR/SPECS-INDEX.yaml"
STATE_FILE="$SPEC_DRIVE_DIR/state.yaml"

# Source workflow engine
source "$SCRIPT_DIR/../workflow-engine.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Arguments
FEATURE_TITLE="${1:-}"

if [[ -z "$FEATURE_TITLE" ]]; then
  echo -e "${RED}❌ ERROR: Feature title is required${NC}" >&2
  echo "Usage: $0 <feature-title>" >&2
  exit 1
fi

# ==============================================================================
# Generate Unique SPEC-ID
# ==============================================================================

generate_spec_id() {
  local title="$1"

  # Extract prefix from title (first word, uppercase)
  local prefix=$(echo "$title" | awk '{print toupper($1)}' | sed 's/[^A-Z]//g')

  # If prefix is empty or too short, use "FEAT"
  if [[ -z "$prefix" ]] || [[ ${#prefix} -lt 2 ]]; then
    prefix="FEAT"
  fi

  # Find highest existing number for this prefix
  local max_num=0
  if [[ -f "$INDEX_FILE" ]]; then
    while IFS= read -r spec_id; do
      if [[ "$spec_id" =~ ^${prefix}-([0-9]+)$ ]]; then
        local num="${BASH_REMATCH[1]}"
        if [[ $num -gt $max_num ]]; then
          max_num=$num
        fi
      fi
    done < <(yq eval '.specs[].spec_id' "$INDEX_FILE" 2>/dev/null || true)
  fi

  # Generate next number
  local next_num=$((max_num + 1))
  printf "%s-%03d" "$prefix" "$next_num"
}

echo -e "${BLUE}Generating SPEC-ID...${NC}"

SPEC_ID=$(generate_spec_id "$FEATURE_TITLE")

echo -e "${GREEN}✓${NC} SPEC-ID: $SPEC_ID"
echo ""

# ==============================================================================
# Prompt for Feature Details
# ==============================================================================

echo -e "${YELLOW}Feature: $FEATURE_TITLE${NC}"
echo ""

# Description
echo -e "${YELLOW}Describe this feature in detail:${NC}"
read -p "→ " DESCRIPTION

if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION="$FEATURE_TITLE"
fi

echo ""

# Priority
echo -e "${YELLOW}Priority [low/medium/high/critical]:${NC}"
read -p "→ " PRIORITY
PRIORITY="${PRIORITY:-medium}"

if [[ ! "$PRIORITY" =~ ^(low|medium|high|critical)$ ]]; then
  echo -e "${YELLOW}⚠${NC}  Invalid priority, using 'medium'"
  PRIORITY="medium"
fi

echo ""

# ==============================================================================
# Create Spec YAML
# ==============================================================================

echo -e "${BLUE}Creating spec file...${NC}"

mkdir -p "$SPECS_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > "$SPECS_DIR/$SPEC_ID.yaml" << EOF
# $SPEC_ID: $FEATURE_TITLE
# Created: $TIMESTAMP

spec_id: $SPEC_ID
title: "$FEATURE_TITLE"
type: feature
status: draft
priority: $PRIORITY
created: $TIMESTAMP
updated: $TIMESTAMP

description: |
  $DESCRIPTION

acceptance_criteria: []

dependencies: []

related_specs: []

traces:
  code: []
  tests: []
  docs: []

notes: |
  Created via /spec-drive:feature workflow.

  Next steps:
  - Add acceptance criteria
  - Define success metrics
  - Advance to specify stage
EOF

echo -e "${GREEN}✓${NC} Created: $SPECS_DIR/$SPEC_ID.yaml"

# ==============================================================================
# Update SPECS-INDEX
# ==============================================================================

echo -e "${BLUE}Updating SPECS-INDEX...${NC}"

if [[ ! -f "$INDEX_FILE" ]]; then
  cat > "$INDEX_FILE" << EOF
version: "0.1"
updated: $TIMESTAMP
specs: []
docs: []
meta:
  total_specs: 0
  total_docs: 0
EOF
fi

# Add spec to index
yq eval ".updated = \"$TIMESTAMP\" | \
         .specs += [{\"spec_id\": \"$SPEC_ID\", \"title\": \"$FEATURE_TITLE\", \"type\": \"feature\", \"status\": \"draft\", \"file\": \"specs/$SPEC_ID.yaml\", \"created\": \"$TIMESTAMP\"}] | \
         .meta.total_specs = (.specs | length)" \
  "$INDEX_FILE" -i

echo -e "${GREEN}✓${NC} Updated SPECS-INDEX"

# ==============================================================================
# Initialize Workflow State
# ==============================================================================

echo -e "${BLUE}Initializing workflow...${NC}"

# Start workflow
workflow_start "feature" "$SPEC_ID" >/dev/null 2>&1

echo -e "${GREEN}✓${NC} Workflow initialized"

# ==============================================================================
# Run Quality Gate 1 (Discover)
# ==============================================================================

echo ""
echo -e "${BLUE}Running Quality Gate 1 (Discover)...${NC}"
echo ""

GATE_SCRIPT="$SCRIPT_DIR/../../gates/gate-1-discover.sh"

if [[ -x "$GATE_SCRIPT" ]]; then
  if "$GATE_SCRIPT"; then
    echo ""
    echo -e "${GREEN}✓ Quality Gate 1 PASSED${NC}"
  else
    echo ""
    echo -e "${RED}✗ Quality Gate 1 FAILED${NC}"
    echo "Fix the issues above before advancing"
    exit 1
  fi
else
  # Fallback if gate script not found
  echo -e "${YELLOW}⚠${NC}  Gate script not found, setting can_advance manually"
  acquire_lock
  yq eval ".can_advance = true" "$STATE_FILE" -i
  release_lock
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}Discover stage complete!${NC}"
echo ""
echo -e "${BLUE}Created:${NC}"
echo "  • Spec: $SPEC_ID ($FEATURE_TITLE)"
echo "  • File: $SPECS_DIR/$SPEC_ID.yaml"
echo "  • Status: draft"
echo "  • Priority: $PRIORITY"
echo ""
echo -e "${YELLOW}Next: Add acceptance criteria to the spec${NC}"
echo "  Then run: /spec-drive:feature advance"
echo ""
