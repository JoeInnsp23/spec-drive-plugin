#!/bin/bash
# Gate 1: Specify
# Validates spec is complete and unambiguous before advancing to architect stage

set -e

SPEC_ID="$1"
SPEC_FILE="${2:-.spec-drive/specs/SPEC-${SPEC_ID}.yaml}"

echo "===== GATE 1: SPECIFY ====="
echo "Spec: $SPEC_ID"
echo "File: $SPEC_FILE"
echo ""

# Check spec file exists
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ FAIL: Spec file not found: $SPEC_FILE"
  exit 1
fi

# Check for [NEEDS CLARIFICATION] markers
if grep -q "\[NEEDS CLARIFICATION\]" "$SPEC_FILE"; then
  echo "❌ FAIL: Spec contains [NEEDS CLARIFICATION] markers"
  echo "Ambiguous sections:"
  grep -n "\[NEEDS CLARIFICATION\]" "$SPEC_FILE"
  exit 1
fi

# Check for acceptance criteria
if ! grep -q "acceptance_criteria:" "$SPEC_FILE"; then
  echo "❌ FAIL: No acceptance_criteria section found"
  exit 1
fi

# Check for Given/When/Then format in ACs (at least one)
if ! grep -E "(Given|When|Then)" "$SPEC_FILE" > /dev/null; then
  echo "⚠️  WARNING: No Given/When/Then format detected in acceptance criteria"
  echo "Acceptance criteria should follow format:"
  echo "  Given [context]"
  echo "  When [action]"
  echo "  Then [outcome]"
fi

# Check for success criteria
if ! grep -q "success_criteria:\|measurable.*:" "$SPEC_FILE"; then
  echo "⚠️  WARNING: No measurable success criteria defined"
fi

echo ""
echo "✅ GATE 1 PASSED: Spec is complete and unambiguous"
echo ""

# Set can_advance flag in state.yaml
if [ -f ".spec-drive/state.yaml" ]; then
  # Using yq if available, otherwise sed
  if command -v yq &> /dev/null; then
    yq eval -i ".can_advance = true" .spec-drive/state.yaml
  else
    sed -i 's/can_advance: false/can_advance: true/' .spec-drive/state.yaml
  fi
  echo "State updated: can_advance = true"
fi

exit 0
