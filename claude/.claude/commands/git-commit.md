---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git commit:*)
argument-hint: [type] [message]
description: Create a smart conventional git commit
model: claude-sonnet-4-5-20250929
---

## Context

- Current git status: !`git status --short`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -5`

## Your Task

Analyze the changes and create a git commit following these guidelines:

1. **Conventional Commit Format**:
   - feat: New feature
   - fix: Bug fix
   - docs: Documentation changes
   - style: Code style changes (formatting, etc)
   - refactor: Code refactoring
   - perf: Performance improvements
   - test: Test changes
   - build: Build system changes
   - ci: CI/CD changes
   - chore: Other changes

2. **Commit Message Structure**:
   ```
   <type>(<scope>): <subject>

   <body>

   <footer>
   ```

3. **Best Practices**:
   - Subject line: 50 characters max
   - Use imperative mood ("Add" not "Added")
   - Body: Wrap at 72 characters
   - Explain what and why, not how
   - Reference issues if applicable

4. **Smart Analysis**:
   - Group related changes
   - Suggest splitting if changes are unrelated
   - Detect breaking changes
   - Identify files that shouldn't be committed

If arguments provided: Use $1 as type and $2 as message.
Otherwise: Analyze changes and suggest appropriate commit.

Never mention Claude Code in the commit message.

## Steps

1. Review all changes
2. Identify the commit type
3. Stage appropriate files
4. Create descriptive commit message
5. Commit the changes
