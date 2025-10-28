# Git Merge Command

This command merges the current branch into the main branch.

```claude
<claude_code>
<description>
Merges the current branch into the main branch with confirmation prompts
</description>

<execute>
#!/bin/bash
set -e

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if we're already on main
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "❌ You are already on the main branch."
    echo "Please switch to the branch you want to merge."
    exit 1
fi

# Ask user whether to merge directly or review first
echo "🔀 Branch '$CURRENT_BRANCH' → 'main'"
echo ""
echo "Would you like to:"
echo "1) Perform the merge directly"
echo "2) Review the changes first (--no-commit --no-ff)"
echo ""
read -p "Your choice (1/2): " CHOICE

case $CHOICE in
    1)
        MERGE_MODE="direct"
        MERGE_OPTS=""
        echo ""
        echo "📋 Merge mode: Direct merge"
        ;;
    2)
        MERGE_MODE="review"
        MERGE_OPTS="--no-commit --no-ff"
        echo ""
        echo "📋 Merge mode: With review (you can review changes before committing)"
        ;;
    *)
        echo "❌ Invalid selection. Aborting."
        exit 1
        ;;
esac

# Confirmation before merge
echo ""
echo "⚠️  CONFIRMATION REQUIRED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Branch '$CURRENT_BRANCH' will be merged into 'main'"
if [ "$MERGE_MODE" = "review" ]; then
    echo "Merge options: --no-commit --no-ff"
    echo "(You can review changes before committing)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Perform merge now? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Merge aborted."
    exit 0
fi

# Switch to main branch
echo ""
echo "🔄 Switching to main branch..."
git checkout main

# Perform merge
echo "🔀 Performing merge..."
if [ "$MERGE_MODE" = "direct" ]; then
    git merge "$CURRENT_BRANCH"
    echo ""
    echo "✅ Merge completed successfully!"
    echo "Branch '$CURRENT_BRANCH' has been merged into 'main'."

    # Ask if branch should be deleted
    echo ""
    read -p "❓ Would you like to delete the branch '$CURRENT_BRANCH' now? (y/n): " DELETE_BRANCH

    if [ "$DELETE_BRANCH" = "y" ] || [ "$DELETE_BRANCH" = "Y" ]; then
        git branch -d "$CURRENT_BRANCH"
        echo "🗑️  Branch '$CURRENT_BRANCH' has been deleted."
    else
        echo "ℹ️  Branch '$CURRENT_BRANCH' has been kept."
    fi
else
    git merge $MERGE_OPTS "$CURRENT_BRANCH"
    echo ""
    echo "✅ Merge prepared!"
    echo ""
    echo "📝 Changes have been merged but not yet committed."
    echo "You can now:"
    echo "  - Review the changes: git status, git diff --cached"
    echo "  - Complete the merge: git commit"
    echo "  - Abort the merge: git merge --abort"
    echo ""
    echo "ℹ️  Note: The option to delete the branch will appear after the commit."
fi
</execute>
</claude_code>
```
