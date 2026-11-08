# dotfiles

Personal macOS dotfiles, managed declaratively with [GNU Stow](https://www.gnu.org/software/stow/), [Homebrew](https://brew.sh) and [mise](https://mise.jdx.dev).

`config.yml` lists the packages and dotfile sets, `stow/mise/.config/mise/config.toml` the global mise tools; `setup.sh` turns them into a working machine and the weekly `pkg-update` routine keeps them current.

<details>
<summary>Table of Contents</summary>

- [About](#about)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Repository Layout](#repository-layout)
- [ZSH](#zsh)
- [Global mise Tasks](#global-mise-tasks)
- [Adding Things](#adding-things)
- [Keeping Packages Current](#keeping-packages-current)
- [Acknowledgments](#acknowledgments)

</details>

## About

### What's Included

| Area | Tools |
| --- | --- |
| Shell | zsh (XDG layout, no plugin manager), [starship](https://starship.rs), [atuin](https://atuin.sh), fzf, zoxide, eza, bat, ripgrep, fd |
| Terminal & editor | [WezTerm](https://wezterm.org), [zellij](https://zellij.dev), [herdr](https://herdr.dev), [Neovim](https://neovim.io) ([LazyVim](https://www.lazyvim.org)) |
| Dev runtimes | mise, Node 26.13, Python 3.14, pre-commit, gitleaks |
| Kubernetes | kubectl, kubectx/kubens, helm, kustomize, flux2, flux-operator, kubeconform, k9s, Headlamp |
| Secrets | sops, age, vault, gnupg |
| Other | OrbStack, GitHub CLI, glab, restic, [Claude Code](https://claude.com/claude-code) + plugins |

See [`config.yml`](config.yml) (Homebrew, custom, npm, Claude) and [`stow/mise/.config/mise/config.toml`](stow/mise/.config/mise/config.toml) (mise tools) for the authoritative lists.

### Built With

- [GNU Stow](https://www.gnu.org/software/stow/) – symlink farm manager
- [Homebrew](https://brew.sh) – formulas and casks
- [mise](https://mise.jdx.dev) – dev tool versions, env vars and tasks
- [yq](https://github.com/mikefarah/yq) and [gum](https://github.com/charmbracelet/gum) – used by `setup.sh`

## Getting Started

### Prerequisites

- macOS on Apple Silicon (Homebrew path `/opt/homebrew` is assumed)
- `git` and an internet connection
- The repo cloned anywhere, e.g. `~/projects/seba140377/src/dotfiles` (`setup.sh` resolves paths relative to itself and stows into `$HOME`)
- `ZDOTDIR` pointing at `~/.config/zsh`. Add this to `/etc/zshenv` (requires `sudo`):

  ```zsh
  if [[ -z "$XDG_CONFIG_HOME" ]]; then
      export XDG_CONFIG_HOME="$HOME/.config"
  fi

  if [[ -d "$XDG_CONFIG_HOME/zsh" ]]; then
      export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
  fi
  ```

### Installation

```bash
git clone git@github.com:abes140377/dotfiles.git ~/projects/seba140377/src/dotfiles
cd ~/projects/seba140377/src/dotfiles
./setup.sh
```

`setup.sh` will:

1. Install Homebrew and mise (if missing), plus `yq` and `gum`
2. Ask for your name and email (stored in `~/.user_details`)
3. Install Homebrew formulas/casks, custom tools and mise tools
4. Add Claude Code plugin marketplaces, install plugins, configure the statusline and permission deny rules
5. Install global npm packages (into every installed mise Node version, and via `~/.default-npm-packages` into every future one) and pip packages
6. Stow all dotfiles and write `~/.gitconfig.local`

> [!WARNING]
> Dotfiles are stowed without `--adopt`: if a real file already exists at a target path in `$HOME`, stow reports a conflict and skips that package. Move or delete the existing file (or run `stow --adopt <package>` manually and review `git diff`), then re-run `./setup.sh --dotfiles`.

## Usage

Run a single step instead of the full setup (always from the repo root):

```bash
./setup.sh --dotfiles  # Stow dotfiles only
./setup.sh --brew      # Homebrew formulas and casks
./setup.sh --custom    # custom/install_*.sh scripts
./setup.sh --mise      # mise tools
./setup.sh --npm       # Global npm packages
./setup.sh --pip       # Global pip packages
./setup.sh --claude    # Claude Code marketplaces, plugins, statusline and permissions (requires Claude Code)
```

Manual stow operations (run from the repo root; `.stowrc` sets `--dir=stow --target=~`):

```bash
stow <package>        # Symlink a package
stow -R <package>     # Restow after adding/removing files
stow -D <package>     # Remove a package's symlinks
stow -n -v <package>  # Dry run
```

`./teardown.sh` is currently disabled.

## Repository Layout

Each stow package mirrors `$HOME`:

```
dotfiles/
├── config.yml            # Single source of truth: brews, custom, npm, pip, claude, stows
├── setup.sh              # Setup orchestration
├── mise.toml             # Repo-local mise config (installs pre-commit hooks on enter)
├── custom/               # install_<name>.sh scripts for tools not in brew/mise
│   ├── ekread/           # read-only EventKit CLI (calendars, reminders → JSON); test: custom/ekread/test.sh
│   └── pkg-update/       # weekly brew/mise update routine (launchd); test: custom/pkg-update/test.sh
└── stow/                 # Stow directory: one package per entry in `stows`
    ├── zsh/.config/zsh/      # → ~/.config/zsh/
    ├── git/.gitconfig        # → ~/.gitconfig  (includes ~/.gitconfig.local)
    ├── git/.gitignore        # → ~/.gitignore  (global excludes)
    ├── mise/.config/mise/    # → ~/.config/mise/ (global tools + mise.lock, env, tasks)
    ├── nvim/.config/nvim/    # → ~/.config/nvim/
    ├── claude/.claude/       # → ~/.claude/statusline*.sh (cc-statusline + Orca wrapper), global CLAUDE.md
    ├── codex/.codex/         # → ~/.codex/config.toml
    ├── vscode/Library/…      # → ~/Library/Application Support/Code/User/
    ├── wezterm/, zellij/, herdr/, starship/, atuin/, neofetch/   # → ~/.config/...
    └── notes/notes/          # → ~/notes/
```

Only `stow/` is stowed (`setup.sh` and `.stowrc` use it as the stow directory); scripts, docs and `config.yml` in the repo root are never linked into `$HOME`.

## ZSH

`~/.config/zsh/.zshrc` sets history, options and completion, activates mise, then sources scripts from `zshrc.d/`:

| Pattern | Purpose |
| --- | --- |
| `enable.*.zsh` | Tool activation and plugins |
| `functions.*.zsh` | Shell functions (e.g. `zshreload`) |
| `aliases.*.zsh` | Aliases (`ls`→eza, `cat`→bat, `grep`→rg, git, kubectl, mise, fzf) |

- Rename a script to `*.zsh_disabled` to skip it.
- Plugins (autosuggestions, history-substring-search, vi-mode, fast-syntax-highlighting) are cloned on first start by `enable.plugins.zsh`; update them with `zplugin-update`.
- `mise` and `zellij` completions are checked in under `completions/` and must be regenerated after upgrading those tools.
- Set `VERBOSE` / `BANNER` at the top of `.zshrc` to control startup output.

## Global mise Tasks

Stowed to `~/.config/mise/tasks/` and available everywhere via `mise run <task>`:

| Task | Description |
| --- | --- |
| `pre-commit:install` | Install pre-commit hooks in the current project |
| `python:install-requirements` | Install `requirements.txt` via `uv pip install` |
| `secrets:show [file]` | Show a decrypted SOPS file (default `.creds.env.yaml`) |
| `secrets:edit [file]` | Edit a SOPS file (default `.creds.env.yaml`) |
| `worktree:add <branch> [--open] [--carry <file>]… [--agent <prompt>]` | Create a git worktree at `<repo>.worktrees/<branch>` (`/` → `-`), add `<repo>.worktrees` to the VS Code workspace in `~/.config/vscode/` that contains the repo, open it in herdr; `--open` also opens a VS Code window, `--carry` moves untracked files (plan, spec) into the worktree, `--agent` starts Claude Code in the left herdr pane with that prompt |
| `worktree:finish [branch]` | Merge the branch into `main` (`--no-ff`, no push), delete branch and worktree; after the last one, drop `<repo>.worktrees` from the workspace |

SOPS uses the age key at `~/.config/mise/age.txt` (configured in `stow/mise/.config/mise/config.toml`).

## Adding Things

| What | How |
| --- | --- |
| Homebrew package | Add to `brews` in `config.yml` (`cask: true` for casks) → `./setup.sh --brew` |
| mise tool | Add to `[tools]` in `stow/mise/.config/mise/config.toml`, pinned as `<major>.<minor>` → `./setup.sh --mise`, then `mise lock --global` in `~` |
| Custom tool | Create an idempotent `custom/install_<name>.sh`, add `<name>` to `custom` |
| Stow package | Create `stow/<name>/<path-from-home>/…`, add to `stows` → `stow <name>` |
| Claude plugin | Add to `claude.marketplaces` / `claude.plugins` → `./setup.sh --claude` |
| Claude permission rule | Add to `claude.permissions.deny` → `./setup.sh --claude` |

Commits run [pre-commit](https://pre-commit.com) hooks (gitleaks, end-of-file-fixer, trailing-whitespace).

## Keeping Packages Current

The `pkg-update` routine (`custom/pkg-update/`, launchd agent `de.seba140377.pkg-update`, Sundays 18:00) runs `brew update/upgrade/autoremove/cleanup`, `mise self-update` and, for the global tools, `mise upgrade` within their `<major>.<minor>` pins (patch versions only), `mise lock --global` and `mise prune`. It commits a changed `stow/mise/.config/mise/mise.lock` to `main` (no push) and sends a notification that names newer minor/major versions and Homebrew packages that differ from `config.yml`. It changes neither pins nor the brew list: raise a pin by hand with `mise upgrade --bump <tool>` in `~`, then `mise lock --global` and commit. Clicking the notification (sent by `terminal-notifier`; allow it once under System Settings → Notifications) opens the report `~/Library/Logs/pkg-update-report.md`, which lists what was updated and, under "Zu tun", copyable commands for whatever is left. Log: `~/Library/Logs/pkg-update.log`; run now with `launchctl kickstart gui/$(id -u)/de.seba140377.pkg-update`.

## Acknowledgments

- Neovim config adapted from [omerxx/dotfiles](https://github.com/omerxx/dotfiles)
- README structure based on [Best-README-Template](https://github.com/othneildrew/Best-README-Template)
