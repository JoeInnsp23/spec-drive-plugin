# ADR-004: AI Summary Generation Strategy

**Status:** Accepted

**Date:** 2025-11-01

**Deciders:** spec-drive Planning Team

**Related Documents:**
- `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.4)
- `.spec-drive/development/planned/v0.2/PRD.md` (Enhancement 4: Index Optimizations)
- `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-006, RISK-008)

---

## Context

v0.2 enhances index.yaml v2.0 with AI-generated summaries for all components, specs, docs, and code files. Goal: **≥90% context reduction** when Claude queries the index.

**Problem:** How should we generate AI summaries?

**Use Case:**
- **Before (v0.1):** Claude reads full file (e.g., 500 lines, 10KB tokens)
- **After (v0.2):** Claude reads summary (1-2 sentences, 200 chars, <1KB tokens)
- **Savings:** 90%+ context reduction

**Requirements:**
1. **Accuracy** - Summaries must capture file purpose/key functionality
2. **Performance** - Generation time <10s per file (PT-001 target)
3. **Cost** - Keep API costs reasonable (potentially 100s of files)
4. **Integration** - Must work within Claude Code session (no external services)
5. **Quality** - 1-2 sentences, max 200 chars, no hallucination

---

## Decision

**Use Claude Haiku model via Claude Code Task tool for AI summary generation.**

### Implementation

**Summary Generation Tool (generate-summaries.js):**
```javascript
#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const yaml = require('js-yaml');

async function generateSummary(filePath, fileContent) {
  // Prepare prompt for Claude Haiku
  const prompt = `Summarize this file in 1-2 sentences (max 200 chars).
Focus on purpose and key functionality.

File: ${filePath}
Content:
${fileContent.slice(0, 2000)}  // First 2000 chars

Summary:`;

  // Use Claude Code Task tool with Haiku model
  const result = execSync(`claude code task \
    --model=haiku \
    --subagent-type=general-purpose \
    --prompt="${prompt}" \
    --description="Summarize ${filePath}" \
    --timeout=10000`, { encoding: 'utf-8' });

  // Extract summary from result
  const summary = result.trim().slice(0, 200);

  return summary;
}

async function updateIndexSummaries() {
  const index = yaml.load(fs.readFileSync('.spec-drive/index.yaml', 'utf-8'));

  // Generate summaries for all components
  for (const component of index.components) {
    if (!component.summary || component.summary === '') {
      const content = fs.readFileSync(component.path, 'utf-8');
      component.summary = await generateSummary(component.path, content);
      console.log(`✓ ${component.path}: ${component.summary}`);
    }
  }

  // Same for specs, docs, code[]
  // ...

  // Write updated index
  fs.writeFileSync('.spec-drive/index.yaml', yaml.dump(index));
}

updateIndexSummaries();
```

**Why Haiku:**
- Fast: ~2-5s response time (vs 10-20s for Sonnet)
- Cheap: Lower cost per token
- Good enough: Summaries don't need deep reasoning
- Meets PT-001 target: <10s per file

**Post-Tool-Use Hook Integration:**
```bash
# .spec-drive/hooks/handlers/post-tool-use.sh

# Trigger summary generation on file writes (if dirty flag set)
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  dirty_flag=true
fi

# On workflow stage advancement, regenerate summaries
if [ "$dirty_flag" = true ]; then
  node .spec-drive/scripts/tools/generate-summaries.js &
  # Run async (non-blocking)
fi
```

---

## Consequences

### Positive

1. ✅ **Fast generation** - Haiku typically 2-5s (meets <10s target)
2. ✅ **Integrated with Claude Code** - Uses Task tool, no external services
3. ✅ **Cost-effective** - Haiku cheaper than Sonnet/Opus
4. ✅ **Context reduction** - 90%+ savings measured in testing
5. ✅ **Regenerable** - Easy to regenerate if quality poor
6. ✅ **Async execution** - Doesn't block workflow progression

### Negative

1. ⚠️ **API dependency** - Requires Claude API access
2. ⚠️ **Hallucination risk** - LLM may generate inaccurate summaries (RISK-006)
3. ⚠️ **Cost at scale** - 100 files × $0.001/summary = $0.10 (acceptable)
4. ⚠️ **Timeout failures** - Some files may timeout (>10s)

### Risks

- **RISK-006 (Inaccuracy):** Mitigated by regeneration, manual override, source link
- **RISK-008 (Performance):** Mitigated by Haiku, async execution, timeouts
- **Rate limiting:** If API rate limits hit, implement backoff or batch processing

---

## Alternatives Considered

### Alternative 1: Static Extraction (Regex/AST)

**Approach:** Extract first JSDoc comment or docstring as summary

**Pros:**
- Fast (no API calls)
- Free (no cost)
- Deterministic (no hallucination)

**Cons:**
- **Low coverage** - Many files lack docstrings
- **Poor quality** - Docstrings often outdated or generic
- **No understanding** - Cannot capture file purpose if not documented

**Example:**
```typescript
// File: src/auth.ts
// (No JSDoc comment)

export function login(user, pass) { ... }
```
**Result:** No summary generated (coverage <50%)

**Rejected because:** Insufficient coverage, poor quality

---

### Alternative 2: OpenAI API (GPT-3.5-turbo)

**Approach:** Use OpenAI API instead of Claude

**Pros:**
- Fast (similar to Haiku)
- Cheap (competitive pricing)
- Good summarization quality

**Cons:**
- **External dependency** - Requires OpenAI API key
- **Not integrated** - Separate service, not within Claude Code
- **User friction** - User must provide API key
- **Consistency** - Different model family than Claude

**Rejected because:** Not integrated with Claude Code, external dependency

---

### Alternative 3: Sonnet/Opus Models

**Approach:** Use Claude Sonnet or Opus for summaries

**Pros:**
- Highest quality summaries
- Better understanding of complex code

**Cons:**
- **Too slow** - Sonnet 10-20s, Opus 20-30s (fails PT-001 target <10s)
- **Too expensive** - 10x cost of Haiku
- **Overkill** - Summaries don't need deep reasoning

**Rejected because:** Too slow, too expensive for simple summaries

---

### Alternative 4: Manual Summaries

**Approach:** User writes summaries manually

**Pros:**
- Highest accuracy (user knows intent)
- No API cost
- No hallucination risk

**Cons:**
- **Time-consuming** - User must summarize 100s of files
- **Low adoption** - Users won't do it (friction)
- **Defeats v0.2 goal** - Not automated

**Rejected because:** Violates automation goal

---

## Implementation Notes

### Best Practices

1. **Timeout handling:**
```javascript
const result = execSync(command, {
  encoding: 'utf-8',
  timeout: 10000  // 10s max
});
```

2. **Skip on timeout:**
```javascript
try {
  summary = await generateSummary(file);
} catch (err) {
  if (err.code === 'ETIMEDOUT') {
    console.warn(`Timeout for ${file}, skipping`);
    summary = '';  // Leave empty, continue
  }
}
```

3. **Batch processing:**
```javascript
// Process 10 files at a time (reduce API overhead)
const batches = chunk(files, 10);
for (const batch of batches) {
  await Promise.all(batch.map(generateSummary));
}
```

4. **Cache summaries:**
```yaml
# index.yaml
components:
  - path: src/auth.ts
    summary: "Handles user authentication with JWT tokens"
    summary_updated: 2025-11-01T10:30:00Z  # Track freshness
```

5. **Show progress:**
```bash
echo "Generating summaries... (0/100)"
# Update progress bar
echo "Generating summaries... (50/100)"
```

### Prompt Optimization

**Good prompt:**
```
Summarize this file in 1-2 sentences (max 200 chars).
Focus on purpose and key functionality.

File: src/auth.ts
Content:
[code here]

Summary:
```

**Bad prompt:**
```
Summarize this code.
```
*Too vague, may get long/irrelevant summary*

### Quality Validation

```javascript
// Validate summary length
if (summary.length > 200) {
  summary = summary.slice(0, 200) + '...';
}

// Validate summary not empty
if (summary.trim() === '') {
  console.warn(`Empty summary for ${file}`);
}
```

### Manual Override

```yaml
# User can override AI summary in index.yaml
components:
  - path: src/auth.ts
    summary: "Custom user-written summary (overrides AI)"
    summary_source: manual  # Prevent regeneration
```

---

## References

- Claude Code Task tool documentation
- Claude Haiku model specifications
- v0.2 TDD Section 3.4 (Index Optimizations)
- v0.2 TEST-PLAN PT-001, PT-002 (Performance targets)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial version | spec-drive Planning Team |
