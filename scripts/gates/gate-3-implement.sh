#!/bin/bash
# Gate 3: Implement
# Validates implementation quality before advancing to verify stage

set -e

SPEC_ID="$1"

echo "===== GATE 3: IMPLEMENT ====="
echo "Spec: $SPEC_ID"
echo ""

FAIL_COUNT=0

# Detect stack for appropriate commands
STACK="typescript"  # Default
if [ -f "package.json" ]; then
  STACK="typescript"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  STACK="python"
elif [ -f "go.mod" ]; then
  STACK="go"
elif [ -f "Cargo.toml" ]; then
  STACK="rust"
fi

echo "Detected stack: $STACK"
echo ""

# Run tests
echo "Running tests..."
case "$STACK" in
  typescript)
    if command -v npm &> /dev/null; then
      if npm test 2>&1; then
        echo "✅ Tests passed"
      else
        echo "❌ Tests failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  npm not found, skipping tests"
    fi
    ;;
  python)
    if command -v pytest &> /dev/null; then
      if pytest 2>&1; then
        echo "✅ Tests passed"
      else
        echo "❌ Tests failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  pytest not found, skipping tests"
    fi
    ;;
  go)
    if command -v go &> /dev/null; then
      if go test ./... 2>&1; then
        echo "✅ Tests passed"
      else
        echo "❌ Tests failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  go not found, skipping tests"
    fi
    ;;
  rust)
    if command -v cargo &> /dev/null; then
      if cargo test 2>&1; then
        echo "✅ Tests passed"
      else
        echo "❌ Tests failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  cargo not found, skipping tests"
    fi
    ;;
esac

echo ""

# Run linter
echo "Running linter..."
case "$STACK" in
  typescript)
    if [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
      if npm run lint 2>&1; then
        echo "✅ Lint passed"
      else
        echo "❌ Lint failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  No lint script in package.json"
    fi
    ;;
  python)
    if command -v ruff &> /dev/null; then
      if ruff check . 2>&1; then
        echo "✅ Lint passed"
      else
        echo "❌ Lint failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    elif command -v pylint &> /dev/null; then
      if pylint **/*.py 2>&1; then
        echo "✅ Lint passed"
      else
        echo "❌ Lint failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "⚠️  No linter found (ruff/pylint)"
    fi
    ;;
  go)
    if command -v go &> /dev/null; then
      if go vet ./... 2>&1; then
        echo "✅ Vet passed"
      else
        echo "❌ Vet failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    fi
    ;;
  rust)
    if command -v cargo &> /dev/null; then
      if cargo clippy 2>&1; then
        echo "✅ Clippy passed"
      else
        echo "❌ Clippy failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    fi
    ;;
esac

echo ""

# Run type check
echo "Running type check..."
case "$STACK" in
  typescript)
    if [ -f "tsconfig.json" ] && command -v npx &> /dev/null; then
      if npx tsc --noEmit 2>&1; then
        echo "✅ Type check passed"
      else
        echo "❌ Type check failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "ℹ️  No TypeScript config found"
    fi
    ;;
  python)
    if command -v mypy &> /dev/null; then
      if mypy . 2>&1; then
        echo "✅ Type check passed"
      else
        echo "❌ Type check failed"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "ℹ️  mypy not found, skipping type check"
    fi
    ;;
esac

echo ""

# Verify @spec tags present
echo "Verifying @spec tags..."
if grep -r "@spec $SPEC_ID" src/ 2>/dev/null || grep -r "@spec $SPEC_ID" . 2>/dev/null | grep -v ".spec-drive" | grep -v "node_modules" | grep -v "venv"; then
  echo "✅ @spec $SPEC_ID tags found"
else
  echo "⚠️  WARNING: No @spec $SPEC_ID tags found"
  echo "Code should include @spec tags for traceability"
fi

echo ""

# Final result
if [ $FAIL_COUNT -gt 0 ]; then
  echo "❌ GATE 3 FAILED: $FAIL_COUNT check(s) failed"
  echo ""
  exit 1
fi

echo "✅ GATE 3 PASSED: Implementation meets quality standards"
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
