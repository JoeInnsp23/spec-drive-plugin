#!/usr/bin/env bash
# scan-spec-tags.sh
# Purpose: Scan codebase for @spec tags and build traceability map
# Usage: ./scan-spec-tags.sh [--dir DIR] [--output FILE]

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Defaults
SCAN_DIR="."
OUTPUT_FILE=""
SPEC_ID_REGEX="^[A-Z][A-Z0-9]*-[0-9]{3,}$"

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

Scan codebase for @spec tags and build traceability map.

OPTIONS:
  --dir DIR       Directory to scan (default: current directory)
  --output FILE   Output file (default: stdout)
  --help          Show this help message

SUPPORTED TAG FORMATS:
  /** @spec AUTH-001 */   (TypeScript/JavaScript)
  // @spec AUTH-001       (TypeScript/JavaScript/Go)
  # @spec AUTH-001        (Bash/Python/YAML)
  """@spec AUTH-001"""    (Python docstring)

OUTPUT FORMAT (JSON):
  {
    "traces": {
      "AUTH-001": {
        "code": ["src/auth/login.ts:42"],
        "tests": ["tests/auth/login.test.ts:12"]
      }
    }
  }

EXAMPLES:
  # Scan current directory
  $0

  # Scan specific directory
  $0 --dir /path/to/project

  # Save to file
  $0 --output traces.json
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

# Validate SPEC-ID format
validate_spec_id() {
  local spec_id="$1"
  if [[ ! "$spec_id" =~ $SPEC_ID_REGEX ]]; then
    return 1
  fi
  return 0
}

# Classify file as code or test
classify_file() {
  local file="$1"

  # Test file heuristics
  if [[ "$file" =~ (^|/)tests?/ ]] || \
     [[ "$file" =~ (^|/)__tests__/ ]] || \
     [[ "$file" =~ \.(test|spec)\.(ts|tsx|js|jsx|py|go)$ ]] || \
     [[ "$file" =~ _test\.(py|go)$ ]]; then
    echo "tests"
  else
    echo "code"
  fi
}

# Escape JSON string
json_escape() {
  local str="$1"
  # Escape backslashes, quotes, and control characters
  printf '%s' "$str" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g'
}

# ==============================================================================
# Scan for @spec Tags
# ==============================================================================

# Find all files to scan (exclude common non-source directories)
find_source_files() {
  find "$SCAN_DIR" -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
    -o -name "*.py" -o -name "*.go" -o -name "*.sh" -o -name "*.bash" \
    -o -name "*.yaml" -o -name "*.yml" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    -not -path "*/.next/*" \
    -not -path "*/coverage/*" \
    -not -path "*/__pycache__/*" \
    2>/dev/null || true
}

# Scan a file for @spec tags
scan_file() {
  local file="$1"
  local file_type
  file_type=$(classify_file "$file")

  # Use grep to find @spec tags in various formats
  # Pattern matches:
  # - /** @spec SPEC-ID */
  # - // @spec SPEC-ID
  # - # @spec SPEC-ID
  # - """@spec SPEC-ID"""
  # - '''@spec SPEC-ID'''

  grep -n -E '@spec\s+[A-Z][A-Z0-9]*-[0-9]+' "$file" 2>/dev/null | while IFS=: read -r line_num line_content; do
    # Extract all SPEC-IDs from line (handles multiple tags per line)
    echo "$line_content" | grep -oE '@spec\s+[A-Z][A-Z0-9]*-[0-9]+' | while read -r tag; do
      spec_id=$(echo "$tag" | awk '{print $2}')

      if [[ -n "$spec_id" ]] && validate_spec_id "$spec_id"; then
        # Output: SPEC-ID|file_type|file:line
        echo "${spec_id}|${file_type}|${file}:${line_num}"
      fi
    done
  done
}

# Build traces map
build_traces() {
  declare -A traces_code
  declare -A traces_tests

  echo -e "${BLUE}Scanning for @spec tags...${NC}" >&2

  local file_count=0
  local tag_count=0

  while IFS= read -r file; do
    ((file_count++)) || true

    while IFS='|' read -r spec_id file_type location; do
      ((tag_count++)) || true

      if [[ "$file_type" == "tests" ]]; then
        if [[ -z "${traces_tests[$spec_id]:-}" ]]; then
          traces_tests[$spec_id]="$location"
        else
          traces_tests[$spec_id]="${traces_tests[$spec_id]},$location"
        fi
      else
        if [[ -z "${traces_code[$spec_id]:-}" ]]; then
          traces_code[$spec_id]="$location"
        else
          traces_code[$spec_id]="${traces_code[$spec_id]},$location"
        fi
      fi
    done < <(scan_file "$file")
  done < <(find_source_files)

  echo -e "${GREEN}✓${NC} Scanned $file_count files, found $tag_count @spec tags" >&2

  # Build JSON output
  echo "{"
  echo '  "traces": {'

  # Collect all unique SPEC-IDs
  local -a all_spec_ids=()
  for spec_id in "${!traces_code[@]}"; do
    all_spec_ids+=("$spec_id")
  done
  for spec_id in "${!traces_tests[@]}"; do
    if [[ ! " ${all_spec_ids[*]} " =~ " ${spec_id} " ]]; then
      all_spec_ids+=("$spec_id")
    fi
  done

  # Sort SPEC-IDs
  IFS=$'\n' sorted_spec_ids=($(sort <<<"${all_spec_ids[*]}"))
  unset IFS

  # Output traces for each SPEC-ID
  local first=true
  for spec_id in "${sorted_spec_ids[@]}"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi

    echo -n "    \"$spec_id\": {"

    # Output code traces
    echo -n '"code": ['
    if [[ -n "${traces_code[$spec_id]:-}" ]]; then
      IFS=',' read -ra locations <<< "${traces_code[$spec_id]}"
      local first_loc=true
      for loc in "${locations[@]}"; do
        if [[ "$first_loc" == true ]]; then
          first_loc=false
        else
          echo -n ", "
        fi
        echo -n "\"$(json_escape "$loc")\""
      done
    fi
    echo -n ']'

    # Output test traces
    echo -n ', "tests": ['
    if [[ -n "${traces_tests[$spec_id]:-}" ]]; then
      IFS=',' read -ra locations <<< "${traces_tests[$spec_id]}"
      local first_loc=true
      for loc in "${locations[@]}"; do
        if [[ "$first_loc" == true ]]; then
          first_loc=false
        else
          echo -n ", "
        fi
        echo -n "\"$(json_escape "$loc")\""
      done
    fi
    echo -n ']'

    echo -n "}"
  done

  echo ""
  echo '  }'
  echo "}"
}

# ==============================================================================
# Main
# ==============================================================================

if [[ -n "$OUTPUT_FILE" ]]; then
  build_traces > "$OUTPUT_FILE"
  echo -e "${GREEN}✓${NC} Output written to: $OUTPUT_FILE" >&2
else
  build_traces
fi
