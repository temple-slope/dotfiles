---
description: Review git diff against main branch
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*)
---

## Context

**Current branch:** !`git branch --show-current`

**Commits on this branch (not in main):**
!`git log main..HEAD --oneline`

**Changed files:**
!`git diff --stat main`

**Full diff:**
!`git diff main`

## Review Instructions

Please review the changes above and provide:

1. **Summary** - Brief overview of what the changes do
2. **Code Quality** - Style consistency, readability, maintainability
3. **Potential Bugs** - Logic errors, edge cases, error handling issues
4. **Security Concerns** - Vulnerabilities, sensitive data exposure
5. **Performance** - Any performance implications
6. **Suggestions** - Improvements and recommendations

Be concise and actionable. Focus on issues that matter.
