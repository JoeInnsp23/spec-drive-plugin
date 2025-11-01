#!/bin/bash
# update-docs.sh
# Purpose: Regenerate AUTO sections in documentation from index.yaml
# Usage: ./update-docs.sh [--dry-run]

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
INDEX_FILE="$SPEC_DRIVE_DIR/index.yaml"
DOCS_DIR="docs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
DRY_RUN=false

# ==============================================================================
# Argument Parsing
# ==============================================================================

show_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Regenerate AUTO sections in documentation from index.yaml.

OPTIONS:
  --dry-run       Show what would be updated without making changes
  --help          Show this help message

AUTO SECTION MARKERS:
  <!-- AUTO:components -->
  ...generated content...
  <!-- /AUTO -->

SUPPORTED AUTO SECTIONS:
  - components: List of components
  - matrix: Traceability matrix (spec → code → tests → docs)
  - specs: List of specs
  - docs: List of documentation

EXAMPLES:
  # Update all docs
  $0

  # Preview changes
  $0 --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      show_usage
      exit 0
      ;;
    *)
      echo -e "${RED}❌ ERROR: Unknown option: $1${NC}" >&2
      show_usage
      exit 1
      ;;
  esac
done

# ==============================================================================
# Prerequisite Checks
# ==============================================================================

if [[ ! -f "$INDEX_FILE" ]]; then
  echo -e "${RED}❌ ERROR: index.yaml not found${NC}" >&2
  echo "Run update-index.sh first to generate index.yaml" >&2
  exit 1
fi

if [[ ! -d "$DOCS_DIR" ]]; then
  echo -e "${YELLOW}⚠${NC}  No docs/ directory found, nothing to update"
  exit 0
fi

# ==============================================================================
# Content Generators
# ==============================================================================

# Generate components list
generate_components_list() {
  local index_file="$1"

  echo ""
  echo "| Component | Type | Path |"
  echo "|-----------|------|------|"

  local component_count=$(yq eval '.components | length' "$index_file" 2>/dev/null || echo "0")

  if [[ "$component_count" -gt 0 ]]; then
    yq eval '.components[] | [.name, .type, .path] | @tsv' "$index_file" 2>/dev/null | while IFS=$'\t' read -r name type path; do
      echo "| $name | $type | $path |"
    done
  else
    echo "| _(No components)_ | | |"
  fi

  echo ""
}

# Generate specs list
generate_specs_list() {
  local index_file="$1"

  echo ""
  echo "| Spec ID | Title | Status |"
  echo "|---------|-------|--------|"

  local spec_count=$(yq eval '.specs | length' "$index_file" 2>/dev/null || echo "0")

  if [[ "$spec_count" -gt 0 ]]; then
    yq eval '.specs[] | [.id, .title, .status] | @tsv' "$index_file" 2>/dev/null | while IFS=$'\t' read -r id title status; do
      echo "| $id | $title | $status |"
    done
  else
    echo "| _(No specs)_ | | |"
  fi

  echo ""
}

# Generate traceability matrix
generate_traceability_matrix() {
  local index_file="$1"

  echo ""
  echo "| Spec ID | Title | Code | Tests | Docs |"
  echo "|---------|-------|------|-------|------|"

  local spec_count=$(yq eval '.specs | length' "$index_file" 2>/dev/null || echo "0")

  if [[ "$spec_count" -eq 0 ]]; then
    echo "| _(No specs)_ | | | | |"
  else
    local i=0
    while [[ $i -lt $spec_count ]]; do
      local spec_id=$(yq eval ".specs[$i].id" "$index_file" 2>/dev/null || echo "?")
      local spec_title=$(yq eval ".specs[$i].title" "$index_file" 2>/dev/null || echo "?")

      local code_count=$(yq eval ".specs[$i].trace.code | length" "$index_file" 2>/dev/null || echo "0")
      local test_count=$(yq eval ".specs[$i].trace.tests | length" "$index_file" 2>/dev/null || echo "0")
      local doc_count=$(yq eval ".specs[$i].trace.docs | length" "$index_file" 2>/dev/null || echo "0")

      # Status indicators
      local code_status="❌"
      local test_status="❌"
      local doc_status="❌"

      [[ $code_count -gt 0 ]] && code_status="✅ ${code_count}"
      [[ $test_count -gt 0 ]] && test_status="✅ ${test_count}"
      [[ $doc_count -gt 0 ]] && doc_status="✅ ${doc_count}"

      echo "| $spec_id | $spec_title | $code_status | $test_status | $doc_status |"

      i=$((i + 1))
    done
  fi

  echo ""
}

# Generate docs list
generate_docs_list() {
  local index_file="$1"

  echo ""
  echo "| Document | Type | Summary |"
  echo "|----------|------|---------|"

  local doc_count=$(yq eval '.docs | length' "$index_file" 2>/dev/null || echo "0")

  if [[ "$doc_count" -gt 0 ]]; then
    yq eval '.docs[] | [.path, .type, .summary] | @tsv' "$index_file" 2>/dev/null | while IFS=$'\t' read -r path type summary; do
      echo "| $path | $type | $summary |"
    done
  else
    echo "| _(No docs)_ | | |"
  fi

  echo ""
}

# ==============================================================================
# AUTO Section Updates
# ==============================================================================

# Update AUTO sections in a file
update_auto_sections() {
  local doc_file="$1"
  local index_file="$2"

  if [[ ! -f "$doc_file" ]]; then
    return
  fi

  local temp_file=$(mktemp)
  local in_auto=false
  local auto_type=""
  local updated=false

  while IFS= read -r line; do
    # Check for AUTO section start
    if [[ "$line" =~ \<!--\ AUTO:([a-z]+)\ --\> ]]; then
      in_auto=true
      auto_type="${BASH_REMATCH[1]}"
      echo "$line" >> "$temp_file"

      # Generate content for this AUTO type
      case "$auto_type" in
        components)
          generate_components_list "$index_file" >> "$temp_file"
          ;;
        specs)
          generate_specs_list "$index_file" >> "$temp_file"
          ;;
        matrix)
          generate_traceability_matrix "$index_file" >> "$temp_file"
          ;;
        docs)
          generate_docs_list "$index_file" >> "$temp_file"
          ;;
        *)
          echo "" >> "$temp_file"
          echo "_(Unknown AUTO section type: $auto_type)_" >> "$temp_file"
          echo "" >> "$temp_file"
          ;;
      esac

      updated=true
      continue
    fi

    # Check for AUTO section end
    if [[ "$line" =~ \<!--\ /AUTO\ --\> ]]; then
      in_auto=false
      auto_type=""
      echo "$line" >> "$temp_file"
      continue
    fi

    # Skip lines inside AUTO sections (will be regenerated)
    if [[ "$in_auto" == true ]]; then
      continue
    fi

    # Preserve all other lines
    echo "$line" >> "$temp_file"
  done < "$doc_file"

  # Replace original file if updated
  if [[ "$updated" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo -e "  ${BLUE}Would update${NC}: $doc_file"
    else
      mv "$temp_file" "$doc_file"
      echo -e "  ${GREEN}✓${NC} Updated: $doc_file"
    fi
  else
    rm -f "$temp_file"
  fi
}

# ==============================================================================
# Main Process
# ==============================================================================

if [[ "$DRY_RUN" == true ]]; then
  echo -e "${YELLOW}DRY RUN MODE${NC} - No files will be modified"
  echo ""
fi

echo -e "${BLUE}Updating documentation AUTO sections...${NC}"
echo ""

UPDATE_COUNT=0

# Find all markdown files with AUTO markers
while IFS= read -r doc_file; do
  if grep -q '<!-- AUTO:' "$doc_file" 2>/dev/null; then
    update_auto_sections "$doc_file" "$INDEX_FILE"
    UPDATE_COUNT=$((UPDATE_COUNT + 1))
  fi
done < <(find "$DOCS_DIR" -type f -name "*.md" 2>/dev/null || true)

echo ""

if [[ $UPDATE_COUNT -eq 0 ]]; then
  echo -e "${YELLOW}⚠${NC}  No AUTO sections found in documentation"
  echo "Add AUTO markers to docs to enable auto-updates:"
  echo ""
  echo "  <!-- AUTO:components -->"
  echo "  <!-- /AUTO -->"
  echo ""
else
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN:${NC} Would update $UPDATE_COUNT documents"
  else
    echo -e "${GREEN}✓${NC} Updated $UPDATE_COUNT documents"
  fi
  echo ""
fi
