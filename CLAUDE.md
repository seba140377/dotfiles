# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal macOS dotfiles repository that uses GNU Stow for symlink management, Homebrew for package installation, and mise for development tool management. The repository is structured to allow declarative configuration through `config.yml` and automated setup through shell scripts.

## Architecture

### Configuration-Driven Design

All package installations and stow operations are defined in `config.yml`:
- `brews`: Homebrew formulas and casks to install (`cask: true` for casks)
- `custom`: Custom tools requiring specialized installation scripts (located in `custom/install_<name>.sh`)
- `mise`: Development tools managed by mise (also duplicated in `mise/.config/mise/config.toml`)
- `npm`: Global npm packages to install
- `pip`: Global pip packages to install
- `claude`: Claude Code plugin `marketplaces` (GitHub `owner/repo`) and `plugins` (`<plugin>@<marketplace>`) to ensure are installed, plus `permissions.deny` rules merged into `~/.claude/settings.json` (currently: all write tools of the claude.ai Gmail, Google Calendar and Google Drive connectors, which stay read-only)
- `stows`: Directories to symlink using GNU Stow

### Directory Structure Pattern

Each stow package (e.g., `zsh/`, `git/`, `mise/`) contains a directory tree that mirrors the home directory structure. Most packages follow the XDG layout under `.config/`. When stowed, files are symlinked to their corresponding locations:
- `git/.gitconfig` → `~/.gitconfig` (and `git/.gitignore` → `~/.gitignore`, used as the global `core.excludesfile`)
- `zsh/.config/zsh/` → `~/.config/zsh/`
- `mise/.config/mise/` → `~/.config/mise/`
- `nvim/.config/nvim/` → `~/.config/nvim/` (LazyVim-based config)
- `herdr/`, `wezterm/`, `zellij/`, `starship/`, `atuin/`, `neofetch/` → their respective `~/.config/...` paths
- `notes/notes/` → `~/notes/`
- `claude/.claude/` → `~/.claude/` (only `statusline.sh` and `statusline-wrapper.sh`; the rest of `~/.claude/` is not managed by stow)
- `vscode/Library/Application Support/Code/User/` → `~/Library/Application Support/Code/User/` (only `settings.json` and `keybindings.json`; these belong to the default profile; additional VS Code profiles only pick them up if they are set to use the default profile's settings/keybindings)

The stow target is always `$HOME`, independent of where the repo is cloned (currently `~/projects/seba140377/src/dotfiles`): `setup.sh` calls `stow -d <repo> -t "$HOME"`, and `.stowrc` (`--target=~`) does the same for manual `stow` commands run from the repo root. `.stow-local-ignore` excludes repo-level files (`setup.sh`, `config.yml`, `CLAUDE.md`, etc.) from stowing. `setup.sh` stows without `--adopt`: existing real files at target paths in `$HOME` cause a stow conflict for that package instead of being pulled into the repo. Resolve by moving the file away, or run `stow --adopt <package>` manually and check `git diff`.

### ZSH Configuration Architecture

ZSH uses `ZDOTDIR=~/.config/zsh`. This is set by `/etc/zshenv` (outside the repo, a manual prerequisite; `setup.sh` does not create it). There is no `~/.zshrc`.

Files in `zsh/.config/zsh/`:
- `.zshenv`: XDG base dirs, `EDITOR`/`VISUAL` (nano), `GPG_TTY`, `~/.local/bin` on `PATH`, Homebrew shellenv
- `.zprofile`: Homebrew shellenv
- `.zshrc`: history, shell options, `mise activate`, `compinit`, then sources modular scripts from `$ZDOTDIR/zshrc.d/` and runs `welcome-banner.sh`. `VERBOSE` and `BANNER` flags at the top control startup output.
- `completions/`: Checked-in completion files for `mise` and `zellij` (built-in generation doesn't work; regenerate manually after upgrading those tools — see comments in `enable.mise.zsh` / `enable.zellij.zsh`)
- `welcome-banner.sh`: MOTD-style banner (system info, greeting, last login)

Modular scripts in `zsh/.config/zsh/zshrc.d/`, loaded in this order:
- `enable.*.zsh`: Tool activation (atuin, fzf, herdr, mise, plugins, pnpm, starship, thefuck, zellij, zoxide)
- `functions.*.zsh`: Custom shell functions (`zshreload`)
- `aliases.*.zsh`: Tool-specific aliases (bat, eza, fzf, git incl. `gac`/`gacp` functions, kubectl, mise, ripgrep)

Scripts renamed to `*.zsh_disabled` are not loaded (currently: flux, flux-operator, helm, homelab-cli, kubectl). Rename back to `.zsh` to enable.

Plugins are managed without a plugin manager by `enable.plugins.zsh`: `_zplugin_load <owner> <repo>` shallow-clones into `$ZDOTDIR/plugins/` on first use; `zplugin-update` pulls all of them. Loaded: zsh-autosuggestions, zsh-history-substring-search, zsh-vi-mode, fast-syntax-highlighting.

Some scripts skip setup inside Claude Code (`$CLAUDECODE == 1`): the `cat`→`bat` alias and the `cd`→zoxide override.

### User-Specific Configuration

The setup process creates `~/.user_details` (YAML format with name/email) and generates `~/.gitconfig.local` to include user-specific git configuration. The main `.gitconfig` includes this via:
```
[include]
    path = .gitconfig.local
```

### mise Configuration Hierarchy

There are two mise configuration files:
- **`mise.toml`** (repository root): Project-specific configuration; its `enter` hook runs `mise i` and `pre-commit install` when entering the directory
- **`mise/.config/mise/config.toml`** (stowed to `~/.config/mise/config.toml`): Global tool versions, `experimental = true`, and environment variables (SOPS/Age configuration)

The tool list in `config.yml` (`mise:`) and `[tools]` in `mise/.config/mise/config.toml` must be kept in sync when adding tools. Version pins may be expressed as `tool@version` in `config.yml` and `tool = "version"` in the TOML.

### Global mise Tasks

Task scripts in `mise/.config/mise/tasks/` are stowed to `~/.config/mise/tasks/` and become available as `mise run <task>` in any project once mise is activated:
- `pre-commit:install`: Installs pre-commit hooks in the current project
- `python:install-requirements`: Installs Python packages from `requirements.txt` via `uv pip install`
- `secrets:show <file>`: Shows the decrypted contents of a SOPS-encrypted secrets file (default: `.creds.env.yaml`)
- `secrets:edit <file>`: Opens a SOPS-encrypted secrets file for editing with SOPS (default: `.creds.env.yaml`)

## Common Commands

### Full System Setup
```bash
./setup.sh
```
Installs Homebrew and mise, prompts for user details, installs brew/custom/mise tools, Claude Code plugins, npm and pip packages, stows dotfiles, and writes `~/.gitconfig.local`. Paths (`config.yml`, `custom/`, the stow directory) are resolved relative to the script via `DOTFILES_DIR`, so it can be run from any directory.

### Partial Setup Flags
```bash
./setup.sh --dotfiles  # Only symlink dotfiles (stow), no package installation
./setup.sh --brew      # Only install Homebrew formulas and casks
./setup.sh --custom    # Only run custom/install_*.sh scripts
./setup.sh --mise      # Only install mise-managed tools
./setup.sh --npm       # Only install global npm packages
./setup.sh --pip       # Only install global pip packages
./setup.sh --claude    # Only add Claude Code marketplaces, install plugins, set the statusLine and merge permissions.deny in ~/.claude/settings.json (idempotent; needs ~/.local/bin/claude)
```
Useful for testing configuration changes or re-running a single install step without a full setup.

### Manual Stow Operations
```bash
# Run from the repo root so .stowrc (--target=~) is picked up
stow <package>      # Symlink a single package
stow -R <package>   # Restow after adding/removing files
stow -D <package>   # Remove a package's symlinks
stow -n -v <package> # Dry run
```

### Teardown/Uninstall
```bash
./teardown.sh
```
**Note**: Currently disabled. The script needs to be manually uncommented before use. Would unstow all dotfiles.

### Adding Packages
- **Homebrew**: add to `brews` in `config.yml` (with `cask: true` for casks), run `./setup.sh --brew`
- **mise tool**: add to `mise` in `config.yml` **and** `[tools]` in `mise/.config/mise/config.toml`, run `./setup.sh --mise`
- **Custom tool**: create an idempotent `custom/install_<name>.sh`, add `<name>` to `custom` in `config.yml`
- **Stow package**: create `<name>/<path-from-home>/...`, add to `stows` in `config.yml`, run `stow <name>`
- **Shell integration**: add `zsh/.config/zsh/zshrc.d/enable.<tool>.zsh` guarded by `command -v <tool>`

## Important Files

- `config.yml`: Single source of truth for all installations
- `setup.sh`: Main setup orchestration script
- `teardown.sh`: Cleanup and uninstall script (currently disabled)
- `mise.toml`: Root-level mise configuration with pre-commit hooks
- `mise/.config/mise/config.toml`: Global mise tool versions and environment variables
- `.pre-commit-config.yaml`: Pre-commit hooks (gitleaks secrets scan, end-of-file-fixer, trailing-whitespace)
- `.stow-local-ignore`: Repo-level files excluded from stowing
- `.stowrc`: Default stow options (`--target=~`) for manual `stow` commands run from the repo root
- `zsh/.config/zsh/.zshrc`: Main ZSH configuration with modular loading
- `zsh/.config/zsh/zshrc.d/`: Modular ZSH scripts for tool activation, plugins, aliases, and functions
- `git/.gitconfig`: Git configuration (includes user-specific local config)
- `git/.gitignore`: Global git excludes (also ignores `.gitconfig.local`, secrets, keys)
- `nvim/.config/nvim/`: Neovim (LazyVim) configuration, adapted from omerxx/dotfiles
- `herdr/.config/herdr/`: herdr configuration and herdr-plus plugin config (plugin auto-installed by `enable.herdr.zsh`)
- `vscode/Library/Application Support/Code/User/settings.json`: VS Code user settings (incl. `terminal.integrated.rightClickBehavior: nothing` so herdr gets the right-click); `keybindings.json` next to it
- `wezterm/.config/wezterm/wezterm.lua`: WezTerm terminal configuration
- `claude/.claude/statusline.sh`: Claude Code statusline generated by [cc-statusline](https://github.com/chongdashu/cc-statusline) (`npx @chongdashu/cc-statusline@latest init`, then move the result from `~/.claude/statusline.sh` into the repo and `stow -R claude` — the generator ignores `--output` and writes nothing with `--no-install`)
- `claude/.claude/statusline-wrapper.sh`: The actual `statusLine` command; forwards the JSON payload to Orca's hook (`~/.orca/agent-hooks/claude-statusline.sh`, if present) in the background, then runs `statusline.sh`. `configure_claude_statusline` in `setup.sh` writes only the `.statusLine` key and `configure_claude_permissions` only adds to `.permissions.deny` of `~/.claude/settings.json` (backup in `settings.json.bak`); `settings.json` itself is not stowed
- `custom/install_*.sh`: Custom installation scripts (bash-commons, claude-code, vault-mcp-server)
- `~/.user_details`: User-specific details (name, email) in YAML format
