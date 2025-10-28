Generate a conventional commit message following https://www.conventionalcommits.org/en/v1.0.0/ specification and create the commit automatically.

Steps:

1. ADD all modified and new files to git. If you think there are files that should not be in version control, ask the user. If you see files that you think should be bundled into separate commits, ask the user.
2. Analyze the current git changes using `git status` and `git diff --staged`
3. Determine the appropriate commit type (feat, fix, docs, style, refactor, test, chore, etc.)
4. Identify the scope if applicable (component, module, or area affected)
5. Write a concise description in imperative mood (50 chars or less)
6. Add a detailed body if the change is complex (wrap at 72 chars)
7. Include breaking change footer if applicable
8. Format as: `type(scope): description`
9. Create the commit with the generated message
10. Ask the user if hey want to push the commit to the remote repository for the current branch.

Example formats:

- `feat(auth): add OAuth2 login support`
- `fix(api): resolve null pointer in user endpoint`
- `docs: update installation instructions`
- `chore(deps): bump lodash to 4.17.21`

Generate the most appropriate commit message based on the changes and commit automatically.

Never add a reference to cluade code in git commit messages
