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
`mise run worktree:add <branch>`, also where a skill
(`superpowers:using-git-worktrees`) or `EnterWorktree` would place it
elsewhere. Run it in the repository the work belongs to: the task acts on the
git repository of the current directory, a repository nested inside another
one included. It reports where the worktree lands (`<repo>.worktrees/<branch>`)
and, inside herdr, opens it as its own herdr workspace. Pass `--open` (an
extra VS Code window) only when the owner asks for it.

`mise run worktree:finish <branch>` merges the branch into `main` (`--no-ff`,
no push) and removes branch and worktree. Run it from the main checkout: from
inside the worktree's herdr workspace, herdr closes that workspace with every
process in it.

### Worktree session (herdr)

A **worktree session** is a fresh Claude Code session that executes a finished
superpowers plan in its own git worktree. The global task
`mise run worktree:add` creates the worktree with its own herdr workspace (left
pane: the agent, right pane: the owner's shell), starts Claude Code in the
left pane and hands it the plan. It applies when `HERDR_ENV=1`.

**Planning session.** At the execution choice of `superpowers:writing-plans`,
offer a third option next to Subagent-driven and Native: *Worktree session*,
naming the branch you propose (`feat/<topic>`, `fix/<topic>`, …). When the
owner picks it, or in any wording asks to hand the execution to a new session
or agent, also settle the method the worktree session uses (Subagent-driven or
Native, with your recommendation as writing-plans gives it). Then:

1. Commit the changes to tracked files the work needs (the worktree starts
   from `HEAD`); untracked files (the plan, a spec not yet committed) travel
   with `--carry`.
2. From the main checkout run
   `mise run worktree:add <branch> --carry <plan> [--carry <spec>] --agent "<prompt>"`,
   with this prompt, placeholders filled:
   > You are the worktree session for the plan `<plan>` (spec `<spec>`). Your
   > cwd is the worktree `<path>` on branch `<branch>`, created by
   > `mise run worktree:add`: it is the isolated workspace the plan runs in.
   > First commit the carried files (`<files>`) on this branch. Then execute
   > the plan with `superpowers:<subagent-driven-development|executing-plans>`.
   > Finish by summarising the result and leave the branch unmerged and
   > unpushed: the owner merges with `mise run worktree:finish <branch>` from
   > the main checkout.
3. Your part ends when the task reports that Claude Code took over: tell the
   owner the branch and the herdr workspace, and stop.

**Worktree session.** The worktree from the prompt is your workspace for
`superpowers:using-git-worktrees`. At `superpowers:finishing-a-development-branch`,
keep the branch as it is and report; `worktree:finish` is the owner's step.
