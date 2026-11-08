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
