#!/bin/bash
# Gate 4: Verify
# Validates feature is complete before marking workflow done

set -e

SPEC_ID="$1"
SPEC_FILE="${2:-.spec-drive/specs/SPEC-${SPEC_ID}.yaml}"

echo "===== GATE 4: VERIFY ====="
echo "Spec: $SPEC_ID"
echo "File: $SPEC_FILE"
echo ""

FAIL_COUNT=0

# Check all acceptance criteria met
echo "Checking acceptance criteria..."
if [ -f "$SPEC_FILE" ]; then
  echo "✅ Spec file exists"
  # Manual verification required - list ACs for user
  echo "ℹ️  Acceptance criteria (manual verification required):"
  grep -A 20 "acceptance_criteria:" "$SPEC_FILE" | grep -E "^\s*-" | head -10 || echo "  (No ACs found)"
else
  echo "❌ Spec file not found: $SPEC_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# Check documentation updated
echo "Checking documentation..."
if [ -d "docs" ]; then
  # Check if docs have recent changes (git status)
  if command -v git &> /dev/null; then
    DOCS_STATUS=$(git status docs/ --porcelain 2>/dev/null || echo "")
    if [ -n "$DOCS_STATUS" ]; then
      echo "✅ Documentation has uncommitted changes (needs commit)"
    else
      echo "ℹ️  Documentation unchanged (may be up to date)"
    fi
  fi

  # Check if index.yaml exists and has spec reference
  if [ -f ".spec-drive/index.yaml" ]; then
    if grep -q "$SPEC_ID" .spec-drive/index.yaml; then
      echo "✅ Spec tracked in index.yaml"
    else
      echo "⚠️  Spec not found in index.yaml (run rebuild-index)"
    fi
  else
    echo "⚠️  No .spec-drive/index.yaml found"
  fi
else
  echo "⚠️  No docs/ directory found"
fi

echo ""

# Check no shortcuts (TODO, console.log)
echo "Checking for shortcuts..."
if grep -r "TODO\|FIXME\|XXX" src/ 2>/dev/null | grep -v "node_modules" | grep -v "venv" | grep -v ".spec-drive"; then
  echo "❌ Found TODO/FIXME/XXX markers in code"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "✅ No TODO markers found"
fi

if grep -r "console\.log\|print(" src/ 2>/dev/null | grep -v "node_modules" | grep -v "venv" | grep -v ".spec-drive" | grep -v "logger\|logging"; then
  echo "⚠️  Found console.log/print statements (clean up before merge)"
else
  echo "✅ No debug statements found"
fi

echo ""

# Verify traceability complete
echo "Verifying traceability..."
if grep -r "@spec $SPEC_ID" src/ 2>/dev/null || grep -r "@spec $SPEC_ID" . 2>/dev/null | grep -v ".spec-drive" | grep -v "node_modules" | grep -v "venv"; then
  echo "✅ @spec tags present in code"
else
  echo "⚠️  No @spec tags found (add for traceability)"
fi

if grep -r "@spec $SPEC_ID" tests/ 2>/dev/null || grep -r "@spec $SPEC_ID" . 2>/dev/null | grep -i "test" | grep -v ".spec-drive" | grep -v "node_modules"; then
  echo "✅ @spec tags present in tests"
else
  echo "⚠️  No @spec tags found in tests"
fi

echo ""

# Final result
if [ $FAIL_COUNT -gt 0 ]; then
  echo "❌ GATE 4 FAILED: $FAIL_COUNT check(s) failed"
  echo ""
  echo "Fix the issues above before completing workflow."
  exit 1
fi

echo "✅ GATE 4 PASSED: Feature is complete"
echo ""
echo "Next steps:"
echo "1. Commit documentation changes"
echo "2. Create pull request"
echo "3. Request code review"
echo ""

# Set can_advance flag
if [ -f ".spec-drive/state.yaml" ]; then
  if command -v yq &> /dev/null; then
    yq eval -i ".can_advance = true" .spec-drive/state.yaml
  else
    sed -i 's/can_advance: false/can_advance: true/' .spec-drive/state.yaml
  fi
  echo "State updated: can_advance = true"
fi

exit 0
