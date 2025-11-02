#!/usr/bin/env bash
# update-index.sh
# Purpose: Create/update AI-navigable index for project navigation
# Usage: ./update-index.sh <SPEC-ID>

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
INDEX_FILE="$SPEC_DRIVE_DIR/index.yaml"

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

# Validate spec exists
if [[ ! -f "$SPEC_FILE" ]]; then
  echo -e "${RED}❌ ERROR: Spec not found: $SPEC_FILE${NC}" >&2
  exit 1
fi

# ==============================================================================
# Build AI-Navigable Index
# ==============================================================================

echo -e "${BLUE}Building AI-navigable index...${NC}"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Create temp index file
TEMP_INDEX=$(mktemp)
trap "rm -f $TEMP_INDEX" EXIT

# Initialize index structure
yq eval -n ".meta.created = \"$TIMESTAMP\" | \
  .meta.updated = \"$TIMESTAMP\" | \
  .meta.purpose = \"AI-navigable project index for Claude to reference\" | \
  .meta.version = \"1.0\"" > "$TEMP_INDEX"

# Extract project data from spec
PROJECT_NAME=$(yq eval '.project.name' "$SPEC_FILE")
PROJECT_VISION=$(yq eval '.project.vision' "$SPEC_FILE")
SPEC_STATUS=$(yq eval '.status' "$SPEC_FILE")

# Add project overview
PROJECT_NAME="$PROJECT_NAME" PROJECT_VISION="$PROJECT_VISION" SPEC_ID="$SPEC_ID" SPEC_STATUS="$SPEC_STATUS" \
  yq eval -i ".project.name = env(PROJECT_NAME) | \
  .project.vision = env(PROJECT_VISION) | \
  .project.primary_spec = env(SPEC_ID) | \
  .project.status = env(SPEC_STATUS)" "$TEMP_INDEX"

echo -e "${GREEN}✓${NC} Added project overview"

# ==============================================================================
# Entry Points - Key Navigation Points for AI
# ==============================================================================

echo -e "${BLUE}Creating entry points...${NC}"

# Entry point: Specs
yq eval -i ".entry_points.specs.description = \"Project specifications and feature specs\" | \
  .entry_points.specs.location = \"$SPECS_DIR\" | \
  .entry_points.specs.primary = \"$SPEC_FILE\"" "$TEMP_INDEX"

# Count and index specs
SPEC_COUNT=0
if [[ -d "$SPECS_DIR" ]]; then
  for spec in "$SPECS_DIR"/*.yaml; do
    if [[ -f "$spec" ]]; then
      SPEC_NAME=$(basename "$spec")
      SPEC_TITLE=$(yq eval '.title' "$spec" 2>/dev/null || echo "$SPEC_NAME")
      SPEC_TYPE=$(yq eval '.type' "$spec" 2>/dev/null || echo "unknown")

      spec="$spec" SPEC_TITLE="$SPEC_TITLE" SPEC_TYPE="$SPEC_TYPE" SPEC_COUNT="$SPEC_COUNT" \
        yq eval -i ".entry_points.specs.index[env(SPEC_COUNT)].file = env(spec) | \
        .entry_points.specs.index[env(SPEC_COUNT)].title = env(SPEC_TITLE) | \
        .entry_points.specs.index[env(SPEC_COUNT)].type = env(SPEC_TYPE)" "$TEMP_INDEX"

      SPEC_COUNT=$((SPEC_COUNT + 1))
    fi
  done
fi

echo -e "${GREEN}✓${NC} Indexed $SPEC_COUNT specs"

# Entry point: Users
USERS_COUNT=$(yq eval '.users | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$USERS_COUNT" != "null" && "$USERS_COUNT" -gt 0 ]]; then
  yq eval -i ".entry_points.users.description = \"User types, personas, goals, and needs\" | \
    .entry_points.users.location = \"$SPEC_FILE\" | \
    .entry_points.users.path = \".users\" | \
    .entry_points.users.count = $USERS_COUNT" "$TEMP_INDEX"

  # Index each user type
  for ((i=0; i<USERS_COUNT; i++)); do
    USER_TYPE=$(yq eval ".users[$i].type" "$SPEC_FILE")
    USER_ROLE=$(yq eval ".users[$i].role_context" "$SPEC_FILE")

    USER_TYPE="$USER_TYPE" USER_ROLE="$USER_ROLE" yq eval -i \
      ".entry_points.users.index[$i].type = env(USER_TYPE) | \
      .entry_points.users.index[$i].role = env(USER_ROLE) | \
      .entry_points.users.index[$i].path = \".users[$i]\"" "$TEMP_INDEX"
  done

  echo -e "${GREEN}✓${NC} Indexed $USERS_COUNT user types"
fi

# Entry point: Features
FEATURES_COUNT=$(yq eval '.features | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$FEATURES_COUNT" != "null" && "$FEATURES_COUNT" -gt 0 ]]; then
  yq eval -i ".entry_points.features.description = \"Features, priorities, and implementation details\" | \
    .entry_points.features.location = \"$SPEC_FILE\" | \
    .entry_points.features.path = \".features\" | \
    .entry_points.features.count = $FEATURES_COUNT" "$TEMP_INDEX"

  # Index each feature
  for ((i=0; i<FEATURES_COUNT; i++)); do
    FEATURE_TITLE=$(yq eval ".features[$i].title" "$SPEC_FILE")
    FEATURE_PRIORITY=$(yq eval ".features[$i].priority" "$SPEC_FILE")
    FEATURE_COMPLEXITY=$(yq eval ".features[$i].complexity" "$SPEC_FILE")

    FEATURE_TITLE="$FEATURE_TITLE" FEATURE_PRIORITY="$FEATURE_PRIORITY" FEATURE_COMPLEXITY="$FEATURE_COMPLEXITY" \
      yq eval -i ".entry_points.features.index[$i].title = env(FEATURE_TITLE) | \
      .entry_points.features.index[$i].priority = env(FEATURE_PRIORITY) | \
      .entry_points.features.index[$i].complexity = env(FEATURE_COMPLEXITY) | \
      .entry_points.features.index[$i].path = \".features[$i]\"" "$TEMP_INDEX"
  done

  echo -e "${GREEN}✓${NC} Indexed $FEATURES_COUNT features"
fi

# Entry point: Technical
TECH_EXISTS=$(yq eval '.technical' "$SPEC_FILE" 2>/dev/null || echo "null")
if [[ "$TECH_EXISTS" != "null" ]]; then
  TECH_STACK=$(yq eval '.technical.stack.language' "$SPEC_FILE" 2>/dev/null || echo "")
  TECH_FRAMEWORK=$(yq eval '.technical.stack.framework' "$SPEC_FILE" 2>/dev/null || echo "")
  TECH_DB=$(yq eval '.technical.stack.database' "$SPEC_FILE" 2>/dev/null || echo "")
  ARCH_STYLE=$(yq eval '.technical.architecture.style' "$SPEC_FILE" 2>/dev/null || echo "")

  SPEC_FILE="$SPEC_FILE" TECH_STACK="$TECH_STACK" TECH_FRAMEWORK="$TECH_FRAMEWORK" TECH_DB="$TECH_DB" ARCH_STYLE="$ARCH_STYLE" \
    yq eval -i ".entry_points.technical.description = \"Tech stack, architecture, infrastructure\" | \
    .entry_points.technical.location = env(SPEC_FILE) | \
    .entry_points.technical.path = \".technical\" | \
    .entry_points.technical.stack.language = env(TECH_STACK) | \
    .entry_points.technical.stack.framework = env(TECH_FRAMEWORK) | \
    .entry_points.technical.stack.database = env(TECH_DB) | \
    .entry_points.technical.architecture = env(ARCH_STYLE)" "$TEMP_INDEX"

  echo -e "${GREEN}✓${NC} Indexed technical details"
fi

# Entry point: Risks
RISKS_COUNT=$(yq eval '.risks | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$RISKS_COUNT" != "null" && "$RISKS_COUNT" -gt 0 ]]; then
  yq eval -i ".entry_points.risks.description = \"Identified risks and mitigations\" | \
    .entry_points.risks.location = \"$SPEC_FILE\" | \
    .entry_points.risks.path = \".risks\" | \
    .entry_points.risks.count = $RISKS_COUNT" "$TEMP_INDEX"

  # Index high-priority risks
  for ((i=0; i<RISKS_COUNT; i++)); do
    RISK_TYPE=$(yq eval ".risks[$i].type" "$SPEC_FILE")
    RISK_IMPACT=$(yq eval ".risks[$i].impact" "$SPEC_FILE")
    RISK_LIKELIHOOD=$(yq eval ".risks[$i].likelihood" "$SPEC_FILE")

    RISK_TYPE="$RISK_TYPE" RISK_IMPACT="$RISK_IMPACT" RISK_LIKELIHOOD="$RISK_LIKELIHOOD" \
      yq eval -i ".entry_points.risks.index[$i].type = env(RISK_TYPE) | \
      .entry_points.risks.index[$i].impact = env(RISK_IMPACT) | \
      .entry_points.risks.index[$i].likelihood = env(RISK_LIKELIHOOD) | \
      .entry_points.risks.index[$i].path = \".risks[$i]\"" "$TEMP_INDEX"
  done

  echo -e "${GREEN}✓${NC} Indexed $RISKS_COUNT risks"
fi

# Entry point: Open Questions
QUESTIONS_COUNT=$(yq eval '.open_questions | length' "$SPEC_FILE" 2>/dev/null || echo "0")
if [[ "$QUESTIONS_COUNT" != "null" && "$QUESTIONS_COUNT" -gt 0 ]]; then
  yq eval -i ".entry_points.open_questions.description = \"Unresolved questions requiring decisions\" | \
    .entry_points.open_questions.location = \"$SPEC_FILE\" | \
    .entry_points.open_questions.path = \".open_questions\" | \
    .entry_points.open_questions.count = $QUESTIONS_COUNT" "$TEMP_INDEX"

  # Index questions by priority
  for ((i=0; i<QUESTIONS_COUNT; i++)); do
    QUESTION=$(yq eval ".open_questions[$i].question" "$SPEC_FILE")
    Q_PRIORITY=$(yq eval ".open_questions[$i].priority" "$SPEC_FILE")

    QUESTION="$QUESTION" Q_PRIORITY="$Q_PRIORITY" \
      yq eval -i ".entry_points.open_questions.index[$i].question = env(QUESTION) | \
      .entry_points.open_questions.index[$i].priority = env(Q_PRIORITY) | \
      .entry_points.open_questions.index[$i].path = \".open_questions[$i]\"" "$TEMP_INDEX"
  done

  echo -e "${GREEN}✓${NC} Indexed $QUESTIONS_COUNT open questions"
fi

# Entry point: Development workspace
DEV_WORKSPACE="$SPEC_DRIVE_DIR/development/current/$SPEC_ID"
if [[ -d "$DEV_WORKSPACE" ]]; then
  yq eval -i ".entry_points.development.description = \"Current development planning and tasks\" | \
    .entry_points.development.location = \"$DEV_WORKSPACE\" | \
    .entry_points.development.spec = \"$SPEC_ID\"" "$TEMP_INDEX"

  # Index workspace files if they exist
  WORKSPACE_FILES=()
  if [[ -f "$DEV_WORKSPACE/CONTEXT.md" ]]; then
    yq eval -i ".entry_points.development.files[0] = \"$DEV_WORKSPACE/CONTEXT.md\"" "$TEMP_INDEX"
  fi
  if [[ -f "$DEV_WORKSPACE/PLAN.md" ]]; then
    yq eval -i ".entry_points.development.files[1] = \"$DEV_WORKSPACE/PLAN.md\"" "$TEMP_INDEX"
  fi
  if [[ -f "$DEV_WORKSPACE/TASKS.md" ]]; then
    yq eval -i ".entry_points.development.files[2] = \"$DEV_WORKSPACE/TASKS.md\"" "$TEMP_INDEX"
  fi

  echo -e "${GREEN}✓${NC} Indexed development workspace"
fi

echo -e "${GREEN}✓${NC} Entry points created"

# ==============================================================================
# Quick Reference - Common AI Queries
# ==============================================================================

echo -e "${BLUE}Creating quick reference...${NC}"

# Add quick reference entries one by one to avoid line continuation issues
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["What is this project?"] = "See: .project.vision in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["Who are the users?"] = "See: .users[] in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["What features?"] = "See: .features[] in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["What tech stack?"] = "See: .technical.stack in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["What are the risks?"] = "See: .risks[] in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["What'"'"'s the MVP?"] = "See: .success.mvp_scope in " + env(SPEC_FILE)' "$TEMP_INDEX"
SPEC_FILE="$SPEC_FILE" yq eval -i '.quick_reference["Any open questions?"] = "See: .open_questions[] in " + env(SPEC_FILE)' "$TEMP_INDEX"

echo -e "${GREEN}✓${NC} Quick reference created"

# ==============================================================================
# Navigation Hints for AI
# ==============================================================================

yq eval -i ".navigation_hints.how_to_read = \"Use entry_points to find key sections, then read full details from referenced files\" | \
  .navigation_hints.spec_format = \"YAML specs contain comprehensive project/feature context\" | \
  .navigation_hints.development_format = \"Markdown files in development/ workspace for planning/tasks\" | \
  .navigation_hints.updating = \"Specs are single source of truth; development docs can diverge for planning\"" "$TEMP_INDEX"

# ==============================================================================
# Write to Final Location
# ==============================================================================

# Atomic write
mv "$TEMP_INDEX" "$INDEX_FILE" || {
  echo -e "${RED}❌ ERROR: Cannot write index file: $INDEX_FILE${NC}" >&2
  exit 1
}

echo -e "${GREEN}✅ Created AI-navigable index: $INDEX_FILE${NC}"
exit 0
