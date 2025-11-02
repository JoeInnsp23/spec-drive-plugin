#!/usr/bin/env bash
# analyze-code.sh
# Purpose: Analyze codebase and detect components (classes, functions, services)
# Usage: ./analyze-code.sh [--dir DIR] [--output FILE]

set -eo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Defaults
SCAN_DIR="."
OUTPUT_FILE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==============================================================================
# Argument Parsing
# ==============================================================================

show_usage() {
  cat << EOF
Usage: $0 [OPTIONS]

Analyze codebase and detect components (classes, functions, services).

OPTIONS:
  --dir DIR       Directory to scan (default: current directory)
  --output FILE   Output file (default: stdout)
  --help          Show this help message

DETECTION STRATEGY:
  - TypeScript/JavaScript: export class, export function, export const
  - Python: class definitions, module-level functions
  - Go: struct types, functions
  - Fallback: File-level components (one per source file)

OUTPUT FORMAT (JSON):
  {
    "components": [
      {
        "id": "auth-service",
        "type": "class",
        "path": "src/auth/AuthService.ts:15",
        "name": "AuthService",
        "summary": "Handles user authentication"
      }
    ]
  }

EXAMPLES:
  # Scan src directory
  $0 --dir src

  # Save to file
  $0 --dir src --output components.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      SCAN_DIR="$2"
      shift 2
      ;;
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
# Validation
# ==============================================================================

if [[ ! -d "$SCAN_DIR" ]]; then
  echo -e "${RED}❌ ERROR: Directory not found: $SCAN_DIR${NC}" >&2
  exit 1
fi

# ==============================================================================
# Helper Functions
# ==============================================================================

# Generate kebab-case ID from name
generate_component_id() {
  local name="$1"
  # Convert to lowercase, replace spaces/underscores with hyphens
  echo "$name" | sed 's/\([A-Z]\)/-\1/g' | tr '[:upper:]' '[:lower:]' | sed 's/^-//' | tr '_' '-' | tr ' ' '-'
}

# Extract summary from comment
extract_summary() {
  local file="$1"
  local line_num="$2"
  local lang="$3"

  # Look for comment above the component (up to 5 lines back)
  local start=$((line_num - 5))
  if [[ $start -lt 1 ]]; then
    start=1
  fi

  local summary=""

  case "$lang" in
    typescript|javascript)
      # Look for JSDoc /** ... */ or // comment
      summary=$(sed -n "${start},${line_num}p" "$file" 2>/dev/null | \
        grep -E '^\s*(/\*\*|//|/\*)' 2>/dev/null | \
        sed 's|^\s*/\*\*\?\s*||; s|\s*\*/\s*$||; s|^\s*//\s*||' 2>/dev/null | \
        grep -v '^$' 2>/dev/null | head -1 2>/dev/null || true)
      ;;
    python)
      # Look for docstring """ or # comment
      summary=$(sed -n "${start},${line_num}p" "$file" 2>/dev/null | \
        grep -E '^\s*("""|#)' 2>/dev/null | \
        sed 's|^\s*"""\s*||; s|\s*"""\s*$||; s|^\s*#\s*||' 2>/dev/null | \
        grep -v '^$' 2>/dev/null | head -1 2>/dev/null || true)
      ;;
    go)
      # Look for // comment
      summary=$(sed -n "${start},${line_num}p" "$file" 2>/dev/null | \
        grep -E '^\s*//' 2>/dev/null | \
        sed 's|^\s*//\s*||' 2>/dev/null | \
        grep -v '^$' 2>/dev/null | head -1 2>/dev/null || true)
      ;;
  esac

  echo "$summary"
}

# Detect language from file extension
detect_language() {
  local file="$1"
  case "$file" in
    *.ts|*.tsx) echo "typescript" ;;
    *.js|*.jsx) echo "javascript" ;;
    *.py) echo "python" ;;
    *.go) echo "go" ;;
    *) echo "unknown" ;;
  esac
}

# Escape JSON string
json_escape() {
  local str="$1"
  printf '%s' "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | sed 's/  */ /g'
}

# ==============================================================================
# Component Detection
# ==============================================================================

# Find source files
find_source_files() {
  find "$SCAN_DIR" -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
    -o -name "*.py" -o -name "*.go" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/.next/*" \
    -not -path "*/coverage/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/tests/*" \
    -not -path "*/test/*" \
    -not -path "*/__tests__/*" \
    -not -name "*.test.*" \
    -not -name "*.spec.*" \
    -not -name "*_test.*" \
    2>/dev/null || true
}

# Detect TypeScript/JavaScript components
detect_ts_js_components() {
  local file="$1"
  local lang="$2"

  # Pattern 1: export class ClassName
  { grep -n -E '^\s*export\s+(abstract\s+)?class\s+[A-Z][a-zA-Z0-9]*' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local class_name=$(echo "$line_content" | sed -E 's/^\s*export\s+(abstract\s+)?class\s+([A-Z][a-zA-Z0-9]*).*/\2/')
    local component_id=$(generate_component_id "$class_name")
    local summary=$(extract_summary "$file" "$line_num" "$lang")
    if [[ -z "$summary" ]]; then
      summary="$class_name class"
    fi
    echo "class|$component_id|$class_name|$file:$line_num|$(json_escape "$summary")"
  done

  # Pattern 2: export function functionName
  { grep -n -E '^\s*export\s+(async\s+)?function\s+[a-zA-Z][a-zA-Z0-9]*' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local func_name=$(echo "$line_content" | sed -E 's/^\s*export\s+(async\s+)?function\s+([a-zA-Z][a-zA-Z0-9]*).*/\2/')
    local component_id=$(generate_component_id "$func_name")
    local summary=$(extract_summary "$file" "$line_num" "$lang" || echo "")
    if [[ -z "$summary" ]]; then
      summary="$func_name function"
    fi
    echo "function|$component_id|$func_name|$file:$line_num|$(json_escape "$summary")"
  done

  # Pattern 3: export const serviceName = (for services/constants)
  { grep -n -E '^\s*export\s+const\s+[A-Z][a-zA-Z0-9]*\s*=' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local const_name=$(echo "$line_content" | sed -E 's/^\s*export\s+const\s+([A-Z][a-zA-Z0-9]*)\s*=.*/\1/')
    local component_id=$(generate_component_id "$const_name")
    local summary=$(extract_summary "$file" "$line_num" "$lang")
    if [[ -z "$summary" ]]; then
      summary="$const_name constant"
    fi
    echo "const|$component_id|$const_name|$file:$line_num|$(json_escape "$summary")"
  done
}

# Detect Python components
detect_python_components() {
  local file="$1"

  # Pattern 1: class ClassName
  { grep -n -E '^\s*class\s+[A-Z][a-zA-Z0-9]*' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local class_name=$(echo "$line_content" | sed -E 's/^\s*class\s+([A-Z][a-zA-Z0-9]*).*/\1/')
    local component_id=$(generate_component_id "$class_name")
    local summary=$(extract_summary "$file" "$line_num" "python" || echo "")
    if [[ -z "$summary" ]]; then
      summary="$class_name class"
    fi
    echo "class|$component_id|$class_name|$file:$line_num|$(json_escape "$summary")"
  done

  # Pattern 2: def function_name (module level - no indentation)
  { grep -n -E '^def\s+[a-z][a-zA-Z0-9_]*' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local func_name=$(echo "$line_content" | sed -E 's/^def\s+([a-z][a-zA-Z0-9_]*).*/\1/')
    local component_id=$(generate_component_id "$func_name")
    local summary=$(extract_summary "$file" "$line_num" "python" || echo "")
    if [[ -z "$summary" ]]; then
      summary="$func_name function"
    fi
    echo "function|$component_id|$func_name|$file:$line_num|$(json_escape "$summary")"
  done
}

# Detect Go components
detect_go_components() {
  local file="$1"

  # Pattern 1: type StructName struct
  { grep -n -E '^\s*type\s+[A-Z][a-zA-Z0-9]*\s+struct' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local struct_name=$(echo "$line_content" | sed -E 's/^\s*type\s+([A-Z][a-zA-Z0-9]*)\s+struct.*/\1/')
    local component_id=$(generate_component_id "$struct_name")
    local summary=$(extract_summary "$file" "$line_num" "go" || echo "")
    if [[ -z "$summary" ]]; then
      summary="$struct_name struct"
    fi
    echo "struct|$component_id|$struct_name|$file:$line_num|$(json_escape "$summary")"
  done

  # Pattern 2: func FunctionName
  { grep -n -E '^\s*func\s+[A-Z][a-zA-Z0-9]*' "$file" 2>/dev/null || true; } | while IFS=: read -r line_num line_content; do
    local func_name=$(echo "$line_content" | sed -E 's/^\s*func\s+([A-Z][a-zA-Z0-9]*).*/\1/')
    local component_id=$(generate_component_id "$func_name")
    local summary=$(extract_summary "$file" "$line_num" "go" || echo "")
    if [[ -z "$summary" ]]; then
      summary="$func_name function"
    fi
    echo "function|$component_id|$func_name|$file:$line_num|$(json_escape "$summary")"
  done
}

# Analyze a single file
analyze_file() {
  local file="$1"
  local lang=$(detect_language "$file")

  case "$lang" in
    typescript|javascript)
      detect_ts_js_components "$file" "$lang"
      ;;
    python)
      detect_python_components "$file"
      ;;
    go)
      detect_go_components "$file"
      ;;
  esac
}

# Build components JSON
build_components_json() {
  declare -A seen_ids

  echo -e "${BLUE}Analyzing codebase...${NC}" >&2

  local file_count=0
  local component_count=0

  echo "{"
  echo '  "components": ['

  local first=true

  while IFS= read -r file; do
    file_count=$((file_count + 1))

    while IFS='|' read -r comp_type comp_id comp_name comp_path comp_summary; do
      # Ensure unique IDs (append number if duplicate)
      local unique_id="$comp_id"
      local counter=2
      while [[ -n "${seen_ids[$unique_id]:-}" ]]; do
        unique_id="${comp_id}-${counter}"
        counter=$((counter + 1))
      done
      seen_ids[$unique_id]=1

      if [[ "$first" == "true" ]]; then
        first=false
      else
        echo ","
      fi

      component_count=$((component_count + 1))

      echo -n "    {"
      echo -n "\"id\": \"$unique_id\", "
      echo -n "\"type\": \"$comp_type\", "
      echo -n "\"path\": \"$comp_path\", "
      echo -n "\"name\": \"$comp_name\", "
      echo -n "\"summary\": \"$comp_summary\""
      echo -n "}"
    done < <(analyze_file "$file")
  done < <(find_source_files)

  echo ""
  echo '  ]'
  echo "}"

  echo -e "${GREEN}✓${NC} Analyzed $file_count files, found $component_count components" >&2
}

# ==============================================================================
# Main
# ==============================================================================

if [[ -n "$OUTPUT_FILE" ]]; then
  build_components_json > "$OUTPUT_FILE"
  echo -e "${GREEN}✓${NC} Output written to: $OUTPUT_FILE" >&2
else
  build_components_json
fi
