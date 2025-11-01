#!/bin/bash
# generate-config.sh
# Purpose: Generate config.yaml from template with auto-detection

set -euo pipefail

# Script metadata
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Usage
usage() {
  cat << EOF
Usage: $0 <project-root>

Generate .spec-drive/config.yaml with auto-detected project settings.

Arguments:
  project-root    Path to the project

Example:
  $0 /path/to/my-project
EOF
}

# Validate arguments
if [ $# -ne 1 ]; then
  usage >&2
  exit 1
fi

PROJECT_ROOT="$1"

# Validate project root exists
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "❌ ERROR: Project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

SPEC_DRIVE_DIR="$PROJECT_ROOT/.spec-drive"
CONFIG_FILE="$SPEC_DRIVE_DIR/config.yaml"
CONFIG_TEMPLATE="$PLUGIN_ROOT/templates/config.yaml.template"

# Ensure .spec-drive exists
if [ ! -d "$SPEC_DRIVE_DIR" ]; then
  echo "❌ ERROR: .spec-drive/ not found. Run init-directories.sh first." >&2
  exit 1
fi

echo "================================================"
echo "  Generating config.yaml"
echo "================================================"
echo "Project: $PROJECT_ROOT"
echo ""

# Auto-detect project name
detect_project_name() {
  local name=""

  # Try package.json
  if [ -f "$PROJECT_ROOT/package.json" ]; then
    if command -v jq &> /dev/null; then
      name=$(jq -r '.name // empty' "$PROJECT_ROOT/package.json" 2>/dev/null || echo "")
    else
      name=$(grep '"name"' "$PROJECT_ROOT/package.json" | head -1 | sed 's/.*"name"[^"]*"\([^"]*\)".*/\1/' || echo "")
    fi
  fi

  # Try Cargo.toml
  if [ -z "$name" ] && [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    name=$(grep '^name = ' "$PROJECT_ROOT/Cargo.toml" | head -1 | sed 's/.*name = "\([^"]*\)".*/\1/' || echo "")
  fi

  # Try pyproject.toml
  if [ -z "$name" ] && [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    name=$(grep '^name = ' "$PROJECT_ROOT/pyproject.toml" | head -1 | sed 's/.*name = "\([^"]*\)".*/\1/' || echo "")
  fi

  # Try git remote
  if [ -z "$name" ] && [ -d "$PROJECT_ROOT/.git" ]; then
    local remote_url=$(git -C "$PROJECT_ROOT" remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
      name=$(basename "$remote_url" .git 2>/dev/null || echo "")
    fi
  fi

  # Fallback to directory name
  if [ -z "$name" ]; then
    name=$(basename "$PROJECT_ROOT")
  fi

  echo "$name"
}

# Auto-detect stack profile
detect_stack_profile() {
  local stack="generic"

  # TypeScript/Node.js project
  if [ -f "$PROJECT_ROOT/package.json" ] && [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    stack="typescript"
  # JavaScript/Node.js project
  elif [ -f "$PROJECT_ROOT/package.json" ]; then
    stack="nodejs"
  # Python project
  elif [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/setup.py" ]; then
    stack="python"
  # Rust project
  elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    stack="rust"
  # Go project
  elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    stack="go"
  fi

  echo "$stack"
}

# Detect test command
detect_test_command() {
  local cmd="echo 'No tests configured'"

  if [ -f "$PROJECT_ROOT/package.json" ]; then
    if grep -q '"test"' "$PROJECT_ROOT/package.json"; then
      cmd="npm test"
    fi
  elif [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
    cmd="pytest"
  elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    cmd="cargo test"
  elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    cmd="go test ./..."
  fi

  echo "$cmd"
}

# Detect lint command
detect_lint_command() {
  local cmd="echo 'No linting configured'"

  if [ -f "$PROJECT_ROOT/package.json" ]; then
    if grep -q '"lint"' "$PROJECT_ROOT/package.json"; then
      cmd="npm run lint"
    elif [ -f "$PROJECT_ROOT/.eslintrc.js" ] || [ -f "$PROJECT_ROOT/.eslintrc.json" ]; then
      cmd="npx eslint ."
    fi
  elif [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/.flake8" ]; then
    cmd="flake8"
  elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    cmd="cargo clippy"
  elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    cmd="golangci-lint run"
  fi

  echo "$cmd"
}

# Detect typecheck command
detect_typecheck_command() {
  local cmd="echo 'No type checking configured'"

  if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then
    cmd="npx tsc --noEmit"
  elif [ -f "$PROJECT_ROOT/pyproject.toml" ] && grep -q "mypy" "$PROJECT_ROOT/pyproject.toml"; then
    cmd="mypy ."
  fi

  echo "$cmd"
}

# Auto-detect configuration values
echo "🔍 Auto-detecting project configuration..."

PROJECT_NAME=$(detect_project_name)
STACK_PROFILE=$(detect_stack_profile)
TEST_CMD=$(detect_test_command)
LINT_CMD=$(detect_lint_command)
TYPECHECK_CMD=$(detect_typecheck_command)

echo "  📝 PROJECT_NAME: $PROJECT_NAME"
echo "  📝 STACK_PROFILE: $STACK_PROFILE"
echo "  📝 TEST_CMD: $TEST_CMD"
echo "  📝 LINT_CMD: $LINT_CMD"
echo "  📝 TYPECHECK_CMD: $TYPECHECK_CMD"
echo ""

# Generate config.yaml
echo "📝 Generating config.yaml..."

cat > "$CONFIG_FILE" << EOF
# .spec-drive/config.yaml
# spec-drive configuration for this project

project:
  name: "$PROJECT_NAME"
  version: "0.1.0"
  stack_profile: "$STACK_PROFILE"

behavior:
  mode: "strict-concise"
  gates_enabled: true
  auto_commit: false

autodocs:
  enabled: true
  update_frequency: "stage-boundary"
  preserve_manual_sections: true

workflows:
  enabled:
    - "app-new"
    - "feature"

tools:
  test_command: "$TEST_CMD"
  lint_command: "$LINT_CMD"
  typecheck_command: "$TYPECHECK_CMD"

# Quality gate enforcement
gates:
  gate_1_specify:
    enabled: true
    checks:
      - spec_file_exists
      - no_clarification_markers
      - success_criteria_defined
  gate_2_implement:
    enabled: true
    checks:
      - acceptance_criteria_defined
      - criteria_testable
  gate_3_verify:
    enabled: true
    checks:
      - tests_pass
      - spec_tags_in_code
      - spec_tags_in_tests
      - lint_clean
  gate_4_done:
    enabled: true
    checks:
      - no_shortcuts
      - traceability_complete
      - docs_updated
      - dirty_flag_cleared

# Generated by spec-drive
# Last updated: $(date +%Y-%m-%d)
EOF

echo "  ✅ Created $CONFIG_FILE"

# Validate against schema (if yq available)
SCHEMA_FILE="$SPEC_DRIVE_DIR/schemas/v0.1/config-schema.json"
if command -v yq &> /dev/null && [ -f "$SCHEMA_FILE" ]; then
  echo "✅ Validating against schema..."
  # Note: yq doesn't validate against JSON schema, but we can at least check it's valid YAML
  yq eval '.' "$CONFIG_FILE" > /dev/null 2>&1 && echo "  ✅ config.yaml is valid YAML" || echo "  ⚠️  config.yaml may have syntax errors"
fi

echo ""
echo "================================================"
echo "  config.yaml generated successfully!"
echo "================================================"
echo ""

exit 0
