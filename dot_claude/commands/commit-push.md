---
description: Commit changes grouped by content type and push after security review
allowed-tools: Bash(git:*), Bash(grep:*), Glob, Grep, Read
---

## Context

**Current branch:** !`git branch --show-current`

**Untracked files:**
!`git status --porcelain | grep "^??" | cut -c4-`

**Modified files:**
!`git status --porcelain | grep "^.M\|^ M\|^M" | cut -c4-`

**Deleted files:**
!`git status --porcelain | grep "^.D\|^ D\|^D" | cut -c4-`

**Full diff (staged and unstaged):**
!`git diff HEAD`

**Recent commits (for style reference):**
!`git log --oneline -5`

## Instructions

1. **Analyze Changes**
   - Review all changes (untracked, modified, deleted files)
   - Group related changes into logical commits by:
     - Feature/functionality (e.g., "tmux config", "zsh settings")
     - File type (e.g., "Brewfile", "Claude settings")
     - Purpose (e.g., "cleanup", "rename", "enhancement")

2. **Security Review**
   Before committing, check for:
   - Hardcoded secrets (API keys, tokens, passwords)
   - Private keys or certificates
   - Sensitive paths or credentials
   - 1Password references being exposed
   - Personal information that shouldn't be public

   If issues found, STOP and report them. Do not proceed with commits.

3. **Create Commits**
   For each logical group:
   - Stage only the related files
   - Write a concise commit message following conventional style:
     - Summary line under 50 characters
     - Explain "what" and "why" in body if needed
   - Always include: `Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>`

4. **Push to Remote**
   After all commits are created:
   - Verify the branch is ahead of remote
   - Push to origin

## Output Format

Report each step:
1. Security review result (pass/fail with details)
2. List of commits to be created with their files
3. Each commit as it's created
4. Final push result

Use the TodoWrite tool to track progress through each commit.
