# spec-drive v0.1 Risk Assessment

**Version:** 0.1.0
**Target Release:** TBD
**Last Updated:** 2025-11-01
**Status:** Planning Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Risk Assessment Framework](#risk-assessment-framework)
3. [Top 10 Risks](#top-10-risks)
4. [Technical Risks](#technical-risks)
5. [Process Risks](#process-risks)
6. [External Risks](#external-risks)
7. [Mitigation Strategies](#mitigation-strategies)
8. [Contingency Plans](#contingency-plans)
9. [Risk Monitoring](#risk-monitoring)
10. [Risk Register](#risk-register)

---

## Overview

### Purpose

This risk assessment identifies, analyzes, and provides mitigation strategies for risks that could impact the successful delivery of spec-drive v0.1. It serves as a living document to track risks throughout the development lifecycle.

### Scope

**In Scope:**
- Technical risks (implementation, performance, compatibility)
- Process risks (scope creep, timeline, resource constraints)
- External risks (dependencies, platform changes)
- Quality risks (bugs, test coverage, usability)

**Out of Scope:**
- Business risks (market adoption, competition)
- Organizational risks (team changes, funding)
- Legal risks (licensing, IP)

### Risk Management Approach

**Proactive:** Identify risks early, mitigate before they become issues.

**Continuous:** Monitor risks throughout development, update assessments.

**Transparent:** Communicate risks to stakeholders, document decisions.

---

## Risk Assessment Framework

### Risk Scoring

**Likelihood:**
- **1 - Rare:** <10% chance (unlikely to happen)
- **2 - Unlikely:** 10-30% chance (could happen)
- **3 - Possible:** 30-50% chance (might happen)
- **4 - Likely:** 50-70% chance (probably will happen)
- **5 - Almost Certain:** >70% chance (will happen)

**Impact:**
- **1 - Negligible:** Minor inconvenience, no delay
- **2 - Minor:** <1 week delay, workaround exists
- **3 - Moderate:** 1-2 weeks delay, requires rework
- **4 - Major:** 2-4 weeks delay, significant rework
- **5 - Critical:** >4 weeks delay, release at risk

**Risk Score:** Likelihood × Impact (1-25)

**Risk Priority:**
- **Critical (20-25):** Immediate action required
- **High (15-19):** Proactive mitigation needed
- **Medium (10-14):** Monitor and mitigate if needed
- **Low (5-9):** Accept or minimal mitigation
- **Negligible (1-4):** Accept

---

## Top 10 Risks

### Risk Matrix

| ID | Risk | Likelihood | Impact | Score | Priority |
|----|------|------------|--------|-------|----------|
| R1 | Shell script portability | 4 | 4 | 16 | High |
| R2 | Performance (large codebases) | 4 | 3 | 12 | Medium |
| R3 | State corruption | 3 | 5 | 15 | High |
| R4 | Tool dependencies | 4 | 3 | 12 | Medium |
| R5 | Scope creep | 4 | 4 | 16 | High |
| R6 | Template complexity | 3 | 3 | 9 | Low |
| R7 | Autodocs accuracy | 3 | 3 | 9 | Low |
| R8 | Gate false positives | 3 | 3 | 9 | Low |
| R9 | User experience | 3 | 4 | 12 | Medium |
| R10 | Testing coverage gaps | 3 | 4 | 12 | Medium |

---

## Technical Risks

### R1: Shell Script Portability (HIGH)

**Description:** Shell scripts may not work consistently across platforms (Linux vs macOS, bash vs zsh, different tool versions).

**Likelihood:** 4 (Likely) - Different platforms have different shells and tool versions.

**Impact:** 4 (Major) - Could block release on certain platforms, require significant rework.

**Risk Score:** 16 (High)

**Indicators:**
- Tests fail on macOS but pass on Linux
- bash 3.2 (macOS default) incompatibility issues
- Tool version differences (yq v3 vs v4)

**Mitigation Strategies:**

1. **Use POSIX-compliant syntax** (where possible)
   - Avoid bash 4+ features (associative arrays) in critical scripts
   - Use portable constructs (test vs [[, command vs builtin)

2. **Test on all platforms early** (CI matrix)
   - GitHub Actions matrix: Ubuntu 22.04, Ubuntu 24.04, macOS 13, macOS 14
   - Run tests on every commit (catch issues early)

3. **Document tool versions** (README, prerequisites)
   - Specify minimum versions (bash 3.2+, yq 4.0+, jq 1.6+)
   - Provide installation instructions per platform

4. **Platform detection and adaptation**
   ```bash
   # Detect platform
   if [[ "$OSTYPE" == "darwin"* ]]; then
     # macOS-specific logic
   else
     # Linux-specific logic
   fi
   ```

**Contingency Plan:**
- If portability issues are severe: Create platform-specific script variants
- If bash 3.2 too limiting: Require bash 4+ on macOS (via brew)
- If tools too inconsistent: Bundle vendored versions (Docker container)

**Monitoring:** Track platform test failures in CI, weekly review.

---

### R2: Performance (Large Codebases) (MEDIUM)

**Description:** Code analysis and autodocs may be too slow on large codebases (>1000 files), causing user frustration.

**Likelihood:** 4 (Likely) - Large codebases are common, performance often underestimated.

**Impact:** 3 (Moderate) - Slow performance degrades UX but doesn't block functionality.

**Risk Score:** 12 (Medium)

**Indicators:**
- Code analysis takes >60 seconds on 1000 files
- Autodocs takes >2 minutes on 1000 files
- User complaints about "slow" operations

**Mitigation Strategies:**

1. **Parallelize analysis** (process files in parallel)
   ```javascript
   // Use worker threads or Promise.all
   const analyses = await Promise.all(
     files.map(file => analyzeFile(file))
   );
   ```

2. **Cache analysis results** (skip unchanged files)
   - Cache file hash → analysis result mapping
   - Only re-analyze files that changed since last run
   - Store cache in .spec-drive/cache/

3. **Incremental index updates** (only update changed sections)
   - Track which files changed (git diff or file mtime)
   - Only regenerate index sections for changed files
   - Merge with existing index (not full rebuild)

4. **Performance budgets** (fail tests if too slow)
   - Target: Analysis <30s, Autodocs <60s (1000 files)
   - CI performance test (fail if regression >20%)

5. **Progress indicators** (show users it's working)
   - Print "Analyzing 500/1000 files..." during long operations
   - Spinner or progress bar for UX

**Contingency Plan:**
- If performance targets missed: Add --skip-analysis flag (manual mode)
- If caching complex: Start with simple file mtime check (v0.1), full caching in v0.2
- If parallelization difficult: Sequential for v0.1, parallelize in v0.2

**Monitoring:** Weekly performance benchmarks on mock 1000-file codebase.

---

### R3: State Corruption (HIGH)

**Description:** state.yaml could become corrupted (invalid YAML, missing fields, concurrent writes), breaking workflows.

**Likelihood:** 3 (Possible) - Concurrent writes or crashes during write could corrupt state.

**Impact:** 5 (Critical) - Corrupted state blocks all workflows, requires manual recovery.

**Risk Score:** 15 (High)

**Indicators:**
- state.yaml fails schema validation
- Workflow commands fail with "invalid state" errors
- User reports "workflow stuck" or "can't advance"

**Mitigation Strategies:**

1. **Atomic writes** (prevent partial writes)
   ```bash
   # Write to temp, then atomic move
   TEMP=$(mktemp)
   yq eval '.field = "value"' state.yaml > "$TEMP"
   mv "$TEMP" state.yaml  # Atomic operation
   ```

2. **Schema validation on read** (detect corruption early)
   ```bash
   # Validate before using
   ajv validate -s state-schema.json -d state.yaml || {
     echo "state.yaml corrupted, run /spec-drive:reset-state"
     exit 1
   }
   ```

3. **Automatic backups** (before every write)
   ```bash
   # Backup before modification
   cp state.yaml state.yaml.backup
   # ... modify state.yaml ...
   # If modification fails, restore backup
   ```

4. **Recovery command** (/spec-drive:reset-state)
   - Reset state to clean default (keep workflow history if possible)
   - Document recovery steps in error messages

5. **Locking for concurrent writes** (prevent race conditions)
   ```bash
   # Simple file lock
   exec 200>/tmp/spec-drive.lock
   flock -n 200 || { echo "State locked by another process"; exit 1; }
   # ... modify state ...
   flock -u 200
   ```

**Contingency Plan:**
- If corruption frequent: Add more aggressive validation (before every operation)
- If backups large: Keep only last 3 backups (rotate)
- If locking complex: Document "one workflow at a time" limitation (v0.1)

**Monitoring:** Track state validation failures in CI, add test for corruption recovery.

---

### R4: Tool Dependencies (MEDIUM)

**Description:** Users may not have required tools installed (yq, jq, ajv, node), causing setup friction.

**Likelihood:** 4 (Likely) - Many users won't have all tools pre-installed.

**Impact:** 3 (Moderate) - Frustrating setup but solvable with documentation.

**Risk Score:** 12 (Medium)

**Indicators:**
- User reports "command not found: yq"
- GitHub issues about installation problems
- Negative feedback about "too many dependencies"

**Mitigation Strategies:**

1. **Clear installation instructions** (README)
   ```markdown
   ## Prerequisites

   ### Linux (Ubuntu/Debian)
   ```bash
   sudo apt-get install -y nodejs jq
   sudo snap install yq
   npm install -g ajv-cli
   ```

   ### macOS
   ```bash
   brew install node jq yq
   npm install -g ajv-cli
   ```
   ```

2. **Dependency checker script** (spec-drive-doctor)
   ```bash
   #!/bin/bash
   # Check for required tools
   for tool in yq jq ajv node; do
     if ! command -v $tool &> /dev/null; then
       echo "❌ Missing: $tool"
       missing=true
     else
       echo "✅ Found: $tool ($(command -v $tool))"
     fi
   done

   if [ "$missing" = true ]; then
     echo "Install missing tools (see README)"
     exit 1
   fi
   ```

3. **Graceful degradation** (optional features)
   - If ajv missing: Skip schema validation (warn user)
   - If jq missing: Fall back to yq for JSON (slower but works)

4. **Bundled dependencies** (future: vendored tools)
   - Package yq, jq binaries in plugin (v0.2+)
   - Use npx for Node.js tools (no global install)

5. **Docker image** (all dependencies pre-installed)
   ```dockerfile
   FROM ubuntu:22.04
   RUN apt-get install -y nodejs jq
   RUN snap install yq
   RUN npm install -g ajv-cli
   ```

**Contingency Plan:**
- If installation too complex: Provide one-line install script (curl | bash)
- If tools unavailable: Bundle binaries (increase plugin size)
- If complaints persist: Create Docker image (recommended path)

**Monitoring:** Track installation issues in GitHub issues, survey users on setup difficulty.

---

### R5: Scope Creep (HIGH)

**Description:** Feature requests or "just one more thing" could expand scope beyond v0.1, delaying release.

**Likelihood:** 4 (Likely) - Scope creep is common in software projects.

**Impact:** 4 (Major) - Delays release, increases complexity and risk.

**Risk Score:** 16 (High)

**Indicators:**
- New features added to "v0.1" list during implementation
- Timeline slipping (weeks delay without explanation)
- "While we're at it, let's add..." conversations

**Mitigation Strategies:**

1. **Strict scope freeze** (after documentation phase)
   - PRD and TDD define v0.1 scope (immutable)
   - New features go into "v0.2 backlog"
   - Require unanimous core team approval for scope changes

2. **Definition of Done** (per phase)
   - Phase exits have clear criteria (Implementation Plan)
   - No phase exit until criteria met (no shortcuts)
   - No new features added mid-phase

3. **Change control process**
   - New feature request → log in v0.2 backlog
   - If critical for v0.1 → requires: impact analysis, timeline update, stakeholder approval
   - Document reason for scope change (decision log)

4. **Regular scope reviews** (weekly)
   - Review current work vs planned scope
   - Identify scope deviations early
   - Realign or defer features

5. **Focus on v0.1 value** (single-developer workflow)
   - v0.1 scope: Prove value for single developer
   - Multi-developer, bugfix workflow, research workflow → v0.2
   - Keep reminding team: "v0.1 first, then iterate"

**Contingency Plan:**
- If scope grows significantly: Split into v0.1a (core) and v0.1b (nice-to-have)
- If timeline slips >2 weeks: Cut features (move to v0.2)
- If quality suffers: Pause feature work, focus on stability

**Monitoring:** Weekly status check (scope vs progress), update STATUS.md.

---

## Process Risks

### R6: Template Complexity (LOW)

**Description:** Templates with AUTO markers may become too complex to maintain or understand.

**Likelihood:** 3 (Possible) - Templates can grow complex over time.

**Impact:** 3 (Moderate) - Complex templates harder to debug, but not blocking.

**Risk Score:** 9 (Low)

**Indicators:**
- Templates have deeply nested AUTO sections
- Confusion about which sections are manual vs generated
- Bugs in template variable substitution

**Mitigation Strategies:**

1. **Keep templates simple** (< 200 lines per template)
   - Limit AUTO sections to 3-5 per template
   - Prefer multiple small templates over one large template

2. **Clear AUTO markers** (with section names)
   ```markdown
   <!-- AUTO:components -->
   (generated content)
   <!-- /AUTO:components -->
   ```

3. **Template documentation** (templates/README.md)
   - Document variables ({{VAR_NAME}} → description)
   - Document AUTO sections (section-name → what it generates)
   - Provide examples (filled-in templates)

4. **Template validation** (syntax check)
   - Validate template syntax before rendering
   - Check for unclosed AUTO markers
   - Check for undefined variables

5. **Template testing** (render with mock data)
   - Test each template with sample variables
   - Verify AUTO sections regenerate correctly
   - Regression test (golden outputs)

**Contingency Plan:**
- If templates too complex: Simplify (remove advanced features)
- If maintenance burden high: Reduce template count (merge similar)
- If confusion persists: Add visual markers (AUTO sections clearly highlighted)

**Monitoring:** Review template complexity during code reviews, user feedback on docs.

---

### R7: Autodocs Accuracy (LOW)

**Description:** Code analysis may miss components, generate incorrect summaries, or produce inaccurate docs.

**Likelihood:** 3 (Possible) - Static analysis is imperfect, especially for dynamic languages.

**Impact:** 3 (Moderate) - Inaccurate docs misleading but not blocking.

**Risk Score:** 9 (Low)

**Indicators:**
- Components not detected (missing from index.yaml)
- Component summaries incorrect or generic
- Dependencies mapped incorrectly

**Mitigation Strategies:**

1. **Conservative analysis** (prefer false negatives over false positives)
   - Only detect clear patterns (class, function, export)
   - Avoid guessing (if uncertain, skip)
   - Document limitations (README: "autodocs best-effort")

2. **Manual overrides** (user can edit index.yaml)
   - Allow manual component additions
   - Preserve manual edits during regeneration
   - Document override process

3. **Validation rules** (detect suspicious results)
   - Warn if component count drops suddenly (deleted components?)
   - Warn if summary is generic ("Function that does X")
   - Prompt user to review

4. **Language-specific parsers** (improve accuracy)
   - Use real parsers (babel for JS/TS, ast for Python)
   - Fallback to regex for unsupported languages

5. **User feedback loop** (improve over time)
   - Track accuracy issues (GitHub issues)
   - Iterate on detection logic (improve parsers)
   - Add language support based on user requests

**Contingency Plan:**
- If accuracy poor: Add prominent "Review generated docs" message
- If complaints frequent: Allow disabling autodocs (manual mode)
- If analysis complex: Reduce scope (detect only classes, skip functions)

**Monitoring:** User feedback on doc accuracy, sample codebase validation.

---

### R8: Gate False Positives (LOW)

**Description:** Quality gates may block valid transitions (false positives) or allow invalid ones (false negatives).

**Likelihood:** 3 (Possible) - Heuristics may be too strict or too lenient.

**Impact:** 3 (Moderate) - False positives frustrating, false negatives reduce quality.

**Risk Score:** 9 (Low)

**Indicators:**
- User complaints "gate blocked me incorrectly"
- Specs pass gates but are low quality (false negatives)
- Frequent gate overrides (--force-advance)

**Mitigation Strategies:**

1. **Tunable gate rules** (config.yaml)
   ```yaml
   gates:
     gate-1:
       enabled: true
       checks:
         require_acceptance_criteria: true
         min_criteria_count: 1
     gate-3:
       enabled: true
       checks:
         require_spec_tags: true
         require_tests: true
         min_test_coverage: 80  # Tunable threshold
   ```

2. **Clear gate failure messages** (actionable)
   - Not: "Gate 1 failed"
   - Instead: "Gate 1 failed: acceptance_criteria is empty. Add at least 1 criterion to proceed."

3. **Manual override option** (with warning)
   ```bash
   ./spec-drive-feature.sh --advance --force
   # Output: "⚠️  WARNING: Forcing advance without gate approval. This may reduce quality."
   ```

4. **Gate iteration** (improve rules over time)
   - Track false positive rate (user feedback)
   - Adjust rules based on data
   - Document rule changes (ADR or changelog)

5. **Gate documentation** (explain each check)
   - Document what each gate checks (README)
   - Explain rationale (why this check matters)
   - Provide examples (passing vs failing)

**Contingency Plan:**
- If false positives high: Loosen rules (make gates advisory in v0.1)
- If false negatives high: Add more checks (strengthen gates)
- If controversy: Make gates configurable (advisory vs enforcing mode per project)

**Monitoring:** Track gate pass/fail rates, user feedback on gate strictness.

---

### R9: User Experience (MEDIUM)

**Description:** Complex workflows, unclear error messages, or poor documentation could frustrate users.

**Likelihood:** 3 (Possible) - UX often overlooked until user feedback.

**Impact:** 4 (Major) - Poor UX reduces adoption, negative feedback.

**Risk Score:** 12 (Medium)

**Indicators:**
- User confusion ("what do I do next?")
- Complaints about error messages ("unhelpful")
- Questions on same topics repeatedly (docs unclear)

**Mitigation Strategies:**

1. **Clear next steps** (after every command)
   ```
   ✅ Feature spec created: AUTH-001
   📋 Next steps:
     1. Add acceptance criteria: edit .spec-drive/specs/AUTH-001.yaml
     2. Advance to specify stage: ./spec-drive-feature.sh --advance
   ```

2. **Helpful error messages** (actionable)
   - Not: "Error: Invalid state"
   - Instead: "Error: state.yaml is corrupted. Run './spec-drive-reset-state.sh' to recover."

3. **Progress indicators** (show workflow status)
   ```
   Current Workflow: feature (AUTH-001)
   Stage: implement (2/4)
   Gate Status: ⚠️ Can't advance (gate-3 failed)

   To advance:
     1. Fix failing tests: npm test
     2. Add @spec tags to code: see examples in docs/
     3. Re-run gate: ./spec-drive-gate.sh --gate 3 --spec AUTH-001
   ```

4. **Comprehensive documentation** (examples, tutorials)
   - README: Quick Start (5-minute walkthrough)
   - WORKFLOWS.md: Step-by-step guides
   - USER-JOURNEYS.md: Full scenarios with screenshots

5. **User testing** (early feedback)
   - Alpha test with 3-5 users (before v0.1 release)
   - Observe users (where do they get stuck?)
   - Iterate on UX based on feedback

**Contingency Plan:**
- If UX poor: Delay release, focus on polish (2-week UX sprint)
- If errors confusing: Add FAQ section (common errors + solutions)
- If workflows complex: Create video tutorials (supplement docs)

**Monitoring:** User feedback, GitHub issues tagged "ux", usability testing.

---

### R10: Testing Coverage Gaps (MEDIUM)

**Description:** Tests may not cover critical edge cases, leading to bugs in production.

**Likelihood:** 3 (Possible) - Coverage metrics don't guarantee quality.

**Impact:** 4 (Major) - Bugs in production damage reputation, require hotfixes.

**Risk Score:** 12 (Medium)

**Indicators:**
- Bugs found in features with "100% coverage"
- Edge cases not tested (empty inputs, large inputs)
- Integration tests missing (components tested in isolation)

**Mitigation Strategies:**

1. **Coverage targets + manual review** (not just metrics)
   - Require 80% line coverage (automated)
   - Require code review (human judgment)
   - Require integration tests (not just unit)

2. **Critical path testing** (100% coverage)
   - Identify critical paths (workflow state transitions)
   - Write E2E tests for every critical path
   - Regression test suite (run before every release)

3. **Edge case checklist** (per feature)
   - Empty inputs (no files, no specs)
   - Large inputs (1000 files, 100 specs)
   - Invalid inputs (corrupted YAML, missing fields)
   - Concurrent operations (two terminals, same workflow)
   - Platform differences (Linux vs macOS)

4. **Mutation testing** (detect weak tests)
   - Introduce bugs (mutate code)
   - Verify tests catch them (tests should fail)
   - If tests pass with bug: Test is weak (improve)

5. **User acceptance testing** (real scenarios)
   - Alpha/beta testers use system (not just developers)
   - Capture bugs missed by automated tests
   - Iterate based on feedback

**Contingency Plan:**
- If critical bug found: Hotfix release (v0.1.1)
- If test gaps large: Delay release, add tests (test sprint)
- If coverage tools insufficient: Add manual test cases (QA checklist)

**Monitoring:** Track bugs per release, test coverage trends, mutation testing scores.

---

## External Risks

### R11: Dependency Vulnerabilities (LOW)

**Description:** Dependencies (yq, jq, node packages) may have security vulnerabilities.

**Likelihood:** 2 (Unlikely) - Most tools are mature and well-maintained.

**Impact:** 3 (Moderate) - Vulnerabilities require patching but unlikely to block release.

**Risk Score:** 6 (Low)

**Indicators:**
- npm audit reports vulnerabilities
- Dependabot alerts (GitHub)
- CVE notifications for dependencies

**Mitigation Strategies:**

1. **Minimal dependencies** (reduce attack surface)
   - Prefer standard tools (yq, jq) over npm packages
   - Only add dependencies when necessary
   - Document dependency rationale

2. **Dependency scanning** (CI)
   ```yaml
   - run: npm audit --audit-level=moderate
   - run: npm audit fix  # Auto-fix if safe
   ```

3. **Pin versions** (reproducible builds)
   - package.json: Pin exact versions (not ^1.0.0)
   - Document required tool versions (README)

4. **Regular updates** (quarterly review)
   - Review dependencies for updates
   - Test after updates (regression suite)
   - Document breaking changes

5. **Vulnerability response plan**
   - High/critical vulnerability: Patch within 48 hours
   - Medium vulnerability: Patch within 1 week
   - Low vulnerability: Patch in next minor release

**Contingency Plan:**
- If critical vulnerability: Emergency hotfix release
- If dependency unmaintained: Find alternative or vendor code
- If vulnerability unfixable: Document risk, add mitigations

**Monitoring:** Dependabot alerts, npm audit in CI, quarterly dependency review.

---

### R12: Platform Changes (LOW)

**Description:** Platform changes (bash updates, tool API changes) could break compatibility.

**Likelihood:** 2 (Unlikely) - Platforms are stable, breaking changes rare.

**Impact:** 3 (Moderate) - Requires updates but unlikely to be urgent.

**Risk Score:** 6 (Low)

**Indicators:**
- macOS update breaks bash compatibility
- yq v5 released with breaking changes
- Node.js LTS version changes

**Mitigation Strategies:**

1. **Target LTS versions** (stable, long support)
   - Node.js: v18 LTS (supported until 2025-04)
   - bash: 3.2+ (macOS default) and 4.0+ (Linux)
   - yq: v4.x (stable, no v5 yet)

2. **Version detection** (warn on unsupported versions)
   ```bash
   # Check bash version
   if ((BASH_VERSINFO[0] < 3)); then
     echo "⚠️  WARNING: bash ${BASH_VERSION} not supported. Upgrade to 3.2+"
     exit 1
   fi
   ```

3. **Compatibility tests** (matrix testing)
   - CI matrix: bash 3.2, 4.0, 5.0
   - CI matrix: Node.js 18, 20
   - CI matrix: yq v4.30, v4.35

4. **Release notes monitoring** (upstream changes)
   - Subscribe to yq releases (GitHub notifications)
   - Subscribe to bash mailing list (major changes)
   - Review Node.js LTS schedule

5. **Graceful degradation** (fallbacks)
   - If yq v5 incompatible: Keep using yq v4 (document requirement)
   - If bash 6 breaks scripts: Update or add compatibility shim

**Contingency Plan:**
- If breaking change: Release patch within 1 week
- If upstream unmaintained: Fork or vendor
- If migration complex: Document manual workaround

**Monitoring:** Subscribe to dependency release notes, quarterly platform review.

---

## Mitigation Strategies

### Mitigation Prioritization

**High-Priority Risks (R1, R3, R5):**
- **Immediate action:** Mitigate during Phase 1-2 (foundation)
- **Resources:** Allocate dedicated time (20% of development)
- **Review:** Weekly risk check-in (status, new indicators)

**Medium-Priority Risks (R2, R4, R9, R10):**
- **Proactive action:** Mitigate during relevant phases
- **Resources:** Standard development time (built into tasks)
- **Review:** Bi-weekly risk check-in

**Low-Priority Risks (R6, R7, R8, R11, R12):**
- **Monitor:** Track indicators, mitigate if escalates
- **Resources:** Minimal (address if becomes issue)
- **Review:** Monthly risk check-in

### Cross-Cutting Mitigations

**1. Early and Frequent Testing**
- Mitigates: R1 (portability), R2 (performance), R3 (state corruption), R10 (coverage gaps)
- Action: CI on every commit, test matrix (platforms, versions)

**2. Clear Documentation**
- Mitigates: R4 (dependencies), R6 (templates), R9 (UX)
- Action: Comprehensive README, examples, troubleshooting

**3. Scope Discipline**
- Mitigates: R5 (scope creep)
- Action: Strict scope freeze, change control process

**4. Iterative Development**
- Mitigates: R7 (autodocs), R8 (gates), R9 (UX)
- Action: Alpha testing, user feedback, iterate

**5. Monitoring and Alerting**
- Mitigates: All risks
- Action: Track indicators, weekly/monthly reviews

---

## Contingency Plans

### Scenario: Critical Bug Found 1 Week Before Release

**Symptoms:**
- State corruption bug (R3) found in beta testing
- Workflow stuck, data loss risk
- High severity, blocks release

**Response Plan:**
1. **Immediate:** Triage (confirm severity, impact)
2. **Day 1:** Fix bug (highest priority, all hands)
3. **Day 2:** Write regression test, verify fix
4. **Day 3:** Release candidate (RC2), re-test
5. **Day 5:** If stable, release. If not, delay 1 week.

**Communication:**
- Notify stakeholders (delay possible)
- Publish status update (GitHub discussion)
- Document fix (changelog, ADR if architectural)

---

### Scenario: Performance Targets Missed (R2)

**Symptoms:**
- Autodocs takes 3 minutes on 1000 files (target: <60s)
- User feedback: "too slow"

**Response Plan:**
1. **Phase 5 (performance testing):** Identify bottleneck (profiling)
2. **Option A (quick fix):** Add progress indicator ("Analyzing 500/1000...")
   - Improves perceived performance (UX fix)
   - Implement in 1 day
3. **Option B (optimization):** Parallelize analysis (technical fix)
   - Requires 1 week, risky for v0.1
4. **Option C (defer):** Add --skip-analysis flag, document limitation
   - Release v0.1 with workaround, optimize in v0.2

**Decision Criteria:**
- If <2 weeks to release: Choose Option A or C (quick)
- If >2 weeks to release: Choose Option B (optimize)

---

### Scenario: Scope Creep Threatens Timeline (R5)

**Symptoms:**
- Timeline slipped 2 weeks (was 12 weeks, now 14 weeks)
- Cause: Added features not in original scope

**Response Plan:**
1. **Week 1:** Scope audit (what was added? why?)
2. **Week 1:** Prioritize features (P0 vs P1 vs P2)
3. **Week 2:** Decision point:
   - **Option A (cut features):** Move P2 features to v0.2, release on time
   - **Option B (accept delay):** Keep all features, delay release 2 weeks
   - **Option C (hybrid):** MVP release (v0.1a) on time, full release (v0.1b) +2 weeks

**Decision Criteria:**
- If stakeholders insist on timeline: Choose Option A (cut)
- If features critical: Choose Option B (delay)
- If risk tolerance high: Choose Option C (phased release)

---

### Scenario: Platform Incompatibility Found Late (R1)

**Symptoms:**
- Tests pass on Linux, fail on macOS
- Cause: bash 3.2 incompatibility (associative arrays)
- Found in Phase 5 (integration testing)

**Response Plan:**
1. **Day 1:** Identify all bash 3.2 incompatibilities (code review)
2. **Day 2-3:** Rewrite using portable syntax (indexed arrays, workarounds)
3. **Day 4:** Re-test on macOS, verify fix
4. **Day 5:** Regression test (ensure Linux still works)

**Prevention (future):**
- Add macOS to CI matrix (catch early)
- Use shellcheck linter (detect portability issues)

---

## Risk Monitoring

### Risk Review Schedule

**Weekly (during development):**
- Review high-priority risks (R1, R3, R5)
- Check indicators (any new signals?)
- Update mitigation status (in progress, completed)

**Bi-Weekly:**
- Review medium-priority risks (R2, R4, R9, R10)
- Update risk scores (likelihood, impact)

**Monthly:**
- Review low-priority risks (R6, R7, R8, R11, R12)
- Review entire risk register (any new risks?)

**Phase Exits:**
- Full risk review (all risks)
- Update contingency plans (based on learnings)

**Pre-Release:**
- Final risk review (any showstoppers?)
- Go/no-go decision (based on risk posture)

### Risk Reporting

**Format:** Risk Status Report (markdown)

```markdown
# Risk Status Report - Week 10

## Summary
- High risks: 3 (R1, R3, R5)
- Medium risks: 4 (R2, R4, R9, R10)
- Low risks: 5 (R6, R7, R8, R11, R12)

## Changes This Week
- R1 (Portability): Mitigated (added macOS to CI)
- R5 (Scope Creep): Escalated (timeline slipped 1 week)

## Actions Required
- R5: Scope audit meeting (scheduled Friday)
- R3: Add state backup test (assigned to @dev)

## New Risks
- None

## Overall Risk Posture: MEDIUM (within tolerance)
```

**Distribution:**
- Core team (weekly, internal)
- Stakeholders (bi-weekly, summary)
- Public (monthly, sanitized)

---

## Risk Register

### Risk Tracking Table

| ID | Risk | Likelihood | Impact | Score | Priority | Status | Owner | Mitigation Due |
|----|------|------------|--------|-------|----------|--------|-------|----------------|
| R1 | Shell portability | 4 | 4 | 16 | High | Mitigated | DevOps | Phase 1 |
| R2 | Performance | 4 | 3 | 12 | Medium | Monitoring | Backend | Phase 3 |
| R3 | State corruption | 3 | 5 | 15 | High | Mitigated | Backend | Phase 2 |
| R4 | Dependencies | 4 | 3 | 12 | Medium | Mitigated | DevOps | Phase 1 |
| R5 | Scope creep | 4 | 4 | 16 | High | Monitoring | PM | Continuous |
| R6 | Template complexity | 3 | 3 | 9 | Low | Accepted | Backend | Phase 1 |
| R7 | Autodocs accuracy | 3 | 3 | 9 | Low | Monitoring | Backend | Phase 3 |
| R8 | Gate false positives | 3 | 3 | 9 | Low | Monitoring | Backend | Phase 4 |
| R9 | User experience | 3 | 4 | 12 | Medium | Monitoring | UX | Phase 5 |
| R10 | Test coverage gaps | 3 | 4 | 12 | Medium | Mitigated | QA | Phase 5 |
| R11 | Dependency vulns | 2 | 3 | 6 | Low | Monitoring | Security | Continuous |
| R12 | Platform changes | 2 | 3 | 6 | Low | Accepted | DevOps | Continuous |

### Risk Status Definitions

**Accepted:** Risk acknowledged, no active mitigation (monitoring only)

**Monitoring:** Risk tracked, mitigation planned but not started

**Mitigating:** Active mitigation in progress

**Mitigated:** Mitigation complete, risk reduced to acceptable level

**Escalated:** Risk likelihood or impact increased, requires immediate attention

**Closed:** Risk no longer relevant (resolved or avoided)

---

## Appendix

### Risk Assessment History

**Version 1.0 (2025-11-01):**
- Initial risk assessment (12 risks identified)
- Prioritized high-priority risks (R1, R3, R5)
- Documented mitigation strategies and contingency plans

**Future Updates:**
- Will be updated weekly during development
- Will track risk status changes (escalations, mitigations)
- Will add new risks as identified

### References

- [TDD.md](./TDD.md) - Technical design (risk context)
- [IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md) - Mitigation timing
- [TEST-PLAN.md](./TEST-PLAN.md) - Testing mitigations (R10)
- [DECISIONS.md](./DECISIONS.md) - Risk-driven decisions

### Risk Assessment Methodology

**Framework:** Qualitative risk assessment (likelihood × impact)

**Process:**
1. Identify risks (brainstorming, historical data)
2. Assess likelihood and impact (1-5 scale)
3. Calculate risk score (likelihood × impact)
4. Prioritize (critical, high, medium, low)
5. Develop mitigation strategies (proactive)
6. Develop contingency plans (reactive)
7. Monitor and review (continuous)

**Tools:**
- Risk register (tracking table)
- Risk matrix (visualization)
- Status reports (communication)

---

**Maintained By:** Core Team
**Update Frequency:** Weekly during development, monthly post-release
**Last Review:** 2025-11-01
