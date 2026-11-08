# Global Claude Code instructions

Stowed from the dotfiles repo (`stow/claude/.claude/CLAUDE.md` → `~/.claude/CLAUDE.md`).
Applies to every project; project `CLAUDE.md` files take precedence.

## Handoffs

When `/mattpocock-skills:handoff` is used, save the handoff document(s) as
Markdown under `.prompts/handoffs/` in the current project, not in the OS temp
directory the skill suggests: `.prompts/handoffs/<timestamp>-<topic>.md`, one
file per topic. `<timestamp>` is the local creation time as `YYYYMMDD-HHMMSS`
(from `date +%Y%m%d-%H%M%S`, e.g. `20261108-143005-pki-renewal.md`), so sorting
by filename lists the handoffs oldest first. Never overwrite existing files
there.

## Worktrees

Create every git worktree with the global mise task
`mise run worktree:add <branch>`, also where a skill or `EnterWorktree` would
place it elsewhere. Run it in the repository the work belongs to: the task
acts on the git repository of the current directory, a repository nested
inside another one included. It reports where the worktree lands (`<repo>.worktrees/<branch>`)
and, inside herdr, opens it as its own herdr workspace. Pass `--open` (an
extra VS Code window) only when the owner asks for it.

`mise run worktree:finish <branch>` merges the branch into `main` (`--no-ff`,
no push) and removes branch and worktree. Run it from the main checkout: from
inside the worktree's herdr workspace, herdr closes that workspace with every
process in it.

An OpenRig seat (`OPENRIG_NODE_ID` is set) is the exception: it creates its
worktrees the way its rig role says (the workshop builder under `.worktrees/`
in the repository) and never runs `worktree:add` or `worktree:finish`.
