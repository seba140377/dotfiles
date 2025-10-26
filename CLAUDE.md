# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository that uses GNU Stow for symlink management, Homebrew for package installation, and mise for development tool management. The repository is structured to allow declarative configuration through `config.yml` and automated setup through shell scripts.

## Architecture

### Configuration-Driven Design

All package installations and stow operations are defined in `config.yml`:
- `brews`: Homebrew formulas and casks to install
- `custom`: Custom tools requiring specialized installation scripts (located in `custom/install_<name>.sh`)
- `mise`: Development tools managed by mise (also duplicated in `mise/.config/mise/config.toml`)
- `stows`: Directories to symlink using GNU Stow

### Directory Structure Pattern

Each stow package (e.g., `zsh/`, `git/`, `mise/`) contains a directory tree that mirrors the home directory structure. When stowed, files are symlinked to their corresponding locations:
- `git/.gitconfig` → `~/.gitconfig`
- `mise/.config/mise/config.toml` → `~/.config/mise/config.toml`
- `zsh/.zshrc` → `~/.zshrc`

### ZSH Configuration Architecture

The `.zshrc` (in `zsh/.zshrc`) uses a modular loading system that sources scripts from `~/zshrc.d/`:
- `enable.*.zsh`: Tool activation scripts (mise, starship, atuin, fzf, zoxide, thefuck)
- `aliases.*.zsh`: Tool-specific aliases (bat, eza, fzf)
- `functions.*.zsh`: Custom shell functions (git)

These scripts are stored in `zsh/zshrc.d/` and stowed to `~/zshrc.d/`.

### User-Specific Configuration

The setup process creates `~/.user_details` (YAML format with name/email) and generates `~/.gitconfig.local` to include user-specific git configuration. The main `.gitconfig` includes this via:
```
[include]
    path = .gitconfig.local
```

## Common Commands

### Full System Setup
```bash
./setup.sh
```
Installs Homebrew, mise, all packages from config.yml, sets up user details, and stows dotfiles.

### Stow Dotfiles Only
```bash
./setup.sh --dotfiles
```
Only symlinks dotfiles without installing packages. Useful for testing configuration changes.

### Teardown/Uninstall
```bash
./teardown.sh
```
Unstows all dotfiles and removes installed configurations. Restores `~/.zshrc` from backup.

### Working with Stow
```bash
# Stow a single package
stow <package-name>

# Unstow a single package
stow -D <package-name>

# Restow (useful after modifying files)
stow -R <package-name>
```

### Managing mise Tools
```bash
# Install all tools from config
mise install

# Add a new global tool
mise use -g <tool-name>

# List installed tools
mise list
```

## Making Changes

### Adding a New Package Manager Tool

1. Add to `config.yml` under the appropriate section (`brews`, `mise`)
2. If using mise, also add to `mise/.config/mise/config.toml`
3. Test with `./setup.sh`

### Adding a New Stow Package

1. Create directory structure: `<name>/<path-from-home>/file`
2. Add `<name>` to `stows` array in `config.yml`
3. Test with: `stow <name>`

### Adding Custom Installation Scripts

1. Create `custom/install_<name>.sh` script
2. Add `<name>` to `custom` array in `config.yml`
3. Script should be idempotent (check if already installed)

### Modifying ZSH Configuration

- Edit files in `zsh/zshrc.d/` following naming conventions
- Use `stow -R zsh` to update symlinks
- Source new configuration: `source ~/.zshrc`

## Important Files

- `config.yml`: Single source of truth for all installations
- `setup.sh`: Main setup orchestration script
- `teardown.sh`: Cleanup and uninstall script
- `zsh/.zshrc`: Main ZSH configuration with modular loading
- `mise/.config/mise/config.toml`: mise tool versions
- `git/.gitconfig`: Git configuration (includes user-specific local config)
