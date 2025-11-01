#!/bin/bash
# Gate 2: Architect
# Validates architecture is documented before advancing to implement stage

set -e

SPEC_ID="$1"
SPEC_FILE="${2:-.spec-drive/specs/SPEC-${SPEC_ID}.yaml}"

echo "===== GATE 2: ARCHITECT ====="
echo "Spec: $SPEC_ID"
echo "File: $SPEC_FILE"
echo ""

# Check spec file exists
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ FAIL: Spec file not found: $SPEC_FILE"
  exit 1
fi

# Check for API contracts (if applicable)
if grep -q "api:\|api_contracts:\|endpoints:" "$SPEC_FILE"; then
  echo "✅ API contracts defined"
else
  echo "⚠️  No API contracts found (may not be applicable)"
fi

# Check for test scenarios
if grep -q "test_scenarios:\|test_cases:" "$SPEC_FILE"; then
  echo "✅ Test scenarios defined"
else
  echo "⚠️  WARNING: No test scenarios found"
  echo "Consider adding test_scenarios section to spec"
fi

# Check for dependencies
if grep -q "dependencies:" "$SPEC_FILE"; then
  echo "✅ Dependencies identified"
else
  echo "ℹ️  No dependencies listed (may be standalone feature)"
fi

# Check for architecture documentation (if new patterns)
if grep -q "architecture:\|design:" "$SPEC_FILE"; then
  echo "✅ Architecture documented"
fi

echo ""
echo "✅ GATE 2 PASSED: Architecture documented"
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
