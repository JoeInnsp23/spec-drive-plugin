#!/bin/bash
# generate-docs.sh
# Purpose: Generate initial documentation suite from APP-001 spec
# Usage: ./generate-docs.sh

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
INDEX_FILE="$SPEC_DRIVE_DIR/SPECS-INDEX.yaml"
RENDER_SCRIPT="$PLUGIN_ROOT/scripts/tools/render-template.sh"
TEMPLATES_DIR="$PLUGIN_ROOT/templates/docs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

# Check APP-001 spec exists
if [[ ! -f "$SPECS_DIR/APP-001.yaml" ]]; then
  echo -e "${RED}❌ ERROR: APP-001 spec not found${NC}" >&2
  echo "Run planning-session.sh first" >&2
  exit 1
fi

# Check render-template.sh exists
if [[ ! -x "$RENDER_SCRIPT" ]]; then
  echo -e "${RED}❌ ERROR: render-template.sh not found or not executable${NC}" >&2
  echo "Path: $RENDER_SCRIPT" >&2
  exit 1
fi

# Check templates directory exists
if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo -e "${RED}❌ ERROR: Templates directory not found${NC}" >&2
  echo "Path: $TEMPLATES_DIR" >&2
  exit 1
fi

# ==============================================================================
# Read APP-001 Spec Data
# ==============================================================================

echo -e "${BLUE}Reading APP-001 spec...${NC}"

# Extract data from spec using yq
PROJECT_NAME=$(yq eval '.title' "$SPECS_DIR/APP-001.yaml" | sed 's/ Project$//')
PROJECT_VISION=$(yq eval '.planning.vision' "$SPECS_DIR/APP-001.yaml")
TARGET_USERS=$(yq eval '.planning.target_users' "$SPECS_DIR/APP-001.yaml")
TECH_STACK=$(yq eval '.planning.tech_stack' "$SPECS_DIR/APP-001.yaml")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build features list (convert YAML array to markdown bullets)
KEY_FEATURES=$(yq eval '.planning.key_features[]' "$SPECS_DIR/APP-001.yaml" | sed 's/^/- /')

echo -e "${GREEN}✓${NC} Loaded project data"

# ==============================================================================
# Create docs/ Directory Structure
# ==============================================================================

echo -e "${BLUE}Creating docs/ structure...${NC}"

# Create directories
mkdir -p docs/10-architecture
mkdir -p docs/20-build-release
mkdir -p docs/30-runtime
mkdir -p docs/40-product
mkdir -p docs/50-observability
mkdir -p docs/60-adr

echo -e "${GREEN}✓${NC} Created directory structure"

# ==============================================================================
# Render Documentation Templates
# ==============================================================================

echo -e "${BLUE}Generating documentation...${NC}"

# Common variables for all templates
DATE=$(date -u +%Y-%m-%d)
COMMON_VARS=(
  --var "PROJECT_NAME=$PROJECT_NAME"
  --var "PROJECT_VISION=$PROJECT_VISION"
  --var "KEY_FEATURES=$KEY_FEATURES"
  --var "TARGET_USERS=$TARGET_USERS"
  --var "TECH_STACK=$TECH_STACK"
  --var "VERSION=0.1.0"
  --var "TIMESTAMP=$TIMESTAMP"
  --var "DATE=$DATE"
)

# Template mapping: template_file -> output_file
declare -A DOCS=(
  ["PRODUCT-BRIEF.md.template"]="docs/40-product/PRODUCT-BRIEF.md"
  ["USER-JOURNEYS.md.template"]="docs/40-product/USER-JOURNEYS.md"
  ["SYSTEM-OVERVIEW.md.template"]="docs/10-architecture/SYSTEM-OVERVIEW.md"
  ["ARCHITECTURE.md.template"]="docs/10-architecture/ARCHITECTURE.md"
  ["COMPONENT-CATALOG.md.template"]="docs/10-architecture/COMPONENT-CATALOG.md"
  ["DATA-FLOWS.md.template"]="docs/10-architecture/DATA-FLOWS.md"
  ["BUILD-RELEASE.md.template"]="docs/20-build-release/BUILD-RELEASE.md"
  ["CI-QUALITY-GATES.md.template"]="docs/20-build-release/CI-QUALITY-GATES.md"
  ["RUNTIME-DEPLOYMENT.md.template"]="docs/30-runtime/RUNTIME-DEPLOYMENT.md"
  ["OBSERVABILITY.md.template"]="docs/50-observability/OBSERVABILITY.md"
  ["GLOSSARY.md.template"]="docs/GLOSSARY.md"
)

# Render each template
doc_count=0
for template in "${!DOCS[@]}"; do
  output="${DOCS[$template]}"
  template_path="$TEMPLATES_DIR/$template"

  if [[ ! -f "$template_path" ]]; then
    echo -e "${YELLOW}⚠${NC}  Template not found: $template (skipping)"
    continue
  fi

  if "$RENDER_SCRIPT" \
    --template "$template_path" \
    --output "$output" \
    "${COMMON_VARS[@]}" 2>&1; then
    doc_count=$((doc_count + 1))
    echo -e "  ${GREEN}✓${NC} Generated: $output"
  else
    echo -e "  ${RED}✗${NC} Failed: $output"
  fi
done

# Create ADR template placeholder
cat > "docs/60-adr/ADR-TEMPLATE.md" << 'EOF'
# ADR-XXX: [Title]

**Status:** [Proposed | Accepted | Deprecated | Superseded]
**Date:** YYYY-MM-DD
**Deciders:** [List decision makers]

## Context

[Describe the context and problem statement]

## Decision

[Describe the decision and its rationale]

## Consequences

### Positive
- [List positive outcomes]

### Negative
- [List negative outcomes or trade-offs]

## Alternatives Considered

1. **[Alternative 1]**
   - Pros: ...
   - Cons: ...

## References

- [Related specs, docs, external links]
EOF

doc_count=$((doc_count + 1))
echo -e "  ${GREEN}✓${NC} Created: docs/60-adr/ADR-TEMPLATE.md"

echo -e "${GREEN}✓${NC} Generated $doc_count documents"

# ==============================================================================
# Update SPECS-INDEX with Docs
# ==============================================================================

echo -e "${BLUE}Updating SPECS-INDEX...${NC}"

# Build docs array for index
for output in "${DOCS[@]}"; do
  doc_title=$(basename "$output" .md | sed 's/-/ /g')
  yq eval ".docs += [{\"file\": \"$output\", \"title\": \"$doc_title\", \"updated\": \"$TIMESTAMP\"}]" \
    "$INDEX_FILE" -i
done

# Update metadata
yq eval ".meta.total_docs = (.docs | length) | \
         .updated = \"$TIMESTAMP\"" \
  "$INDEX_FILE" -i

echo -e "${GREEN}✓${NC} Updated SPECS-INDEX"

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo -e "${GREEN}Documentation generation complete!${NC}"
echo "  Generated: $doc_count documents"
echo "  Location: docs/"
echo ""
