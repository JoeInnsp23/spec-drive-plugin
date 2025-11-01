#!/bin/bash
# render-template.sh
# Purpose: Template rendering with variable substitution and AUTO marker support
#
# Inputs:
#   --template FILE   : Template file path (required)
#   --output FILE     : Output file path (required)
#   --var KEY=VALUE   : Variable substitution (can be repeated)
#
# Outputs:
#   Exit 0: Success, output file created/updated
#   Exit 1: Error (missing args, file not found, etc.)
#
# Features:
#   - Variable substitution: {{VAR_NAME}} replaced with values
#   - AUTO markers: <!-- AUTO:section --> ... <!-- /AUTO --> regions regenerated
#   - Content preservation: Manual content outside AUTO markers preserved
#   - Atomic writes: Uses temp file + mv for safety
#
# Example Usage:
#   ./render-template.sh \
#     --template templates/docs/README.md.template \
#     --output docs/README.md \
#     --var PROJECT_NAME="my-app" \
#     --var VERSION="0.1.0"
#
# Limitations:
#   - No nested variables: {{VAR_{{OTHER}}}} not supported
#   - No nested AUTO markers: Must be flat structure
#   - Bash 4+ required: Uses associative arrays

set -euo pipefail

# Script metadata
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check bash version (requires 4+ for associative arrays)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  echo "❌ ERROR: Bash 4+ required (found: ${BASH_VERSION})" >&2
  exit 1
fi

# Usage function
usage() {
  cat << EOF
Usage: $SCRIPT_NAME --template FILE --output FILE [--var KEY=VALUE ...]

Required arguments:
  --template FILE    Template file to render
  --output FILE      Output file path

Optional arguments:
  --var KEY=VALUE    Variable for substitution (can be repeated)
  --help             Show this help message

Example:
  $SCRIPT_NAME \\
    --template templates/README.md.template \\
    --output docs/README.md \\
    --var PROJECT_NAME="my-app" \\
    --var VERSION="0.1.0"
EOF
}

# Initialize variables
TEMPLATE_FILE=""
OUTPUT_FILE=""
declare -A VARS  # Associative array for variables

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --template)
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --var)
      # Parse KEY=VALUE
      if [[ "$2" =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]]; then
        KEY="${BASH_REMATCH[1]}"
        VALUE="${BASH_REMATCH[2]}"
        VARS["$KEY"]="$VALUE"
        shift 2
      else
        echo "❌ ERROR: Invalid --var format: $2 (expected KEY=VALUE)" >&2
        exit 1
      fi
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "❌ ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$TEMPLATE_FILE" ]]; then
  echo "❌ ERROR: --template is required" >&2
  usage >&2
  exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
  echo "❌ ERROR: --output is required" >&2
  usage >&2
  exit 1
fi

# Validate template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "❌ ERROR: Template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# Validate template file is readable
if [[ ! -r "$TEMPLATE_FILE" ]]; then
  echo "❌ ERROR: Template file not readable: $TEMPLATE_FILE" >&2
  exit 1
fi

# Function: Substitute variables in a line
# Args: $1 = line of text
# Returns: Line with {{VAR}} replaced by values
substitute_variables() {
  local line="$1"
  local result="$line"

  # Find all {{VAR}} patterns in the line
  while [[ "$result" =~ \{\{([A-Z_][A-Z0-9_]*)\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"

    # Check if variable is defined
    if [[ -v VARS["$var_name"] ]]; then
      local var_value="${VARS[$var_name]}"
      # Escape special characters for sed
      var_value=$(printf '%s\n' "$var_value" | sed 's/[&/\]/\\&/g')
      # Replace the variable
      result=$(echo "$result" | sed "s/{{$var_name}}/$var_value/")
    else
      echo "❌ ERROR: Undefined variable: {{$var_name}} in template" >&2
      echo "Available variables:" >&2
      for key in "${!VARS[@]}"; do
        echo "  $key=${VARS[$key]}" >&2
      done
      exit 1
    fi
  done

  echo "$result"
}

# Function: Extract manual sections from existing output file
# Returns: Associative array of section_name => manual_content
extract_manual_sections() {
  local file="$1"
  declare -gA MANUAL_SECTIONS  # Global associative array

  if [[ ! -f "$file" ]]; then
    return 0  # No existing file, no manual sections
  fi

  local in_auto=false
  local current_section=""
  local manual_content=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect AUTO marker start
    if [[ "$line" =~ ^\<!--\ AUTO:([a-zA-Z0-9_-]+)\ --\>$ ]]; then
      # Save any manual content before this AUTO section
      if [[ -n "$manual_content" ]]; then
        MANUAL_SECTIONS["before_${BASH_REMATCH[1]}"]="$manual_content"
        manual_content=""
      fi
      in_auto=true
      current_section="${BASH_REMATCH[1]}"
      continue
    fi

    # Detect AUTO marker end
    if [[ "$line" =~ ^\<!--\ /AUTO\ --\>$ ]]; then
      in_auto=false
      current_section=""
      continue
    fi

    # If not in AUTO section, accumulate manual content
    if [[ "$in_auto" == false ]]; then
      manual_content+="$line"$'\n'
    fi
  done < "$file"

  # Save any trailing manual content
  if [[ -n "$manual_content" ]]; then
    MANUAL_SECTIONS["trailing"]="$manual_content"
  fi
}

# Function: Merge template output with preserved manual sections
# Args: $1 = template output file, $2 = final output file
merge_with_manual_sections() {
  local template_out="$1"
  local final_out="$2"

  # If no existing output file, just copy template output
  if [[ ! -f "$OUTPUT_FILE" ]]; then
    cat "$template_out" > "$final_out"
    return 0
  fi

  # Extract manual sections from existing file
  extract_manual_sections "$OUTPUT_FILE"

  # Now process template output and insert manual sections
  local in_auto=false
  local current_section=""
  local before_section_inserted=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Detect AUTO marker start
    if [[ "$line" =~ ^\<!--\ AUTO:([a-zA-Z0-9_-]+)\ --\>$ ]]; then
      current_section="${BASH_REMATCH[1]}"

      # Insert manual content before this AUTO section (if any)
      if [[ -v MANUAL_SECTIONS["before_$current_section"] ]]; then
        echo -n "${MANUAL_SECTIONS[before_$current_section]}" >> "$final_out"
      fi

      in_auto=true
      echo "$line" >> "$final_out"
      continue
    fi

    # Detect AUTO marker end
    if [[ "$line" =~ ^\<!--\ /AUTO\ --\>$ ]]; then
      in_auto=false
      echo "$line" >> "$final_out"
      continue
    fi

    # Always output lines (AUTO sections are regenerated, manual preserved via insertion)
    echo "$line" >> "$final_out"
  done < "$template_out"

  # Add trailing manual content (if any)
  if [[ -v MANUAL_SECTIONS["trailing"] ]]; then
    echo -n "${MANUAL_SECTIONS[trailing]}" >> "$final_out"
  fi
}

# Create temporary files
TEMP_FILE=$(mktemp)
MERGED_FILE=$(mktemp)
trap "rm -f $TEMP_FILE $MERGED_FILE" EXIT

# Step 1: Process template with variable substitution → TEMP_FILE
while IFS= read -r line || [[ -n "$line" ]]; do
  processed_line=$(substitute_variables "$line")
  echo "$processed_line" >> "$TEMP_FILE"
done < "$TEMPLATE_FILE"

# Step 2: Merge template output with existing manual sections → MERGED_FILE
merge_with_manual_sections "$TEMP_FILE" "$MERGED_FILE"

# Step 3: Validate output directory exists
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ ! -d "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR" || {
    echo "❌ ERROR: Cannot create output directory: $OUTPUT_DIR" >&2
    exit 1
  }
fi

# Step 4: Atomic write - move merged file to final output
mv "$MERGED_FILE" "$OUTPUT_FILE" || {
  echo "❌ ERROR: Cannot write output file: $OUTPUT_FILE" >&2
  exit 1
}

echo "✅ Template rendered: $OUTPUT_FILE"
exit 0
