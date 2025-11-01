# ADR-001: YAML Format for Specs

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #3, [TDD.md](../TDD.md) Section 6.7

---

## Context

spec-drive requires a structured file format for specification files (`.spec-drive/specs/SPEC-ID.yaml`). The format must support:

1. **Human-readability** - Developers will read and edit specs frequently
2. **Comments** - Design rationale and notes need to be preserved
3. **Structured data** - Acceptance criteria, dependencies, metadata
4. **Tool compatibility** - Easy to parse and validate programmatically
5. **Version control friendliness** - Clear diffs in git

### Candidate Formats Evaluated

**Option A: JSON**
- ✅ Widely supported, strict schema validation
- ❌ No comment support (defeats documentation purpose)
- ❌ Less readable (quotes, brackets, commas)
- ❌ Poor for human editing

**Option B: TOML**
- ✅ Comments supported
- ✅ Simpler than YAML for flat structures
- ❌ Less common in development tools
- ❌ Awkward for nested structures (acceptance criteria lists)
- ❌ Limited adoption compared to YAML

**Option C: YAML**
- ✅ Human-readable, clean syntax
- ✅ Full comment support
- ✅ Excellent for nested/list structures
- ✅ Widely adopted (Kubernetes, Docker Compose, GitHub Actions)
- ✅ Strong tooling ecosystem (yq, yamllint)
- ❌ Whitespace-sensitive (can cause errors)
- ❌ Multiple valid representations of same data

**Option D: Markdown with YAML frontmatter**
- ✅ Best of both worlds (structured + freeform)
- ❌ Adds complexity (two formats to parse)
- ❌ Harder to validate programmatically

---

## Decision

**We will use YAML as the spec file format.**

Spec files will be named `SPEC-ID.yaml` (e.g., `AUTH-001.yaml`) and stored in `.spec-drive/specs/`.

### Spec Structure

```yaml
id: "AUTH-001"
title: "User authentication"
status: draft  # draft | specified | implemented | verified | done
created: "2025-11-01T10:30:00Z"
updated: "2025-11-01T10:30:00Z"

summary: |
  Implement user authentication with email/password.
  Support session management and JWT tokens.

acceptance_criteria:
  - criterion: "User can log in with valid email/password"
    testable: true
  - criterion: "User receives JWT token on successful login"
    testable: true
  - criterion: "User session persists across page reloads"
    testable: true

success_criteria:
  - "Login success rate >99.9%"
  - "Authentication latency <200ms p95"

dependencies:
  - "DATABASE-001"  # User schema
  - "CRYPTO-001"    # Password hashing

risks:
  - "Brute force attacks if no rate limiting"
  - "Token expiration handling unclear"

notes: |
  # Design Notes
  - Using bcrypt for password hashing (10 rounds)
  - JWT expires after 7 days, refresh token after 30 days
  - Rate limit: 5 failed attempts per 15 minutes
```

### Validation

JSON Schema will validate all spec YAML files (see ADR-005 for schema details):
- `.spec-drive/schemas/v0.1/spec-schema.json`

### Tooling

- **Parser:** `yq` (YAML processor)
- **Validator:** JSON Schema validation via `ajv` or similar
- **Editor support:** VSCode YAML extension with schema autocomplete

---

## Consequences

### Positive

1. **Developer-friendly editing**
   - Clean, readable syntax
   - Comments preserve design rationale
   - Lists and nested structures natural to express

2. **Strong ecosystem**
   - `yq` for command-line processing (query, update, transform)
   - JSON Schema validation (same tooling as config.yaml)
   - Wide adoption means familiar format

3. **Git-friendly**
   - Clear diffs (line-based changes)
   - Merge conflicts easier to resolve than JSON
   - Comments show up in diffs

4. **Flexibility**
   - Multiline strings (`|` and `>` operators)
   - Complex nested structures (acceptance criteria with sub-fields)
   - Anchors and aliases for reuse (if needed in future)

### Negative

1. **Whitespace sensitivity**
   - Indentation errors can cause parsing failures
   - Requires discipline (use 2-space indentation consistently)
   - **Mitigation:** Editor linting (YAML extension), pre-commit hooks

2. **Multiple valid representations**
   - Same data can be written different ways (flow vs block style)
   - **Mitigation:** Enforce block style in schema, use `yq` for normalization

3. **Learning curve**
   - New users may struggle with YAML syntax initially
   - **Mitigation:** Provide templates, examples, editor autocomplete via schema

4. **Parsing overhead**
   - YAML parsing slower than JSON
   - **Mitigation:** Acceptable for spec files (small, infrequent reads)

### Trade-offs

**Chose readability over strictness:**
- YAML's flexibility (comments, multiline) more valuable than JSON's strictness
- Schema validation provides safety net for structure

**Chose familiarity over simplicity:**
- YAML more complex than TOML, but wider adoption means less friction

---

## Alternatives Considered

### JSON (Rejected)

**Why rejected:**
- No comments = cannot document design decisions inline
- Poor developer experience (editing JSON manually is tedious)
- Spec files are documentation artifacts, not just data

### TOML (Rejected)

**Why rejected:**
- Less familiar to most developers
- Awkward for nested lists (acceptance criteria with sub-fields)
- Limited tooling compared to YAML

### Markdown + YAML frontmatter (Rejected)

**Why rejected:**
- Two formats to parse (complexity)
- Harder to enforce structure
- Feature pages (`docs/60-features/SPEC-ID.md`) already provide markdown documentation
- Specs should be pure data

---

## Implementation Notes

### yq Integration

All YAML operations use `yq` (version ≥4.0):

```bash
# Read spec ID
yq eval '.id' .spec-drive/specs/AUTH-001.yaml

# Update status
yq eval '.status = "implemented"' -i .spec-drive/specs/AUTH-001.yaml

# Query acceptance criteria
yq eval '.acceptance_criteria[].criterion' .spec-drive/specs/AUTH-001.yaml
```

### Schema Validation

Specs validated against JSON Schema on:
- Spec creation (via `scripts/tools/create-spec.sh`)
- Gate-1 check (before Specify → Implement transition)
- Pre-commit hook (optional)

### Editor Support

VSCode `.vscode/settings.json`:

```json
{
  "yaml.schemas": {
    ".spec-drive/schemas/v0.1/spec-schema.json": ".spec-drive/specs/*.yaml"
  }
}
```

Provides autocomplete and inline validation.

---

## Related Decisions

- **ADR-002:** SessionStart hook auto-injection (uses YAML for config)
- **ADR-005:** JSON Schema for validation (validates YAML structure)
- **DECISIONS.md Decision #4:** `.spec-drive/` hidden structure (where specs live)

---

## References

- [YAML Specification](https://yaml.org/spec/1.2.2/)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [JSON Schema](https://json-schema.org/)
- [TDD.md Section 6.7](../TDD.md) - Template structure

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 1 (template system)
- First use: `scripts/tools/create-spec.sh` generates YAML from template
