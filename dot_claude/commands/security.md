---
description: Security review of git diff against main branch
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git branch:*), Bash(grep:*), Bash(find:*), Glob, Grep, Read
---

## Context

**Current branch:** !`git branch --show-current`

**Changed files:**
!`git diff --name-only main`

**Full diff:**
!`git diff main`

## Security Review Instructions

Perform a thorough security analysis of the changes above. Check for:

### 1. Secrets & Credentials
- Hardcoded API keys, tokens, passwords
- Private keys or certificates
- Connection strings with credentials
- Sensitive configuration values

### 2. Injection Vulnerabilities
- SQL injection
- Command injection
- XSS (Cross-Site Scripting)
- Code injection / eval usage

### 3. Authentication & Authorization
- Broken access controls
- Missing authentication checks
- Insecure session handling
- Privilege escalation risks

### 4. Data Exposure
- Sensitive data in logs
- Unencrypted sensitive data
- Excessive data in API responses
- PII handling issues

### 5. Input Validation
- Missing or weak input validation
- Path traversal vulnerabilities
- Unsafe deserialization
- File upload vulnerabilities

### 6. Dependencies & Configuration
- Known vulnerable dependencies
- Insecure default configurations
- Missing security headers
- Overly permissive CORS

## Output Format

For each issue found:
- **Severity**: Critical / High / Medium / Low
- **Location**: File and line number
- **Issue**: Description of the vulnerability
- **Recommendation**: How to fix it

If no issues found, confirm the changes appear secure.
