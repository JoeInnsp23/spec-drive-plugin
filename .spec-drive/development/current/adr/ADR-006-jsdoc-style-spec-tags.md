# ADR-006: JSDoc-Style @spec Tags

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #11, [TDD.md](../TDD.md) Section 5.3

---

## Context

spec-drive's traceability system connects specs → code → tests → docs. The system must mark code and test files with spec identifiers so autodocs can:

1. Find which code implements which spec
2. Find which tests validate which spec
3. Generate `index.yaml` traces

### Traceability Requirements

- **Language-agnostic:** Works for TypeScript, Python, Go, Rust, etc.
- **Lint-compatible:** Doesn't break linters, type checkers
- **Tool-friendly:** Easy to detect via grep/regex
- **Human-readable:** Developers understand meaning
- **Non-invasive:** Doesn't affect runtime behavior

### Tag Format Options Evaluated

**Option A: Custom decorators**

```typescript
@Spec("AUTH-001")
class AuthService { }
```

**Pros:**
- Clean syntax
- Type-safe (in TypeScript)

**Cons:**
- ❌ Not universal (TypeScript/Python only, not available in all languages)
- ❌ May affect runtime (decorators can have side effects)
- ❌ Requires compilation support
- ❌ Not available in Go, Rust, C++, etc.

**Option B: Custom comment syntax**

```typescript
// SPEC: AUTH-001
class AuthService { }
```

**Pros:**
- Simple, universal
- Language-agnostic (all languages have comments)

**Cons:**
- ❌ Not standardized (custom syntax, linters may not understand)
- ❌ Collision risk (SPEC could mean other things)
- ❌ No existing tool support

**Option C: JSDoc-style tags**

```typescript
/** @spec AUTH-001 */
class AuthService { }
```

**Pros:**
- ✅ Standardized (JSDoc convention widely understood)
- ✅ Lint-compatible (linters already handle JSDoc)
- ✅ Tool-friendly (easy grep: `@spec SPEC-ID`)
- ✅ Language-agnostic pattern (adapts to each language's doc comment style)
- ✅ Human-readable (clear intent)
- ✅ Non-invasive (pure comment, no runtime effect)

**Cons:**
- ⚠️ Not official JSDoc tag (custom tag)
- **Mitigation:** Many tools support custom JSDoc tags

**Option D: Pragma comments**

```typescript
// #pragma spec AUTH-001
class AuthService { }
```

**Pros:**
- Standardized pragma syntax

**Cons:**
- ❌ Typically for compiler directives, not documentation
- ❌ May confuse developers (pragmas usually affect compilation)
- ❌ Not commonly used for metadata

---

## Decision

**We will use JSDoc-style `@spec` tags for traceability.**

### Tag Format (Language-Specific)

**TypeScript / JavaScript:**

```typescript
/** @spec AUTH-001 */
export class AuthService {
  /** @spec AUTH-001 */
  login(credentials: Credentials): Promise<User> {
    // implementation
  }
}

// Test file
/** @spec AUTH-001 */
describe('AuthService', () => {
  /** @spec AUTH-001 */
  it('should authenticate valid credentials', () => {
    // test
  });
});
```

**Python:**

```python
"""@spec AUTH-001"""
class AuthService:
    """@spec AUTH-001"""
    def login(self, credentials: dict) -> User:
        """Authenticate user with credentials."""
        pass

# Test file
"""@spec AUTH-001"""
def test_login_valid_credentials():
    """Test authentication with valid credentials."""
    pass
```

**Go:**

```go
// @spec AUTH-001
type AuthService struct {}

// @spec AUTH-001
func (s *AuthService) Login(credentials Credentials) (*User, error) {
    // implementation
}

// Test file
// @spec AUTH-001
func TestLogin(t *testing.T) {
    // test
}
```

**Rust:**

```rust
/// @spec AUTH-001
pub struct AuthService;

/// @spec AUTH-001
impl AuthService {
    pub fn login(&self, credentials: Credentials) -> Result<User, Error> {
        // implementation
    }
}

// Test file
/// @spec AUTH-001
#[test]
fn test_login() {
    // test
}
```

### Detection Mechanism

**Simple grep pattern:**

```bash
# Find all @spec tags in code
grep -rn "@spec AUTH-001" src/

# Output:
# src/auth/AuthService.ts:5:/** @spec AUTH-001 */
# src/auth/login.ts:12:/** @spec AUTH-001 */
```

**Used in:**
- Gate-3 verification (check @spec tags present)
- Index generation (`scripts/tools/index-docs.js`)
- Trace building (`index.yaml` population)

### Index Mapping

```yaml
# .spec-drive/index.yaml
specs:
  - id: "AUTH-001"
    title: "User authentication"
    status: "implemented"
    trace:
      code:
        - "src/auth/AuthService.ts:5"   # Line where @spec tag found
        - "src/auth/login.ts:12"
      tests:
        - "tests/auth/login.test.ts:8"  # Line where @spec tag found
        - "tests/auth/session.test.ts:15"
      docs:
        - "docs/60-features/AUTH-001.md"
```

---

## Consequences

### Positive

1. **Lint-compatible**
   - JSDoc tags already supported by linters (ESLint, TSLint)
   - No linting errors for custom `@spec` tag
   - Existing infrastructure handles gracefully

2. **Tool-friendly**
   - Simple grep pattern: `grep -rn "@spec SPEC-ID"`
   - No complex parsing required
   - Works in CI/CD scripts, pre-commit hooks

3. **Language-agnostic pattern**
   - `/** @spec */` in TypeScript/JavaScript
   - `"""@spec"""` in Python
   - `// @spec` in Go
   - `/// @spec` in Rust
   - Adapts to each language's doc comment convention

4. **Human-readable**
   - Clear intent: "this code implements SPEC-ID"
   - Familiar format (JSDoc widely known)
   - Self-documenting (tag shows relationship)

5. **Non-invasive**
   - Pure comment (no runtime effect)
   - Doesn't affect compilation, bundling, minification
   - Zero performance impact

6. **Editor support**
   - IDEs already highlight JSDoc comments
   - Can add custom rules for `@spec` validation
   - Autocomplete possible (via editor extensions)

### Negative

1. **Not official JSDoc tag**
   - `@spec` is custom (not in JSDoc standard)
   - Some tools may warn about unknown tag
   - **Mitigation:** Most tools support custom tags, can configure to allow

2. **Manual tagging required**
   - Developer must remember to add tags
   - No auto-injection in v0.1
   - ❌ Risk: developer forgets → no traceability
   - **Mitigation:** Gate-3 enforces tags (cannot advance without)

3. **Granularity ambiguity**
   - Tag on class? Function? File? All?
   - ❌ No strict rules (developer discretion)
   - **Mitigation:** Best practice guidelines (tag at meaningful boundaries)

4. **Duplication across files**
   - Large feature → many files → many tags
   - ❌ Feels repetitive (same tag in 10+ files)
   - **Mitigation:** This is the point (explicit traceability)

### Trade-offs

**Chose familiarity over novelty:**
- JSDoc pattern vs custom syntax
- Benefit: Developers already understand JSDoc

**Chose simplicity over automation:**
- Manual tags vs auto-injection
- Benefit: Explicit, clear, no magic

**Chose language-agnostic over language-specific:**
- Same pattern across languages vs decorators (TypeScript-only)
- Benefit: Consistent approach regardless of stack

---

## Alternatives Considered

### Decorators (TypeScript-Only) - Rejected

```typescript
@Spec("AUTH-001")
class AuthService { }
```

**Why rejected:**
- Not available in all languages (Python has decorators, Go/Rust don't)
- May affect runtime (decorators can execute)
- Requires compilation support
- Not language-agnostic

### Custom Comment Syntax - Rejected

```typescript
// SPEC: AUTH-001
class AuthService { }
```

**Why rejected:**
- Not standardized (custom invention)
- Collision risk (SPEC might mean other things)
- No existing tool support
- JSDoc pattern better established

### Pragma Comments - Rejected

```typescript
// #pragma spec AUTH-001
class AuthService { }
```

**Why rejected:**
- Pragmas typically for compiler directives
- May confuse developers (pragmas usually affect compilation)
- Not commonly used for metadata
- JSDoc more intuitive for documentation

### Annotation Comments (Java-style) - Rejected

```java
@interface Spec {
    String value();
}

@Spec("AUTH-001")
class AuthService { }
```

**Why rejected:**
- Requires language support (not available in all languages)
- Heavyweight (need interface definition)
- Affects runtime (annotations can be reflective)
- Overkill for simple traceability

---

## Implementation Notes

### Tag Placement Guidelines

**Best practices:**

1. **Tag entry points:**
   ```typescript
   /** @spec AUTH-001 */
   export class AuthService {  // ✅ Tag the class
     login() { }               // Don't tag every method
   }
   ```

2. **Tag test suites:**
   ```typescript
   /** @spec AUTH-001 */
   describe('AuthService', () => {  // ✅ Tag the describe
     it('test 1', () => { });       // Don't tag every test
     it('test 2', () => { });
   });
   ```

3. **Tag significant functions:**
   ```typescript
   /** @spec AUTH-001 */
   export function login(creds) { }  // ✅ Tag exported function
   ```

4. **Don't over-tag:**
   ```typescript
   // ❌ Too much
   /** @spec AUTH-001 */
   const helper = () => { };  // Internal helper, don't tag
   ```

**Goal:** Tag enough for traceability, not everything.

### Detection Script

```bash
#!/bin/bash
# scripts/tools/detect-spec-tags.sh
# Purpose: Find all @spec tags in codebase
# Usage: detect-spec-tags.sh SPEC-ID

SPEC_ID=$1

# Search code
CODE_TAGS=$(grep -rn "@spec $SPEC_ID" src/ | cut -d: -f1-2)

# Search tests
TEST_TAGS=$(grep -rn "@spec $SPEC_ID" tests/ | cut -d: -f1-2)

echo "Code files:"
echo "$CODE_TAGS"
echo ""
echo "Test files:"
echo "$TEST_TAGS"
```

### Linter Configuration

**ESLint (TypeScript/JavaScript):**

```json
// .eslintrc.json
{
  "rules": {
    "valid-jsdoc": ["error", {
      "requireReturn": false,
      "requireParamDescription": false,
      "preferType": {
        "spec": "spec"  // Allow @spec tag
      }
    }]
  }
}
```

**Python (Pylint):**

```ini
# .pylintrc
[BASIC]
# Allow docstrings with @spec tags
good-names=spec
```

### Editor Support (VSCode)

```json
// .vscode/settings.json
{
  "cSpell.words": [
    "spec"  // Don't spell-check @spec
  ],
  "jsdoc.tags": {
    "spec": {
      "description": "Links code to spec-drive specification",
      "example": "@spec AUTH-001"
    }
  }
}
```

---

## Related Decisions

- **ADR-004:** Four quality gates (gate-3 verifies @spec tags)
- **ADR-001:** YAML format for specs (specs that @spec tags reference)
- **DECISIONS.md Decision #12:** Four quality gates

---

## Future Evolution (v0.2+)

### Auto-Injection

```javascript
// AI-based auto-injection during implementation
// Analyze code, detect spec relationship, inject tags automatically
const code = readFile('src/auth/login.ts');
const spec = inferSpec(code);  // AI inference
const tagged = injectSpecTag(code, spec);  // Add /** @spec SPEC-ID */
writeFile('src/auth/login.ts', tagged);
```

**Benefit:** Reduces manual work
**Risk:** Incorrect inference (tags wrong spec)

### Multi-Spec Tags

```typescript
/** @spec AUTH-001 @spec SESSION-002 */
class AuthService {
  // Implements both AUTH-001 and SESSION-002
}
```

Support code that implements multiple specs.

### Tag Validation

```bash
# Pre-commit hook: validate @spec tags reference existing specs
for tag in $(grep -rh "@spec [A-Z0-9-]+" src/ tests/ | awk '{print $2}'); do
  if [ ! -f ".spec-drive/specs/$tag.yaml" ]; then
    echo "❌ Invalid @spec tag: $tag (no spec file found)"
    exit 1
  fi
done
```

Enforce that tags reference real specs.

---

## References

- [JSDoc Documentation](https://jsdoc.app/)
- [TDD.md Section 5.3](../TDD.md) - Traceability system
- [TDD.md Section 6.5](../TDD.md) - Gate-3 @spec tag detection

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 4 (quality gates)
- Pattern: JSDoc-style, language-agnostic
- Trade-off: Familiarity + simplicity over automation
