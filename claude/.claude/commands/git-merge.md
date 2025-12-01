---
allowed-tools: bash_tool
argument-hint: [source] [target]
description: Merge git branches with optional push
model: claude-sonnet-4-5-20250929
---

## Your Task

Merge a source branch into a target branch with safety checks and optional push.

**If arguments provided:**
- First argument: source branch (branch to merge FROM)
- Second argument: target branch (branch to merge INTO)

**If no arguments provided:**
- Detect current branch as source
- Use `main` as default target branch
- If `main` doesn't exist, try `master` as fallback

## Workflow

1. **Preparation**:
   - Run `git status` to check for uncommitted changes
   - **If uncommitted changes exist**:
     - Inform user: "Du hast uncommittete Änderungen. Ich erstelle zuerst einen Commit."
     - Execute `/git-commit` slash command to commit changes
     - Wait for commit completion before proceeding
   - Run `git fetch` to update remote references
   - Show current branch with `git branch --show-current`

2. **Branch Analysis**:
   - If source not provided: Use current branch
   - If target not provided: Use `main` (or `master` if `main` doesn't exist)
   - Verify both branches exist with `git branch -a`
   - Show last commits on both branches with `git log`

3. **Checkout Target**:
   - Execute `git checkout <target>`
   - Confirm successful checkout
   - Run `git pull` to ensure target is up-to-date

4. **Merge Execution**:
   - Execute `git merge <source>`
   - Handle merge conflicts if they occur
   - If conflicts: Show conflicted files and stop with instructions
   - If successful: Show merge summary

5. **Push Confirmation**:
   - After successful merge, ask:
```
     Merge erfolgreich! Möchtest du die Änderungen auf '<target>' jetzt pushen? (ja/nein)
```
   - Wait for user response
   - If yes/ja: Execute `git push` and show result
   - If no/nein: Acknowledge and finish

## Handling Uncommitted Changes

**Detection**:
- Run `git status --porcelain` to detect changes
- Check for both staged and unstaged changes

**Action**:
1. If changes detected:
```
   ⚠️ Uncommittete Änderungen gefunden:
   <list changes>

   Ich erstelle jetzt einen Commit mit /git-commit...
```
2. Call `/git-commit` slash command
3. Wait for successful commit completion
4. Continue with merge workflow

**Important**: Do NOT proceed with merge until changes are committed. The `/git-commit` command will handle:
- Staging files with `git add .`
- Analyzing changes
- Creating appropriate commit message
- Executing the commit

## Default Target Branch Logic

1. Check if `main` branch exists (local or remote)
2. If `main` exists: Use `main` as target
3. If `main` doesn't exist: Check for `master`
4. If `master` exists: Use `master` as target
5. If neither exists: Ask user to specify target branch

Always inform user which target branch is being used:
```
Merge '<source>' in '<target>' (Standard-Branch)
```

## Safety Checks

- **Before checkout**: Check for uncommitted changes and auto-commit if needed
- **Before merge**: Ensure branches exist
- **During merge**: Detect conflicts immediately
- **After merge**: Verify merge commit was created

## Conflict Handling

If merge conflicts occur:
1. List all conflicted files with `git status`
2. Show conflict markers in files
3. Provide clear instructions:
```
   Merge-Konflikt erkannt! Bitte löse folgende Konflikte:

   Konfliktdateien:
   - <list files>

   Schritte:
   1. Öffne die Dateien und löse die Konflikte
   2. Führe 'git add <file>' für jede gelöste Datei aus
   3. Führe 'git commit' aus um den Merge abzuschließen
   4. Optional: Führe 'git push' aus
```
4. Do NOT attempt to auto-resolve conflicts
5. Stop and wait for user to resolve manually

## Examples
```bash
# Merge current branch into main (with auto-commit if needed)
claude /gitmerge

# Merge feature branch into main (with auto-commit if needed)
claude /gitmerge feature/user-auth

# Merge feature branch into develop (explicit target)
claude /gitmerge feature/user-auth develop

# Merge develop into main (explicit source and target)
claude /gitmerge develop main
```

## Workflow Example with Uncommitted Changes
```
User: claude /gitmerge

Claude:
1. ✓ Status prüfen
2. ⚠️ Uncommittete Änderungen gefunden:
   M  src/auth.py
   ?? src/test.py
3. 📝 Erstelle Commit mit /git-commit...
   → Analyzing changes...
   → Proposed: "feat(auth): add login validation"
   → Commit created!
4. ✓ Fetch remote changes
5. ✓ Checkout main
6. ✓ Pull main
7. ✓ Merge feature/auth into main
8. ✅ Merge erfolgreich!
9. ❓ Möchtest du die Änderungen auf 'main' jetzt pushen? (ja/nein)
```

## Important

- Always fetch before analyzing branches
- Never force-push after merge
- Preserve merge commit history (no squash unless explicitly requested)
- Show clear status messages at each step
- Handle both local and remote branches
- Never mention Claude Code in commit messages
- Always inform user about default target branch being used
- **Auto-commit uncommitted changes using `/git-commit` before proceeding**

## Error Messages

Provide helpful German error messages:
- "Fehler: Branch '<name>' existiert nicht"
- "Warnung: Du hast uncommittete Änderungen - erstelle Commit..."
- "Fehler: Merge-Konflikt - manuelle Auflösung erforderlich"
- "Fehler: Remote-Branch ist weiter voraus - bitte erst pullen"
- "Fehler: Weder 'main' noch 'master' Branch gefunden - bitte Target-Branch angeben"
- "Fehler: Commit fehlgeschlagen - Merge abgebrochen"
