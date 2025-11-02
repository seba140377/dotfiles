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
- `npm`: Global npm packages to install
- `stows`: Directories to symlink using GNU Stow

### Directory Structure Pattern

Each stow package (e.g., `zsh/`, `git/`, `mise/`) contains a directory tree that mirrors the home directory structure. When stowed, files are symlinked to their corresponding locations:
- `git/.gitconfig` → `~/.gitconfig`
- `mise/.config/mise/config.toml` → `~/.config/mise/config.toml`
- `zsh/.zshrc` → `~/.zshrc`

### ZSH Configuration Architecture

The `.zshrc` (in `zsh/.zshrc`) uses a modular loading system that sources scripts from `~/zshrc.d/`:
- `enable.*.zsh`: Tool activation scripts (mise, starship, atuin, fzf, zoxide, thefuck)
- `aliases.*.zsh`: Tool-specific aliases (bat, eza, fzf, mise)
- `functions.*.zsh`: Custom shell functions (git)

These scripts are stored in `zsh/zshrc.d/` and stowed to `~/zshrc.d/`.

### User-Specific Configuration

The setup process creates `~/.user_details` (YAML format with name/email) and generates `~/.gitconfig.local` to include user-specific git configuration. The main `.gitconfig` includes this via:
```
[include]
    path = .gitconfig.local
```

### mise Configuration Hierarchy

There are two mise configuration files:
- **`mise.toml`** (repository root): Project-specific configuration with pre-commit hooks that auto-install when entering the directory
- **`mise/.config/mise/config.toml`** (stowed to `~/.config/mise/config.toml`): Global tool versions and environment variables (SOPS/Age configuration)

Additional tools in global config not in `config.yml`: `python` (3.12), `yq`

## Installed Tools & Packages

### Homebrew Packages
- **Shell**: zsh
- **Utilities**: wget, stow, git, dos2unix, figlet
- **Tools**: thefuck, neofetch
- **Containers**: orbstack (cask)

### mise-managed Tools
- **Shell Enhancement**: starship, atuin, zoxide, fzf, zellij
- **File Utilities**: bat, eza
- **CLI Tools**: gum, jq, yq
- **Security**: sops, age
- **Development**: node@lts, pnpm, python (3.12), claude

### npm Global Packages
- `oclif`: CLI framework
- `@fission-ai/openspec@latest`: OpenAPI specification tool

### Custom Installation Scripts
Located in `custom/install_*.sh`:
- **runbook**: Documentation/runbook management
- **bash-commons**: Common bash utilities library
- **pocketbase**: Lightweight database/backend
- **mu-repo**: Multi-repository management tool

### Stow Packages
Currently configured stow packages: `atuin`, `zsh`, `git`, `mise`, `starship`, `zellij`, `neofetch`, `claude`, `notes`

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
**Note**: Currently disabled. The script needs to be manually uncommented before use. Would unstow all dotfiles and remove installed configurations.

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

1. Add to `config.yml` under the appropriate section (`brews`, `mise`, `npm`)
2. If using mise, also add to `mise/.config/mise/config.toml`
3. Test with `./setup.sh`

### Adding a New npm Global Package

1. Add to `config.yml` under `npm` section
2. Run `./setup.sh` or install manually with `npm install -g <package>`

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
- `teardown.sh`: Cleanup and uninstall script (currently disabled)
- `mise.toml`: Root-level mise configuration with pre-commit hooks
- `mise/.config/mise/config.toml`: Global mise tool versions and environment variables
- `zsh/.zshrc`: Main ZSH configuration with modular loading
- `zsh/zshrc.d/`: Modular ZSH scripts for tool activation, aliases, and functions
- `git/.gitconfig`: Git configuration (includes user-specific local config)
- `custom/install_*.sh`: Custom installation scripts (runbook, bash-commons, pocketbase, mu-repo)
- `~/.user_details`: User-specific details (name, email) in YAML format
