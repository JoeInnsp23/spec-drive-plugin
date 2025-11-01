#!/bin/bash
# update-index.sh
# Purpose: Populate index.yaml with components, specs, docs, and traces
# Usage: ./update-index.sh [--output FILE]

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SPEC_DRIVE_DIR="${SPEC_DRIVE_DIR:-.spec-drive}"
INDEX_FILE="$SPEC_DRIVE_DIR/index.yaml"
SPECS_DIR="$SPEC_DRIVE_DIR/specs"
DOCS_DIR="docs"

# Scripts
ANALYZE_CODE_SCRIPT="$SCRIPT_DIR/analyze-code.sh"
SCAN_TAGS_SCRIPT="$SCRIPT_DIR/scan-spec-tags.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Argument Parsing
# ==============================================================================

OUTPUT_FILE="$INDEX_FILE"

show_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Populate index.yaml with components, specs, docs, and code traces.

OPTIONS:
  --output FILE   Output file (default: .spec-drive/index.yaml)
  --help          Show this help message

PROCESS:
  1. Run analyze-code.sh → get components
  2. Run scan-spec-tags.sh → get @spec traces
  3. Read all specs from .spec-drive/specs/
  4. Scan docs/ for documentation files
  5. Merge all data into index.yaml

EXAMPLES:
  # Generate index
  $0

  # Generate to custom location
  $0 --output /tmp/index.yaml
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_FILE="$2"
      shift 2
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

if [[ ! -x "$ANALYZE_CODE_SCRIPT" ]]; then
  echo -e "${RED}❌ ERROR: analyze-code.sh not found or not executable${NC}" >&2
  echo "Path: $ANALYZE_CODE_SCRIPT" >&2
  exit 1
fi

if [[ ! -x "$SCAN_TAGS_SCRIPT" ]]; then
  echo -e "${RED}❌ ERROR: scan-spec-tags.sh not found or not executable${NC}" >&2
  echo "Path: $SCAN_TAGS_SCRIPT" >&2
  exit 1
fi

# ==============================================================================
# Helper Functions
# ==============================================================================

# Get project name from package.json or directory name
get_project_name() {
  if [[ -f "package.json" ]]; then
    jq -r '.name // "unknown"' package.json 2>/dev/null || echo "unknown"
  else
    basename "$(pwd)"
  fi
}

# Get version from package.json or default
get_project_version() {
  if [[ -f "package.json" ]]; then
    jq -r '.version // "0.1.0"' package.json 2>/dev/null || echo "0.1.0"
  else
    echo "0.1.0"
  fi
}

# Scan docs directory for markdown files
scan_docs() {
  local docs_dir="$1"

  if [[ ! -d "$docs_dir" ]]; then
    echo "[]"
    return
  fi

  echo "["
  local first=true

  find "$docs_dir" -type f -name "*.md" 2>/dev/null | sort | while IFS= read -r doc_file; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi

    # Classify doc type based on path
    local doc_type="other"
    case "$doc_file" in
      */00-overview/*|*/overview/*) doc_type="overview" ;;
      */10-architecture/*|*/architecture/*) doc_type="architecture" ;;
      */20-build/*|*/build/*) doc_type="build" ;;
      */40-api/*|*/api/*) doc_type="api" ;;
      */50-decisions/*|*/decisions/*|*/adr/*) doc_type="decision" ;;
      */60-features/*|*/features/*) doc_type="feature" ;;
      *README.md) doc_type="readme" ;;
    esac

    # Extract first heading as summary
    local summary=$(grep -m 1 '^#' "$doc_file" 2>/dev/null | sed 's/^#* *//' || echo "")
    if [[ -z "$summary" ]]; then
      summary=$(basename "$doc_file" .md | sed 's/-/ /g')
    fi

    echo -n "    {\"path\": \"$doc_file\", \"type\": \"$doc_type\", \"summary\": \"$summary\"}"
  done

  echo ""
  echo "  ]"
}

# ==============================================================================
# Main Process
# ==============================================================================

echo -e "${BLUE}Generating index.yaml...${NC}"
echo ""

# Step 1: Analyze code for components
echo -e "${BLUE}1. Analyzing codebase for components...${NC}"
COMPONENTS_JSON=$(mktemp)
if [[ -d "src" ]]; then
  "$ANALYZE_CODE_SCRIPT" --dir src --output "$COMPONENTS_JSON" 2>&1 | grep -E "(Analyzing|✓)" || true
elif [[ -d "lib" ]]; then
  "$ANALYZE_CODE_SCRIPT" --dir lib --output "$COMPONENTS_JSON" 2>&1 | grep -E "(Analyzing|✓)" || true
else
  echo '{"components": []}' > "$COMPONENTS_JSON"
  echo -e "${YELLOW}⚠${NC}  No src/ or lib/ directory found, skipping component detection"
fi

COMPONENT_COUNT=$(jq '.components | length' "$COMPONENTS_JSON" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Found $COMPONENT_COUNT components"
echo ""

# Step 2: Scan for @spec tags
echo -e "${BLUE}2. Scanning for @spec tags...${NC}"
TRACES_JSON=$(mktemp)
"$SCAN_TAGS_SCRIPT" --dir . --output "$TRACES_JSON" 2>&1 | grep -E "(Scanning|✓)" || true

TRACE_COUNT=$(jq '.traces | length' "$TRACES_JSON" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Found traces for $TRACE_COUNT specs"
echo ""

# Step 3: Read specs
echo -e "${BLUE}3. Reading specs...${NC}"
SPEC_COUNT=0
if [[ -d "$SPECS_DIR" ]]; then
  SPEC_COUNT=$(find "$SPECS_DIR" -type f -name "*.yaml" 2>/dev/null | wc -l)
fi
echo -e "${GREEN}✓${NC} Found $SPEC_COUNT spec files"
echo ""

# Step 4: Scan docs
echo -e "${BLUE}4. Scanning documentation...${NC}"
DOC_COUNT=0
if [[ -d "$DOCS_DIR" ]]; then
  DOC_COUNT=$(find "$DOCS_DIR" -type f -name "*.md" 2>/dev/null | wc -l)
fi
echo -e "${GREEN}✓${NC} Found $DOC_COUNT documentation files"
echo ""

# Step 5: Build index.yaml
echo -e "${BLUE}5. Building index.yaml...${NC}"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PROJECT_NAME=$(get_project_name)
PROJECT_VERSION=$(get_project_version)

# Create temporary file
TEMP_FILE=$(mktemp)

cat > "$TEMP_FILE" << EOF
# index.yaml
# Generated: $TIMESTAMP
# Auto-generated index of components, specs, docs, and code traces

meta:
  generated: "$TIMESTAMP"
  version: "$PROJECT_VERSION"
  project_name: "$PROJECT_NAME"

EOF

# Add components section
echo "components:" >> "$TEMP_FILE"
if [[ $COMPONENT_COUNT -gt 0 ]]; then
  jq -r '.components[] | "  - id: \"\(.id)\"\n    type: \"\(.type)\"\n    path: \"\(.path)\"\n    name: \"\(.name)\"\n    summary: \"\(.summary)\""' "$COMPONENTS_JSON" >> "$TEMP_FILE"
else
  echo "  []" >> "$TEMP_FILE"
fi
echo "" >> "$TEMP_FILE"

# Add specs section
echo "specs:" >> "$TEMP_FILE"
if [[ $SPEC_COUNT -gt 0 ]]; then
  find "$SPECS_DIR" -type f -name "*.yaml" 2>/dev/null | sort | while IFS= read -r spec_file; do
    spec_id=$(yq eval '.id' "$spec_file" 2>/dev/null || echo "")
    spec_title=$(yq eval '.title' "$spec_file" 2>/dev/null || echo "")
    spec_status=$(yq eval '.status' "$spec_file" 2>/dev/null || echo "draft")

    if [[ -n "$spec_id" ]]; then
      echo "  - id: \"$spec_id\"" >> "$TEMP_FILE"
      echo "    title: \"$spec_title\"" >> "$TEMP_FILE"
      echo "    status: \"$spec_status\"" >> "$TEMP_FILE"
      echo "    file: \"$spec_file\"" >> "$TEMP_FILE"

      # Add traces if available
      code_traces=$(jq -r ".traces.\"$spec_id\".code[]? // empty" "$TRACES_JSON" 2>/dev/null)
      test_traces=$(jq -r ".traces.\"$spec_id\".tests[]? // empty" "$TRACES_JSON" 2>/dev/null)

      if [[ -n "$code_traces" ]] || [[ -n "$test_traces" ]]; then
        echo "    trace:" >> "$TEMP_FILE"

        if [[ -n "$code_traces" ]]; then
          echo "      code:" >> "$TEMP_FILE"
          echo "$code_traces" | while IFS= read -r trace; do
            echo "        - \"$trace\"" >> "$TEMP_FILE"
          done
        else
          echo "      code: []" >> "$TEMP_FILE"
        fi

        if [[ -n "$test_traces" ]]; then
          echo "      tests:" >> "$TEMP_FILE"
          echo "$test_traces" | while IFS= read -r trace; do
            echo "        - \"$trace\"" >> "$TEMP_FILE"
          done
        else
          echo "      tests: []" >> "$TEMP_FILE"
        fi

        # Docs traces (check for feature docs)
        feature_doc="docs/60-features/${spec_id}.md"
        if [[ -f "$feature_doc" ]]; then
          echo "      docs:" >> "$TEMP_FILE"
          echo "        - \"$feature_doc\"" >> "$TEMP_FILE"
        else
          echo "      docs: []" >> "$TEMP_FILE"
        fi
      fi

      echo "" >> "$TEMP_FILE"
    fi
  done
else
  echo "  []" >> "$TEMP_FILE"
fi

# Add docs section
echo "docs:" >> "$TEMP_FILE"
if [[ $DOC_COUNT -gt 0 ]]; then
  find "$DOCS_DIR" -type f -name "*.md" 2>/dev/null | sort | while IFS= read -r doc_file; do
    # Classify doc type
    doc_type="other"
    case "$doc_file" in
      */00-overview/*|*/overview/*) doc_type="overview" ;;
      */10-architecture/*|*/architecture/*) doc_type="architecture" ;;
      */20-build/*|*/build/*) doc_type="build" ;;
      */40-api/*|*/api/*) doc_type="api" ;;
      */50-decisions/*|*/decisions/*|*/adr/*) doc_type="decision" ;;
      */60-features/*|*/features/*) doc_type="feature" ;;
      *README.md) doc_type="readme" ;;
    esac

    # Extract summary
    summary=$(grep -m 1 '^#' "$doc_file" 2>/dev/null | sed 's/^#* *//' || basename "$doc_file" .md | sed 's/-/ /g')

    echo "  - path: \"$doc_file\"" >> "$TEMP_FILE"
    echo "    type: \"$doc_type\"" >> "$TEMP_FILE"
    echo "    summary: \"$summary\"" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
  done
else
  echo "  []" >> "$TEMP_FILE"
fi

# Move to final location atomically
mkdir -p "$(dirname "$OUTPUT_FILE")"
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Cleanup
rm -f "$COMPONENTS_JSON" "$TRACES_JSON"

echo -e "${GREEN}✓${NC} Generated index.yaml"
echo ""

# ==============================================================================
# Summary
# ==============================================================================

echo -e "${GREEN}Index generation complete!${NC}"
echo ""
echo "Summary:"
echo "  Components: $COMPONENT_COUNT"
echo "  Specs: $SPEC_COUNT"
echo "  Docs: $DOC_COUNT"
echo "  Traces: $TRACE_COUNT specs with code/test links"
echo ""
echo "Output: $OUTPUT_FILE"
echo ""
