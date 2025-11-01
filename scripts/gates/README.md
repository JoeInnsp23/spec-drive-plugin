# Quality Gate Scripts

Standalone quality gate scripts for spec-drive workflows.

## Overview

Four quality gates enforce quality standards at each workflow stage:

| Gate | Stage | Purpose | Key Checks |
|------|-------|---------|------------|
| **Gate 1** | Discover | Requirements documented | Spec structure, ID, title, description |
| **Gate 2** | Specify | Acceptance criteria defined | ACs exist, no clarity markers, API contracts |
| **Gate 3** | Implement | Code quality enforced | Tests pass, lint pass, type-check pass, @spec tags present, no shortcuts |
| **Gate 4** | Verify | Traceability complete | No shortcuts, traceability index, code/test traces, docs updated |

## Usage

### Manual Execution

```bash
# Run gate for current workflow stage
cd /path/to/project
/path/to/spec-drive-plugin/scripts/gates/gate-1-discover.sh

# Output:
# ========================================
#   Quality Gate 1: Discover
# ========================================
#
# Check 1: Spec file is valid YAML... ✓
# Check 2: Spec has ID... ✓ (AUTH-001)
# Check 3: Spec has title... ✓
# Check 4: Spec has description... ✓ (145 chars)
# Check 5: Spec has status... ✓ (draft)
#
# ========================================
#   Gate 1 Results
# ========================================
#
# Checks passed: 5
# Checks failed: 0
#
# ✓ Gate 1 PASSED
#
# Ready to advance to Specify stage
# Run: /spec-drive:feature advance
```

### Exit Codes

- **0**: Gate passed, can advance to next stage
- **1**: Gate failed, issues must be fixed

### State Management

Gates automatically set `can_advance` flag in `.spec-drive/state.yaml`:

```yaml
# After passing gate
can_advance: true

# After failing gate
can_advance: false
```

## Configuration

Gates read project commands from `.spec-drive/config.yaml`:

```yaml
commands:
  test: "npm test"
  lint: "npm run lint"
  typecheck: "npx tsc --noEmit"
```

**Fallback:** If not configured, gates auto-detect from `package.json`.

## Gate Details

### Gate 1: Discover

**When**: After defining initial requirements  
**Validates**:
- Spec file is valid YAML
- Spec has `id` field
- Spec has `title` field
- Spec has `description` (≥20 characters)
- Spec has `status` field

**Example Failure**:
```
Check 4: Spec has description... ✗
  Description too short (8 chars, min 20)
  Add more detail to the description field
```

### Gate 2: Specify

**When**: After defining acceptance criteria  
**Validates**:
- Acceptance criteria exist (≥1)
- All criteria have content (non-empty)
- No clarity markers (`[NEEDS CLARIFICATION]`, `[TBD]`, `[TODO]`, `[FIXME]`)
- API contracts defined if spec mentions APIs
- Test scenarios defined (soft warning)
- Non-functional requirements considered (soft warning)

**Example Failure**:
```
Check 3: No clarity markers... ✗
  Found clarity markers in spec:
    5:[NEEDS CLARIFICATION] on error handling
    12:[TBD] performance requirements
```

### Gate 3: Implement

**When**: After implementing code and tests  
**Validates**:
- `@spec SPEC-ID` tags present in code files
- `@spec SPEC-ID` tags present in test files
- Tests pass (`npm test` or configured command)
- Lint passes (`npm run lint` or configured command)
- Type-check passes (TypeScript projects)
- No `TODO` markers in source code
- No `console.log` in production code

**Example Failure**:
```
Check 6: No TODO markers... ✗
  Found 3 TODO markers:
    src/auth.ts:42:  // TODO: implement error handling
    src/user.ts:18:  // TODO: add validation
    src/db.ts:95:    // TODO: add retry logic
```

### Gate 4: Verify

**When**: Before completing feature  
**Validates**:
- No `TODO` markers anywhere
- No `console.log` in production code
- Traceability index exists (`.spec-drive/index.yaml`)
- Spec has code traces in index
- Spec has test traces in index
- Documentation updated (recent commits or changes)
- Spec status appropriate (`implemented` or `done`)
- Acceptance criteria reviewed (manual verification)

**Example Failure**:
```
Check 4: Code traces exist... ✗
  No code traces for AUTH-001
  Add @spec AUTH-001 tags to code
```

## Integration with Workflows

Gates are designed to be called from workflow stage scripts:

```bash
# In scripts/workflows/feature/specify.sh

# Run gate before advancing
if "$PLUGIN_ROOT/scripts/gates/gate-2-specify.sh"; then
  echo "Gate 2 passed, ready to advance"
else
  echo "Gate 2 failed, fix issues before advancing"
  exit 1
fi
```

## Troubleshooting

### "yq not installed" Error

Gates require `yq` for YAML processing:

```bash
# Install yq
brew install yq           # macOS
sudo apt install yq        # Ubuntu
# or download from https://github.com/mikefarah/yq
```

### Tests Hang or Fail

If using `npm test`, ensure tests don't wait for input:

```json
{
  "scripts": {
    "test": "jest --ci --passWithNoTests"
  }
}
```

### False Positives for console.log

Gate 3 and 4 exclude test files from console.log checks:

- Excluded: `tests/`, `test/`, `*.test.*`, `*.spec.*`
- To exclude more: modify grep exclusion patterns

## Performance

Gates are optimized for speed:
- **Gate 1**: <50ms (YAML validation only)
- **Gate 2**: <100ms (spec content checks)
- **Gate 3**: 2-10s (depends on test/lint/typecheck duration)
- **Gate 4**: <500ms (traceability checks, git log)

## Exit Strategy

To bypass a gate (not recommended):

```bash
# Manually set can_advance
yq eval ".can_advance = true" .spec-drive/state.yaml -i

# Then advance
/spec-drive:feature advance
```

**Warning**: Bypassing gates defeats quality enforcement.

## Contributing

To add a new gate check:

1. Add check logic to appropriate gate script
2. Follow existing pattern (check → pass/fail → increment counters)
3. Update this README with new check description
4. Add test case to `tests/unit/test-gates.sh`

