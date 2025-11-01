# Task TASK-023: Enhance stack-detection.py

**Status:** Not Started
**Phase:** Phase 3 (Stack Profiles)
**Duration:** 12 hours
**Created:** 2025-11-01

---

## Overview

Enhance stack-detection.py to detect Python/FastAPI, Go, and Rust stacks with ≥90% accuracy.

## Dependencies

- [ ] TASK-020 - Create python-fastapi.yaml profile
- [ ] TASK-021 - Create go.yaml profile
- [ ] TASK-022 - Create rust.yaml profile

## Acceptance Criteria

- [ ] Detects 4 stacks: TypeScript/React, Python/FastAPI, Go, Rust
- [ ] Detection accuracy ≥90% on test projects
- [ ] Multiple indicators used (files + content patterns)
- [ ] Confidence scoring implemented
- [ ] Monorepo support (detect multiple stacks)
- [ ] Fallback to generic profile works
- [ ] Unit tests ≥90% coverage

## Implementation Details

### Detection Heuristics

**Python/FastAPI:**
- Files: requirements.txt, pyproject.toml
- Content: "fastapi" in requirements.txt
- Confidence: High if both present

**Go:**
- Files: go.mod
- Content: Go files with "package main"
- Confidence: High if go.mod present

**Rust:**
- Files: Cargo.toml
- Content: [package] section
- Confidence: High if Cargo.toml present

---

**Related Documents:**
- TDD: `.spec-drive/development/planned/v0.2/TDD.md` (Section 3.3)
- Risk Assessment: `.spec-drive/development/planned/v0.2/RISK-ASSESSMENT.md` (RISK-007)
