---
allowed-tools: bash_tool
argument-hint: [type] [message]
description: Create a smart conventional git commit
model: claude-sonnet-4-5-20250929
---

## Your Task

Create a git commit following Conventional Commits format.

**If the user provides arguments:**
- First argument: commit type (feat, fix, docs, etc.)
- Second argument: commit message
- Use these directly for the commit

**If no arguments provided:**
- Analyze changes with `git status` and `git diff`
- Suggest appropriate commit type and message
- Ask for confirmation before committing

## Conventional Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style (formatting, whitespace)
- **refactor**: Code restructuring without behavior change
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system or dependencies
- **ci**: CI/CD configuration
- **chore**: Maintenance tasks

## Commit Message Rules

1. Format: `<type>(<scope>): <subject>`
2. Subject: 50 chars max, imperative mood ("Add" not "Added")
3. Optional body: Explain what and why (wrap at 72 chars)
4. Optional footer: Reference issues, breaking changes

## Workflow

1. Run `git status` to see current state
2. Check if there are unstaged changes that need `git add .`
3. Review `git diff --cached` to understand staged changes
4. Determine commit type based on changes
5. Create clear, concise commit message
6. Show the proposed commit and ask for confirmation
7. Execute `git commit -m "<message>"`
8. **After successful commit**: Ask user if they want to push changes with `git push`
9. **If user confirms**: Execute `git push` and show result
10. **If user declines**: Acknowledge and finish

## Important

- Group related changes logically
- Suggest splitting commit if changes are too diverse
- Warn about files that shouldn't be committed (e.g., secrets, temp files)
- Never include "Co-Authored-By: Claude" or mention Claude Code in commits
- If breaking changes detected, include "BREAKING CHANGE:" in footer

## Push Confirmation

After a successful commit, ALWAYS ask:
```
Commit erfolgreich erstellt! Möchtest du die Änderungen jetzt pushen? (ja/nein)
```

Wait for user response before executing `git push`. If the user says yes/ja, execute the push. If no/nein, thank them and finish.

## Examples

Good commits:
- `feat(auth): add OAuth2 login support`
- `fix(api): handle null response in user endpoint`
- `docs(readme): update installation instructions`

Bad commits:
- `updated stuff` (too vague)
- `Added new feature for users to login with OAuth` (not imperative)
- `fix` (no description)
