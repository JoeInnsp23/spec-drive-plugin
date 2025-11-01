# ADR-002: SessionStart Hook Auto-Injection

**Date:** 2025-11-01
**Status:** Accepted
**Deciders:** Core Team
**Related:** [DECISIONS.md](../DECISIONS.md) Decision #9, [TDD.md](../TDD.md) Section 5.1

---

## Context

spec-drive's behavior optimization system (System 1) requires injecting strict-concise behavior rules into every Claude Code session. The behavior content must be loaded into Claude's context to enforce:

- Quality gates (stop-the-line on errors)
- Extreme planning (TodoWrite discipline)
- Parallel delegation (multiple Task() calls)
- Docs-first enforcement
- Zero shortcuts (no TODO/console.log/placeholders)

### User Experience Goal

**Developers should not need to manually activate behavior enforcement.** It should "just work" from the moment they start using spec-drive.

### Activation Strategies Evaluated

**Option A: Manual activation (user runs command)**
- User runs `/spec-drive:activate-behavior` to load rules
- ❌ Users will forget to run it
- ❌ Inconsistent enforcement (some sessions with, some without)
- ❌ Adds friction to workflow

**Option B: Opt-in via config**
- `config.yaml`: `behavior.enabled: true/false`
- User must explicitly enable in config
- ❌ Defaults matter - users won't change default
- ❌ If default=false, defeats purpose (no adoption)
- ❌ If default=true, still requires awareness

**Option C: SessionStart hook auto-injection**
- Hook runs automatically when Claude Code session starts
- Injects behavior content into Claude's context
- ✅ Always active, no user action required
- ✅ Consistent enforcement across all sessions
- ✅ Follows "explanatory-output-style" pattern from strict-concise plugin
- ⚠️ No opt-out (could be seen as intrusive)

**Option D: PostToolUse injection (after first tool use)**
- Inject behavior after user's first action
- ❌ Too late - first action already unconstrained
- ❌ Inconsistent (what if first action has issues?)

---

## Decision

**We will use SessionStart hook for automatic behavior injection.**

Behavior content will be injected at the start of every Claude Code session, before any user interaction.

### Implementation

**Hook Registration:**

```json
// spec-drive/hooks/hooks.json
{
  "hooks": {
    "SessionStart": {
      "handler": "spec-drive/hooks/handlers/session-start.sh",
      "description": "Inject strict-concise behavior for all sessions",
      "version": "0.1.0"
    }
  }
}
```

**Hook Handler:**

```bash
#!/bin/bash
# spec-drive/hooks/handlers/session-start.sh
# Purpose: Inject behavior optimization content into Claude Code session
# Inputs: None
# Outputs: Markdown content to stdout (consumed by Claude Code)

# Performance target: <100ms
cat spec-drive/assets/strict-concise-behavior.md
```

**Behavior Content:**

`spec-drive/assets/strict-concise-behavior.md` contains the full strict-concise prompt from the strict-concise plugin, including:
- Quality gate rules
- Extreme planning format
- Delegation patterns
- Docs-first enforcement
- Zero shortcuts policy

### Timing

- **Trigger:** Claude Code session initialization
- **Execution:** Before first user message
- **Performance:** <100ms (simple cat operation)
- **Failure mode:** If hook fails, session continues without behavior (degraded but not blocked)

---

## Consequences

### Positive

1. **Always-on enforcement**
   - Every session gets behavior rules automatically
   - No user action required
   - Consistent quality across all development

2. **Zero configuration**
   - Works out-of-the-box after plugin installation
   - No setup steps, no activation commands
   - Follows principle of least surprise

3. **Proven pattern**
   - Follows explanatory-output-style pattern from strict-concise plugin
   - SessionStart hook is standard Claude Code mechanism
   - Well-tested approach

4. **Separation of concerns**
   - Behavior injection separate from workflow logic
   - Can update behavior content without changing workflows
   - Clear responsibility: hook injects, agent enforces

### Negative

1. **No opt-out (v0.1)**
   - Users cannot disable behavior enforcement
   - Could be seen as opinionated/intrusive
   - **Mitigation:** v0.2 will add `config.yaml` opt-out
   - **Rationale:** v0.1 aims to prove behavior value, opt-out premature

2. **Context consumption**
   - Behavior prompt consumes ~2-3KB of context per session
   - **Mitigation:** Acceptable cost for benefits
   - **Optimization:** Future versions could compress/summarize

3. **Startup latency**
   - Adds ~100ms to session start time
   - **Mitigation:** Imperceptible to users
   - **Optimization:** Cat operation is minimal overhead

4. **Single behavior profile**
   - v0.1 only supports strict-concise behavior (no alternatives)
   - **Mitigation:** Generic profile appropriate for v0.1
   - **Future:** v0.2 adds stack-specific profiles (TypeScript, Python, etc.)

### Trade-offs

**Chose automatic over explicit:**
- Automatic activation ensures consistent enforcement
- Risk: users may not understand why Claude behaves differently
- **Mitigation:** Clear documentation, onboarding guide

**Chose always-on over configurable:**
- v0.1 focuses on proving behavior value
- Configuration adds complexity without clear benefit yet
- **Future:** Add opt-out in v0.2 after gathering feedback

---

## Alternatives Considered

### Manual Activation (Rejected)

```bash
# User must run this every session
/spec-drive:activate-behavior
```

**Why rejected:**
- Users will forget → inconsistent enforcement
- Adds friction to workflow
- Defeats purpose (behavior should be invisible infrastructure)

### Config-Based Opt-In (Rejected)

```yaml
# config.yaml
behavior:
  enabled: true  # User must set this
```

**Why rejected:**
- If default=false: no adoption (users won't enable)
- If default=true: same as auto-injection, but with config complexity
- v0.1 should be opinionated (prove value first, add flexibility later)

### First-Tool-Use Injection (Rejected)

Hook fires after user's first tool use, injects behavior mid-session.

**Why rejected:**
- First action unconstrained (defeats purpose)
- Weird UX (behavior appears after user starts work)
- No clear benefit over SessionStart

### Slash Command Expansion (Rejected)

Expand behavior content in every slash command (`/spec-drive:feature`, etc.).

**Why rejected:**
- Duplicates content (every command repeats behavior)
- Wastes context (behavior repeated N times per session)
- SessionStart is cleaner (inject once)

---

## Implementation Notes

### Hook Performance

**Target:** <100ms execution time

**Measurement:**
```bash
time spec-drive/hooks/handlers/session-start.sh
# Real: 0m0.023s (well under target)
```

**Optimization:**
- Use `cat` (native, minimal overhead)
- No parsing, no processing, just output
- Behavior file pre-generated (not dynamically created)

### Error Handling

**Failure modes:**

1. **Behavior file missing:**
   ```bash
   if [ ! -f "spec-drive/assets/strict-concise-behavior.md" ]; then
     echo "⚠️ WARNING: Behavior file not found, skipping injection"
     exit 0  # Soft fail (session continues)
   fi
   ```

2. **Hook script not executable:**
   - Installation script must `chmod +x hooks/handlers/*.sh`
   - Pre-flight check warns if not executable

3. **Hook timeout (>500ms):**
   - Claude Code enforces timeout
   - Hook must complete quickly
   - **Mitigation:** Simple cat operation, no risk

### Behavior Content Updates

**Update workflow:**

1. Update `spec-drive/assets/strict-concise-behavior.md`
2. New sessions automatically get updated content
3. Existing sessions retain old behavior (until restart)

**No restart required:** Plugin file changes take effect on next session.

---

## Security Considerations

**Injection safety:**

- Hook outputs markdown (safe, no code execution)
- Content is static (not user-controlled)
- No input validation needed (no user input)

**Privilege:**

- Hook runs with user permissions (not elevated)
- Reads plugin files only (no system access)
- Cannot modify project files

---

## Related Decisions

- **ADR-003:** Stage-boundary autodocs (PostToolUse hook)
- **ADR-004:** Four quality gates (enforced by injected behavior)
- **DECISIONS.md Decision #10:** Stage-boundary autodocs updates

---

## Future Evolution (v0.2+)

### Opt-Out Support

```yaml
# config.yaml
behavior:
  mode: "strict-concise"  # or "off", "advisory"
  gates_enabled: true
```

If `mode: "off"`, SessionStart hook exits early (no injection).

### Stack-Specific Profiles

```yaml
# config.yaml
project:
  stack_profile: "typescript-react"  # vs "python-fastapi", "generic"

behavior:
  mode: "strict-concise-typescript"  # Stack-specific behavior
```

Different behavior files for different stacks.

### Behavior Versioning

```
spec-drive/assets/
├── strict-concise-behavior-v1.md
├── strict-concise-behavior-v2.md
└── strict-concise-behavior.md → v2.md  # Symlink
```

Allow users to pin behavior version in config.

---

## References

- [Claude Code Hooks Documentation](https://docs.claude.com/plugins/hooks)
- [strict-concise Plugin](https://github.com/...) - Original behavior source
- [TDD.md Section 5.1](../TDD.md) - Behavior system architecture
- [TDD.md Section 8.1.1](../TDD.md) - Hook system integration

---

**Review Notes:**
- Approved by core team 2025-11-01
- Implementation: Phase 1 (hook system)
- First use: Session initialization
- Performance validated: <100ms (23ms measured)
