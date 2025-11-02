#!/usr/bin/env bash
# init-docs.sh
# Purpose: Initialize docs/ directory structure and render templates

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
RENDER_TEMPLATE="$SCRIPT_DIR/render-template.sh"

# Usage
usage() {
  cat << EOF
Usage: $0 <project-root> [--archive-existing]

Initialize docs/ directory structure and render documentation templates.

Arguments:
  project-root          Path to the project where docs/ should be created
  --archive-existing    Archive existing docs/ before creating new structure

Example:
  $0 /path/to/my-project
  $0 /path/to/my-project --archive-existing
EOF
}

# Validate render-template.sh exists
if [ ! -x "$RENDER_TEMPLATE" ]; then
  echo "❌ ERROR: render-template.sh not found or not executable: $RENDER_TEMPLATE" >&2
  exit 1
fi

# Parse arguments
ARCHIVE_EXISTING=false
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  usage >&2
  exit 1
fi

PROJECT_ROOT="$1"

if [ $# -eq 2 ]; then
  if [ "$2" = "--archive-existing" ]; then
    ARCHIVE_EXISTING=true
  else
    echo "❌ ERROR: Unknown argument: $2" >&2
    usage >&2
    exit 1
  fi
fi

# Validate project root exists
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "❌ ERROR: Project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

# Ensure .spec-drive/ exists and config.yaml is present
SPEC_DRIVE_DIR="$PROJECT_ROOT/.spec-drive"
CONFIG_FILE="$SPEC_DRIVE_DIR/config.yaml"

if [ ! -d "$SPEC_DRIVE_DIR" ]; then
  echo "❌ ERROR: .spec-drive/ not found. Run init-directories.sh first." >&2
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ ERROR: config.yaml not found. Run generate-config.sh first." >&2
  exit 1
fi

DOCS_DIR="$PROJECT_ROOT/docs"

echo "================================================"
echo "  Initializing docs/ structure"
echo "================================================"
echo "Project: $PROJECT_ROOT"
echo ""

# Archive existing docs if requested
if [ "$ARCHIVE_EXISTING" = true ] && [ -d "$DOCS_DIR" ]; then
  TIMESTAMP=$(date +%Y-%m-%dT%H-%M-%S)
  ARCHIVE_DIR="$PROJECT_ROOT/docs-archive-$TIMESTAMP"
  echo "📦 Archiving existing docs/ → $ARCHIVE_DIR"
  mv "$DOCS_DIR" "$ARCHIVE_DIR"
  echo "  ✅ Archived to $ARCHIVE_DIR"
fi

# Create docs directory structure
echo "📁 Creating docs/ structure..."
mkdir -p "$DOCS_DIR"
mkdir -p "$DOCS_DIR/10-architecture"
mkdir -p "$DOCS_DIR/20-build"
mkdir -p "$DOCS_DIR/30-deployment"
mkdir -p "$DOCS_DIR/40-product"
mkdir -p "$DOCS_DIR/50-decisions"
mkdir -p "$DOCS_DIR/60-features"

# Read configuration variables from config.yaml
# (We'll use yq if available, otherwise extract manually)
if command -v yq &> /dev/null; then
  PROJECT_NAME=$(yq eval '.project.name' "$CONFIG_FILE" 2>/dev/null || echo "unknown-project")
  STACK=$(yq eval '.project.stack_profile' "$CONFIG_FILE" 2>/dev/null || echo "generic")
else
  # Fallback: simple grep-based extraction
  PROJECT_NAME=$(grep "^  name:" "$CONFIG_FILE" | sed 's/.*: *"\?\([^"]*\)"\?/\1/' || echo "unknown-project")
  STACK=$(grep "^  stack_profile:" "$CONFIG_FILE" | sed 's/.*: *"\?\([^"]*\)"\?/\1/' || echo "generic")
fi

DATE=$(date +%Y-%m-%d)

echo "  📝 PROJECT_NAME: $PROJECT_NAME"
echo "  📝 STACK: $STACK"
echo "  📝 DATE: $DATE"
echo ""

# Template rendering configuration
TEMPLATES_DIR="$PLUGIN_ROOT/templates/docs"

# Template mapping: template file → output path
declare -A TEMPLATE_MAP=(
  ["SYSTEM-OVERVIEW.md.template"]="10-architecture/SYSTEM-OVERVIEW.md"
  ["ARCHITECTURE.md.template"]="10-architecture/ARCHITECTURE.md"
  ["COMPONENT-CATALOG.md.template"]="10-architecture/COMPONENT-CATALOG.md"
  ["DATA-FLOWS.md.template"]="10-architecture/DATA-FLOWS.md"
  ["BUILD-RELEASE.md.template"]="20-build/BUILD-RELEASE.md"
  ["CI-QUALITY-GATES.md.template"]="20-build/CI-QUALITY-GATES.md"
  ["RUNTIME-DEPLOYMENT.md.template"]="30-deployment/RUNTIME-DEPLOYMENT.md"
  ["OBSERVABILITY.md.template"]="30-deployment/OBSERVABILITY.md"
  ["PRODUCT-BRIEF.md.template"]="40-product/PRODUCT-BRIEF.md"
  ["USER-JOURNEYS.md.template"]="40-product/USER-JOURNEYS.md"
  ["GLOSSARY.md.template"]="10-architecture/GLOSSARY.md"
  ["ADR-TEMPLATE.md.template"]="50-decisions/ADR-TEMPLATE.md"
)

# Render each template
echo "📝 Rendering templates..."
RENDERED_COUNT=0

for template_file in "${!TEMPLATE_MAP[@]}"; do
  OUTPUT_PATH="${TEMPLATE_MAP[$template_file]}"
  TEMPLATE_PATH="$TEMPLATES_DIR/$template_file"
  OUTPUT_FILE="$DOCS_DIR/$OUTPUT_PATH"

  if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "  ⚠️  Template not found: $template_file (skipping)"
    continue
  fi

  echo "  📄 Rendering $template_file → $OUTPUT_PATH"

  # Render template with variables
  "$RENDER_TEMPLATE" \
    --template "$TEMPLATE_PATH" \
    --output "$OUTPUT_FILE" \
    --var PROJECT_NAME="$PROJECT_NAME" \
    --var DATE="$DATE" \
    --var STACK="$STACK" \
    --var PROJECT_DESCRIPTION="A project built with spec-drive" || {
      echo "  ❌ Failed to render $template_file" >&2
      continue
    }

  RENDERED_COUNT=$((RENDERED_COUNT + 1))
done

echo ""
echo "  ✅ Rendered $RENDERED_COUNT templates"

# Create README.md in docs/
cat > "$DOCS_DIR/README.md" << EOF
# $PROJECT_NAME Documentation

Welcome to the $PROJECT_NAME documentation.

## Documentation Structure

- **10-architecture/**: System architecture, components, data flows
- **20-build/**: Build process, CI/CD, quality gates
- **30-deployment/**: Runtime deployment, observability
- **40-product/**: Product vision, user journeys
- **50-decisions/**: Architecture Decision Records (ADRs)
- **60-features/**: Feature specifications (auto-generated from specs/)

## Navigation

- [System Overview](10-architecture/SYSTEM-OVERVIEW.md) - Start here
- [Architecture](10-architecture/ARCHITECTURE.md) - Technical architecture
- [Product Brief](40-product/PRODUCT-BRIEF.md) - Product vision

## Auto-Generated Sections

Sections marked with \`<!-- AUTO:section-name -->\` are automatically regenerated by spec-drive. Manual edits outside AUTO markers are preserved.

---

🤖 Generated by spec-drive on $DATE
EOF

echo "  ✅ Created docs/README.md"

echo ""
echo "================================================"
echo "  docs/ structure created successfully!"
echo "================================================"
echo ""
echo "Documentation available at: $DOCS_DIR"
echo ""

exit 0
