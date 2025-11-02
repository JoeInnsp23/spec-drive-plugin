#!/usr/bin/env bash
# init-development.sh
# Purpose: Initialize development workspace for a spec
# Usage: ./init-development.sh <SPEC-ID>

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
DEV_ROOT="$SPEC_DRIVE_DIR/development"
CURRENT_DIR="$DEV_ROOT/current"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Validate Input
# ==============================================================================

if [[ $# -ne 1 ]]; then
  echo -e "${RED}❌ ERROR: SPEC-ID argument required${NC}" >&2
  echo "Usage: $0 <SPEC-ID>" >&2
  exit 1
fi

SPEC_ID="$1"
SPEC_FILE="$SPECS_DIR/$SPEC_ID.yaml"
WORKSPACE="$CURRENT_DIR/$SPEC_ID"

# Validate spec exists
if [[ ! -f "$SPEC_FILE" ]]; then
  echo -e "${RED}❌ ERROR: Spec not found: $SPEC_FILE${NC}" >&2
  exit 1
fi

# ==============================================================================
# Create Workspace Structure
# ==============================================================================

echo -e "${BLUE}Creating development workspace...${NC}"

# Create workspace directory
mkdir -p "$WORKSPACE"

echo -e "${GREEN}✓${NC} Created directory: $WORKSPACE"

# ==============================================================================
# Extract Data from Spec
# ==============================================================================

PROJECT_NAME=$(yq eval '.project.name' "$SPEC_FILE")
PROJECT_VISION=$(yq eval '.project.vision' "$SPEC_FILE")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Count features
FEATURES_COUNT=$(yq eval '.features | length' "$SPEC_FILE" 2>/dev/null || echo "0")

# Count users
USERS_COUNT=$(yq eval '.users | length' "$SPEC_FILE" 2>/dev/null || echo "0")

# Get tech stack
TECH_LANG=$(yq eval '.technical.stack.language' "$SPEC_FILE" 2>/dev/null || echo "")
TECH_FRAMEWORK=$(yq eval '.technical.stack.framework' "$SPEC_FILE" 2>/dev/null || echo "")
TECH_DB=$(yq eval '.technical.stack.database' "$SPEC_FILE" 2>/dev/null || echo "")

# ==============================================================================
# Create CONTEXT.md
# ==============================================================================

echo -e "${BLUE}Creating CONTEXT.md...${NC}"

cat > "$WORKSPACE/CONTEXT.md" << EOF
# Development Context: $PROJECT_NAME

**Spec:** $SPEC_ID
**Created:** $TIMESTAMP
**Status:** Initial setup

---

## Project Overview

**Vision:** $PROJECT_VISION

This workspace tracks development planning, decisions, and tasks for $PROJECT_NAME.

## Purpose of This Workspace

This is an **independent planning space** that can diverge from the spec:
- **Spec** (.spec-drive/specs/$SPEC_ID.yaml) = single source of truth for requirements
- **Workspace** (this directory) = evolving implementation plans, decisions, tasks

### When to Use Each

- **Reference spec** for: user needs, feature requirements, acceptance criteria
- **Update workspace** for: implementation decisions, task breakdown, progress tracking
- **Update spec** when: requirements change, new features discovered, acceptance criteria refined

---

## Quick Reference

- **Total Features:** $FEATURES_COUNT
- **User Types:** $USERS_COUNT
- **Tech Stack:** $TECH_LANG, $TECH_FRAMEWORK, $TECH_DB

For full details, see: .spec-drive/specs/$SPEC_ID.yaml

---

## Development Phases

1. **Discovery** ✓ (Complete)
   - Comprehensive discovery interview conducted
   - Spec generated with all context

2. **Specify** (Next)
   - Refine acceptance criteria
   - Add technical specifications
   - Document edge cases

3. **Implement**
   - Break down features into tasks
   - Implement according to plan
   - Update TASKS.md as you go

4. **Verify**
   - Test against acceptance criteria
   - Verify completeness
   - Document any deviations

---

## Key Decisions

<!-- Document implementation decisions here as they're made -->

*No decisions yet - workspace just initialized*

---

## Open Questions

<!-- Track questions that arise during development -->

EOF

# Add open questions from spec if any
QUESTIONS_COUNT=$(yq eval '.open_questions | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$QUESTIONS_COUNT" != "null" && "$QUESTIONS_COUNT" -gt 0 ]]; then
  echo "### From Discovery" >> "$WORKSPACE/CONTEXT.md"
  echo "" >> "$WORKSPACE/CONTEXT.md"

  for ((i=0; i<QUESTIONS_COUNT; i++)); do
    QUESTION=$(yq eval ".open_questions[$i].question" "$SPEC_FILE")
    Q_CONTEXT=$(yq eval ".open_questions[$i].context" "$SPEC_FILE")
    Q_PRIORITY=$(yq eval ".open_questions[$i].priority" "$SPEC_FILE")

    echo "**[$Q_PRIORITY]** $QUESTION" >> "$WORKSPACE/CONTEXT.md"
    if [[ "$Q_CONTEXT" != "null" && -n "$Q_CONTEXT" ]]; then
      echo "  - Context: $Q_CONTEXT" >> "$WORKSPACE/CONTEXT.md"
    fi
    echo "" >> "$WORKSPACE/CONTEXT.md"
  done
else
  echo "*No open questions from discovery*" >> "$WORKSPACE/CONTEXT.md"
  echo "" >> "$WORKSPACE/CONTEXT.md"
fi

cat >> "$WORKSPACE/CONTEXT.md" << 'EOF'

---

## Notes

<!-- Use this space for quick notes, links, references -->

EOF

echo -e "${GREEN}✓${NC} Created CONTEXT.md"

# ==============================================================================
# Create PLAN.md
# ==============================================================================

echo -e "${BLUE}Creating PLAN.md...${NC}"

cat > "$WORKSPACE/PLAN.md" << EOF
# Implementation Plan: $PROJECT_NAME

**Spec:** $SPEC_ID
**Last Updated:** $TIMESTAMP

---

## Overview

This document tracks the implementation plan for $PROJECT_NAME.

As features are built, update this plan with:
- Technical approach and architecture decisions
- Implementation sequence and dependencies
- Risk mitigations
- Testing strategy

---

## Current Phase: Discovery

**Status:** Complete
**Next:** Refine spec, add acceptance criteria, move to Specify phase

---

## Features Roadmap

EOF

# Add features from spec
if [[ "$FEATURES_COUNT" != "null" && "$FEATURES_COUNT" -gt 0 ]]; then
  echo "### Prioritized Features" >> "$WORKSPACE/PLAN.md"
  echo "" >> "$WORKSPACE/PLAN.md"

  # Group by priority
  for priority in "critical" "high" "medium" "nice-to-have"; do
    HAS_PRIORITY=false

    for ((i=0; i<FEATURES_COUNT; i++)); do
      FEAT_PRIORITY=$(yq eval ".features[$i].priority" "$SPEC_FILE")

      if [[ "$FEAT_PRIORITY" == "$priority" ]]; then
        if [[ "$HAS_PRIORITY" == false ]]; then
          echo "#### ${priority^} Priority" >> "$WORKSPACE/PLAN.md"
          echo "" >> "$WORKSPACE/PLAN.md"
          HAS_PRIORITY=true
        fi

        FEAT_TITLE=$(yq eval ".features[$i].title" "$SPEC_FILE")
        FEAT_COMPLEXITY=$(yq eval ".features[$i].complexity" "$SPEC_FILE")

        echo "- **$FEAT_TITLE** ($FEAT_COMPLEXITY complexity)" >> "$WORKSPACE/PLAN.md"
        echo "  - Status: Not started" >> "$WORKSPACE/PLAN.md"
        echo "  - Details: See .features[$i] in spec" >> "$WORKSPACE/PLAN.md"
        echo "" >> "$WORKSPACE/PLAN.md"
      fi
    done
  done
else
  echo "*No features defined yet*" >> "$WORKSPACE/PLAN.md"
  echo "" >> "$WORKSPACE/PLAN.md"
fi

cat >> "$WORKSPACE/PLAN.md" << 'EOF'

---

## Technical Approach

### Architecture

<!-- Describe high-level architecture decisions -->

*To be determined during Specify phase*

### Tech Stack

EOF

echo "- **Language:** $TECH_LANG" >> "$WORKSPACE/PLAN.md"
echo "- **Framework:** $TECH_FRAMEWORK" >> "$WORKSPACE/PLAN.md"
echo "- **Database:** $TECH_DB" >> "$WORKSPACE/PLAN.md"
echo "" >> "$WORKSPACE/PLAN.md"

cat >> "$WORKSPACE/PLAN.md" << 'EOF'

For full technical context, see: .technical in spec

### Key Design Decisions

<!-- Document architecture/design decisions here -->

*No decisions yet*

---

## Testing Strategy

<!-- Define testing approach -->

*To be determined during implementation*

---

## Deployment Plan

<!-- Describe deployment approach -->

*To be determined*

---

## Risks & Mitigations

EOF

# Add risks from spec
RISKS_COUNT=$(yq eval '.risks | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$RISKS_COUNT" != "null" && "$RISKS_COUNT" -gt 0 ]]; then
  for ((i=0; i<RISKS_COUNT; i++)); do
    RISK_TYPE=$(yq eval ".risks[$i].type" "$SPEC_FILE")
    RISK_DESC=$(yq eval ".risks[$i].description" "$SPEC_FILE")
    RISK_IMPACT=$(yq eval ".risks[$i].impact" "$SPEC_FILE")
    RISK_LIKELIHOOD=$(yq eval ".risks[$i].likelihood" "$SPEC_FILE")
    RISK_MITIGATION=$(yq eval ".risks[$i].mitigation" "$SPEC_FILE")

    echo "### ${RISK_TYPE^} Risk: $RISK_DESC" >> "$WORKSPACE/PLAN.md"
    echo "" >> "$WORKSPACE/PLAN.md"
    echo "- **Impact:** $RISK_IMPACT" >> "$WORKSPACE/PLAN.md"
    echo "- **Likelihood:** $RISK_LIKELIHOOD" >> "$WORKSPACE/PLAN.md"
    echo "- **Mitigation:** $RISK_MITIGATION" >> "$WORKSPACE/PLAN.md"
    echo "" >> "$WORKSPACE/PLAN.md"
  done
else
  echo "*No risks identified*" >> "$WORKSPACE/PLAN.md"
  echo "" >> "$WORKSPACE/PLAN.md"
fi

cat >> "$WORKSPACE/PLAN.md" << 'EOF'

---

## Next Steps

1. Review and refine spec acceptance criteria
2. Resolve open questions from discovery
3. Break down MVP features into tasks
4. Advance workflow to Specify phase

EOF

echo -e "${GREEN}✓${NC} Created PLAN.md"

# ==============================================================================
# Create TASKS.md
# ==============================================================================

echo -e "${BLUE}Creating TASKS.md...${NC}"

cat > "$WORKSPACE/TASKS.md" << EOF
# Tasks: $PROJECT_NAME

**Spec:** $SPEC_ID
**Last Updated:** $TIMESTAMP

---

## Current Tasks

### Discovery Phase ✓

- [x] Conduct comprehensive discovery interview
- [x] Generate $SPEC_ID spec
- [x] Initialize development workspace
- [x] Create AI-navigable index

### Specify Phase (Next)

- [ ] Review spec for completeness
- [ ] Add/refine acceptance criteria for each feature
- [ ] Resolve open questions from discovery
- [ ] Document technical specifications
- [ ] Identify edge cases and error scenarios
- [ ] Define test scenarios

### Implement Phase (Future)

*Tasks will be added during Specify phase*

### Verify Phase (Future)

*Tasks will be added during Implementation*

---

## Backlog

<!-- Add future tasks, ideas, enhancements here -->

*Empty*

---

## Completed Tasks

### $TIMESTAMP - Discovery Complete

- Comprehensive discovery interview conducted
- APP-001 spec generated with:
  - $USERS_COUNT user types
  - $FEATURES_COUNT features
  - Technical context and stack
  - Constraints and risks
  - Success criteria
- Development workspace initialized

EOF

echo -e "${GREEN}✓${NC} Created TASKS.md"

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}✅ Development workspace initialized: $WORKSPACE${NC}"
echo ""
echo "Created files:"
echo "  • CONTEXT.md - Development context and decisions"
echo "  • PLAN.md - Implementation plan and roadmap"
echo "  • TASKS.md - Task tracking"
echo ""

exit 0
