#!/bin/bash
# test-autodocs.sh
# End-to-end integration test for autodocs system
# Tests: scan-spec-tags → analyze-code → update-index → update-docs → posttool hook

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_file_exists() {
  local file_path="$1"
  local test_name="$2"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ -f "$file_path" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    File not found: $file_path"
    return 1
  fi
}

assert_contains() {
  local content="$1"
  local needle="$2"
  local test_name="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$content" | grep -qF "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "  ${GREEN}✓${NC} $test_name"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "  ${RED}✗${NC} $test_name"
    echo "    Expected to find: $needle"
    return 1
  fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Autodocs End-to-End Integration Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create test project
TEST_DIR=$(mktemp -d)
echo -e "${YELLOW}Test project:${NC} $TEST_DIR"
echo ""

cd "$TEST_DIR"

# ============================================================================
# Step 1: Initialize project structure
# ============================================================================
echo -e "${BLUE}Step 1: Initialize project structure${NC}"

mkdir -p src tests docs .spec-drive/specs
cat > .spec-drive/config.yaml << 'EOF'
project_name: "test-project"
version: "1.0.0"
EOF

echo -e "  ${GREEN}✓${NC} Created project structure"
echo ""

# ============================================================================
# Step 2: Create source code with @spec tags
# ============================================================================
echo -e "${BLUE}Step 2: Create source code with @spec tags${NC}"

cat > src/auth.ts << 'EOF'
// @spec AUTH-001
export class AuthService {
  // Handles user authentication

  // @spec AUTH-001
  async login(username: string, password: string): Promise<boolean> {
    return true;
  }
}

// @spec AUTH-002
export function validateToken(token: string): boolean {
  return token.length > 0;
}
EOF

cat > src/user.ts << 'EOF'
// @spec USER-001
export class UserService {
  // Manages user data

  getUser(id: string): Promise<User> {
    return Promise.resolve({ id, name: 'Test' });
  }
}

interface User {
  id: string;
  name: string;
}
EOF

echo -e "  ${GREEN}✓${NC} Created source files with @spec tags"
echo ""

# ============================================================================
# Step 3: Create test files with @spec tags
# ============================================================================
echo -e "${BLUE}Step 3: Create test files${NC}"

cat > tests/auth.test.ts << 'EOF'
// @spec AUTH-001
import { AuthService } from '../src/auth';

describe('AuthService', () => {
  // @spec AUTH-001
  it('should authenticate valid users', async () => {
    const service = new AuthService();
    const result = await service.login('user', 'pass');
    expect(result).toBe(true);
  });
});

// @spec AUTH-002
describe('validateToken', () => {
  it('should validate tokens', () => {
    expect(validateToken('abc123')).toBe(true);
  });
});
EOF

echo -e "  ${GREEN}✓${NC} Created test files with @spec tags"
echo ""

# ============================================================================
# Step 4: Create spec files
# ============================================================================
echo -e "${BLUE}Step 4: Create spec files${NC}"

cat > .spec-drive/specs/AUTH-001.yaml << 'EOF'
id: AUTH-001
title: User authentication
status: implemented
description: |
  Users can log in with username and password
acceptance_criteria:
  - Valid credentials return success
  - Invalid credentials return failure
EOF

cat > .spec-drive/specs/AUTH-002.yaml << 'EOF'
id: AUTH-002
title: Token validation
status: implemented
description: |
  Validate JWT tokens for authenticated requests
EOF

cat > .spec-drive/specs/USER-001.yaml << 'EOF'
id: USER-001
title: User data management
status: draft
description: |
  CRUD operations for user data
EOF

echo -e "  ${GREEN}✓${NC} Created spec files"
echo ""

# ============================================================================
# Step 5: Create docs with AUTO markers
# ============================================================================
echo -e "${BLUE}Step 5: Create docs with AUTO markers${NC}"

cat > docs/README.md << 'EOF'
# Test Project

## Components

<!-- AUTO:components -->
<!-- /AUTO -->

## Specifications

<!-- AUTO:specs -->
<!-- /AUTO -->
EOF

cat > docs/TRACE.md << 'EOF'
# Traceability Matrix

<!-- AUTO:matrix -->
<!-- /AUTO -->
EOF

echo -e "  ${GREEN}✓${NC} Created docs with AUTO markers"
echo ""

# ============================================================================
# Step 6: Run update-index.sh
# ============================================================================
echo -e "${BLUE}Step 6: Run update-index.sh${NC}"

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/autodocs/update-index.sh" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

assert_file_exists "$TEST_DIR/.spec-drive/index.yaml" "Creates index.yaml"

# Verify index.yaml contents
INDEX_CONTENT=$(cat "$TEST_DIR/.spec-drive/index.yaml")

assert_contains "$INDEX_CONTENT" "AuthService" "Index contains AuthService component"
assert_contains "$INDEX_CONTENT" "UserService" "Index contains UserService component"
assert_contains "$INDEX_CONTENT" "validateToken" "Index contains validateToken function"
assert_contains "$INDEX_CONTENT" "AUTH-001" "Index contains AUTH-001 spec"
assert_contains "$INDEX_CONTENT" "AUTH-002" "Index contains AUTH-002 spec"
assert_contains "$INDEX_CONTENT" "USER-001" "Index contains USER-001 spec"
assert_contains "$INDEX_CONTENT" "src/auth.ts" "Index contains source traces"
assert_contains "$INDEX_CONTENT" "tests/auth.test.ts" "Index contains test traces"

echo ""

# ============================================================================
# Step 7: Run update-docs.sh
# ============================================================================
echo -e "${BLUE}Step 7: Run update-docs.sh${NC}"

cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/autodocs/update-docs.sh" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

# Verify README.md was updated
README_CONTENT=$(cat "$TEST_DIR/docs/README.md")

assert_contains "$README_CONTENT" "AuthService" "README contains AuthService in components"
assert_contains "$README_CONTENT" "UserService" "README contains UserService in components"
assert_contains "$README_CONTENT" "AUTH-001" "README contains AUTH-001 in specs"
assert_contains "$README_CONTENT" "AUTH-002" "README contains AUTH-002 in specs"
assert_contains "$README_CONTENT" "implemented" "README contains spec status"

# Verify TRACE.md was updated
TRACE_CONTENT=$(cat "$TEST_DIR/docs/TRACE.md")

assert_contains "$TRACE_CONTENT" "AUTH-001" "TRACE contains AUTH-001"
assert_contains "$TRACE_CONTENT" "✅" "TRACE contains checkmarks for existing traces"
assert_contains "$TRACE_CONTENT" "❌" "TRACE contains X for missing traces"

echo ""

# ============================================================================
# Step 8: Test PostToolUse hook (dirty flag)
# ============================================================================
echo -e "${BLUE}Step 8: Test PostToolUse hook${NC}"

# Create initial state.yaml
cat > .spec-drive/state.yaml << 'EOF'
dirty: false
last_update: null
EOF

# Simulate Write tool (via hook)
cd "$TEST_DIR"
TOOL_NAME="Write" "$PLUGIN_ROOT/hooks-handlers/posttool.sh" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

STATE_CONTENT=$(cat "$TEST_DIR/.spec-drive/state.yaml")
assert_contains "$STATE_CONTENT" "dirty: true" "PostToolUse sets dirty flag"

echo ""

# ============================================================================
# Step 9: Verify traceability links
# ============================================================================
echo -e "${BLUE}Step 9: Verify traceability links${NC}"

# Check that AUTH-001 has both code and test traces
TESTS_RUN=$((TESTS_RUN + 1))
CODE_COUNT=$(yq eval '.specs[] | select(.id == "AUTH-001") | .trace.code | length' "$TEST_DIR/.spec-drive/index.yaml" 2>/dev/null || echo "0")
if [[ $CODE_COUNT -gt 0 ]]; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} AUTH-001 has code traces ($CODE_COUNT traces)"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} AUTH-001 has code traces"
fi

TESTS_RUN=$((TESTS_RUN + 1))
if yq eval '.specs[] | select(.id == "AUTH-001") | .trace.tests | length' "$TEST_DIR/.spec-drive/index.yaml" | grep -q "[12]"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} AUTH-001 has test traces"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} AUTH-001 has test traces"
fi

# Check that USER-001 has code but no tests
TESTS_RUN=$((TESTS_RUN + 1))
if yq eval '.specs[] | select(.id == "USER-001") | .trace.code | length' "$TEST_DIR/.spec-drive/index.yaml" | grep -q "1"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} USER-001 has code traces"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} USER-001 has code traces"
fi

TESTS_RUN=$((TESTS_RUN + 1))
if yq eval '.specs[] | select(.id == "USER-001") | .trace.tests | length' "$TEST_DIR/.spec-drive/index.yaml" | grep -q "0"; then
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "  ${GREEN}✓${NC} USER-001 has no test traces (expected)"
else
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "  ${RED}✗${NC} USER-001 has no test traces (expected)"
fi

echo ""

# ============================================================================
# Step 10: Test incremental updates
# ============================================================================
echo -e "${BLUE}Step 10: Test incremental updates${NC}"

# Add a new component
cat > "$TEST_DIR/src/payment.ts" << 'EOF'
// @spec PAY-001
export class PaymentService {
  processPayment(amount: number): Promise<boolean> {
    return Promise.resolve(true);
  }
}
EOF

# Add new spec
cat > "$TEST_DIR/.spec-drive/specs/PAY-001.yaml" << 'EOF'
id: PAY-001
title: Payment processing
status: draft
description: Process payments
EOF

# Re-run update-index
cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/autodocs/update-index.sh" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

INDEX_CONTENT=$(cat "$TEST_DIR/.spec-drive/index.yaml")
assert_contains "$INDEX_CONTENT" "PaymentService" "Incremental update adds new component"
assert_contains "$INDEX_CONTENT" "PAY-001" "Incremental update adds new spec"

# Re-run update-docs
cd "$TEST_DIR"
"$PLUGIN_ROOT/scripts/autodocs/update-docs.sh" >/dev/null 2>&1
cd "$PLUGIN_ROOT"

README_CONTENT=$(cat "$TEST_DIR/docs/README.md")
assert_contains "$README_CONTENT" "PaymentService" "Incremental docs update adds new component"

echo ""

# ============================================================================
# Cleanup
# ============================================================================
cd "$PLUGIN_ROOT"
rm -rf "$TEST_DIR"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Total:  $TESTS_RUN"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All autodocs integration tests passed!${NC}"
  echo ""
  echo -e "${GREEN}Validated:${NC}"
  echo "  - Component detection (classes, functions)"
  echo "  - @spec tag scanning and tracing"
  echo "  - Index generation (.spec-drive/index.yaml)"
  echo "  - AUTO section regeneration in docs"
  echo "  - PostToolUse hook dirty flag"
  echo "  - Traceability matrix (code → tests → docs)"
  echo "  - Incremental updates"
  exit 0
else
  echo -e "${RED}✗ Some autodocs integration tests failed${NC}"
  exit 1
fi
