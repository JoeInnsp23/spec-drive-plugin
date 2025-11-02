#!/usr/bin/env bash
# validate-templates.sh
# Purpose: Validate documentation templates and document their variables

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/templates/docs"

echo "================================================"
echo "  Template Validation Report"
echo "================================================"
echo ""

# Counters
TOTAL_TEMPLATES=0
VALID_TEMPLATES=0
ISSUES_FOUND=0

# Process each template
for template in "$TEMPLATES_DIR"/*.template; do
  TOTAL_TEMPLATES=$((TOTAL_TEMPLATES + 1))
  template_name=$(basename "$template")

  echo "📄 $template_name"

  # Extract variables
  VARS=$(grep -oE '\{\{[A-Z_][A-Z0-9_]*\}\}' "$template" | sort -u || true)
  VAR_COUNT=$(echo "$VARS" | grep -c "{{" || echo "0")

  # Extract AUTO markers
  AUTO_MARKERS=$(grep -oE '<!-- AUTO:[a-zA-Z0-9_-]+ -->' "$template" || true)
  AUTO_COUNT=$(echo "$AUTO_MARKERS" | grep -c "AUTO:" || echo "0")

  # Check for old-style markers (BEGIN/END)
  OLD_MARKERS=$(grep -E '<!-- AUTO:(BEGIN|END):' "$template" || true)

  # Validation checks
  TEMPLATE_VALID=true

  # Check 1: Has variables
  if [ "$VAR_COUNT" -gt 0 ]; then
    echo "  ✅ Variables: $VAR_COUNT found"
    echo "$VARS" | sed 's/^/     - /'
  else
    echo "  ⚠️  Variables: None (may be intentional)"
  fi

  # Check 2: AUTO markers formatted correctly
  if [ "$AUTO_COUNT" -gt 0 ]; then
    echo "  ✅ AUTO markers: $AUTO_COUNT found"
    echo "$AUTO_MARKERS" | sed 's/^/     - /'
  else
    echo "  ℹ️  AUTO markers: None"
  fi

  # Check 3: No old-style markers
  if [ -n "$OLD_MARKERS" ]; then
    echo "  ❌ ISSUE: Old-style AUTO markers found (BEGIN/END format)"
    echo "$OLD_MARKERS" | sed 's/^/     - /'
    TEMPLATE_VALID=false
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  fi

  # Check 4: Closing markers match opening markers
  OPENING=$(grep -c '<!-- AUTO:[a-zA-Z0-9_-]* -->' "$template" || echo "0")
  CLOSING=$(grep -c '<!-- /AUTO -->' "$template" || echo "0")

  if [ "$OPENING" -ne "$CLOSING" ]; then
    echo "  ❌ ISSUE: Mismatched AUTO markers (opening: $OPENING, closing: $CLOSING)"
    TEMPLATE_VALID=false
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
  else
    if [ "$OPENING" -gt 0 ]; then
      echo "  ✅ AUTO markers balanced: $OPENING pairs"
    fi
  fi

  if [ "$TEMPLATE_VALID" = true ]; then
    VALID_TEMPLATES=$((VALID_TEMPLATES + 1))
  fi

  echo ""
done

# Summary
echo "================================================"
echo "  Summary"
echo "================================================"
echo "Total templates:   $TOTAL_TEMPLATES"
echo "Valid templates:   $VALID_TEMPLATES"
echo "Issues found:      $ISSUES_FOUND"
echo "================================================"

if [ "$ISSUES_FOUND" -eq 0 ]; then
  echo "✅ All templates valid!"
  exit 0
else
  echo "❌ Some templates have issues - see above"
  exit 1
fi
