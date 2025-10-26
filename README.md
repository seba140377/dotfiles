# dotfiles

Personal dotfiles managed with GNU Stow, Homebrew, and mise.

## Quick Start

```bash
# Full system setup (first time)
./setup.sh

# Dotfiles only (no package installation)
./setup.sh --dotfiles

# Remove all dotfiles
./teardown.sh
```

## What's Included

- **Shell**: ZSH with modular configuration
- **Tools**: starship, atuin, fzf, eza, bat, zoxide, zellij, gum
- **Dev**: mise, node, claude
- **Git**: Custom configuration with user-specific settings
- **Container**: OrbStack

## Configuration

Everything is defined in `config.yml`:
- `brews`: Homebrew packages and casks
- `mise`: Development tools managed by mise
- `custom`: Custom installation scripts (in `custom/install_<name>.sh`)
- `stows`: Directories to symlink with Stow

## How It Works

### Stow Structure
Each stow package mirrors your home directory:
```
git/.gitconfig       → ~/.gitconfig
zsh/.zshrc          → ~/.zshrc
mise/.config/mise/  → ~/.config/mise/
```

### ZSH Modules
`.zshrc` loads scripts from `~/zshrc.d/`:
- `enable.*.zsh`: Tool activations (mise, starship, atuin, etc.)
- `aliases.*.zsh`: Tool-specific aliases
- `functions.*.zsh`: Custom functions

## Manual Stow Operations

```bash
# Stow a single package
stow <package-name>

# Remove a package
stow -D <package-name>

# Restow (after modifying files)
stow -R <package-name>
```

## Adding New Tools

### Homebrew Package
1. Add to `config.yml` under `brews`
2. Run `./setup.sh` or `brew install <package>`

### mise Tool
1. Add to `config.yml` under `mise`
2. Add to `mise/.config/mise/config.toml`
3. Run `mise install`

### Stow Package
1. Create directory: `<name>/<path-from-home>/file`
2. Add to `stows` in `config.yml`
3. Run `stow <name>`

### Custom Install Script
1. Create `custom/install_<name>.sh`
2. Add to `custom` in `config.yml`
3. Make it idempotent (check if already installed)

## Requirements

- macOS (tested on Darwin 24.6.0)
- Internet connection for package downloads

## User Configuration

On first run, `setup.sh` creates:
- `~/.user_details`: Your name and email (YAML)
- `~/.gitconfig.local`: Git user configuration

The main `.gitconfig` includes the local config automatically.
