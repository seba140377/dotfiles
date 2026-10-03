#!/usr/bin/env bash

clear

zshrc="${ZDOTDIR:-$HOME}/.zshrc"
zprofile="${ZDOTDIR:-$HOME}/.zprofile"
mkdir -p "$(dirname "$zshrc")"
mkdir -p "$(dirname "$zprofile")"

# installl brew
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed. Skipping installation."
fi

activation='eval "$(/opt/homebrew/bin/brew shellenv zsh)"'
grep -qxF "$activation" "$zprofile" 2>/dev/null || printf '%s\n' "$activation" >> "$zprofile"

# install mise
if [ ! -f "$HOME/.local/bin/mise" ]; then
  curl https://mise.run | sh
else
  echo "Mise already installed. Skipping installation."
fi

activation='eval "$(mise activate zsh)"'
grep -qxF "$activation" "$zshrc" 2>/dev/null || printf '%s\n' "$activation" >> "$zshrc"

#
CONFIG_FILE="config.yml"

# Prepares the environment by activating mise and installing required tools
# - Activates mise for the shell
# - Installs yq (YAML processor) globally
# - Installs gum (shell script UI tool) globally
# - Runs mise install to ensure all tools are available for further use
prepare() {
  # Activate mise for the bash shell because this script is run using bash
  eval "$($HOME/.local/bin/mise activate bash)"

  $HOME/.local/bin/mise use -g yq > /dev/null 2>&1
  $HOME/.local/bin/mise use -g gum > /dev/null 2>&1

  $HOME/.local/bin/mise install > /dev/null 2>&1
}

# Prepares the environment by activating mise and installing required tools
# - Activates mise for the shell
# - Installs yq (YAML processor) globally
# - Installs gum (shell script UI tool) globally
# - Runs mise install to ensure all tools are available for further use
ask_for_user_details() {
  # Get existing name and email from ~/.user_details if it exists
  NAME_FROM_CONF=""
  EMAIL_FROM_CONF=""
  if [ -f ~/.user_details ]; then
    NAME_FROM_CONF=$(yq -r '.name' ~/.user_details)
    EMAIL_FROM_CONF=$(yq -r '.email' ~/.user_details)
  fi

  echo ""
  echo "🔸 Ask for user details..."

  # ask for confirmation or allow to re-enter name and email using gum
  NAME=$(gum input --value "$NAME_FROM_CONF" --prompt "   Enter your full name: ")
  EMAIL=$(gum input --value "$EMAIL_FROM_CONF" --prompt "   Enter your email: ")

  # Create content for ~/.user_details with the provided name and email and save it
  {
    echo "name: \"$NAME\""
    echo "email: \"$EMAIL\""
  } > ~/.user_details
}

# Prompts the user for their full name and email address
# - Loads existing values from ~/.user_details if the file exists
# - Uses gum to create interactive input prompts with existing values pre-filled
# - Saves the entered name and email to ~/.user_details in YAML format
# - The stored values are used later to configure git and other tools
install_brew_packages() {
  # Iterate all brew packages from the config file
  BREW_COUNT=$(yq '.brews | length' "$CONFIG_FILE")

  eval $(/opt/homebrew/bin/brew shellenv)

  echo ""
  echo "🔸 Installing brew formulas and casks..."

  for i in $(seq 0 $((BREW_COUNT - 1))); do
    name=$(yq ".brews[$i].name" "$CONFIG_FILE")
    cask=$(yq ".brews[$i].cask" "$CONFIG_FILE")

    if [ "$cask" = "true" ]; then
      echo "   Installing cask: ${name}..."
      brew install -q --cask "$name" > /dev/null 2>&1
    else
      echo "   Installing formula: ${name}..."
      brew install -q "$name" > /dev/null 2>&1
    fi
  done
}

# Installs custom tools using installation scripts from ~/dotfiles/custom/
# - Reads the list of custom packages from the config file
# - For each custom package, executes its corresponding install script
# - Install scripts are expected to be located at ~/dotfiles/custom/install_<package>.sh
# - This allows for flexible installation of tools that require custom setup beyond brew
install_custom_tools() {
  # Read custom packages from config.yml
  CUSTOM_PACKAGES=$(yq -r '.custom[]' "$CONFIG_FILE" | tr '\n' ' ')

  echo ""
  echo "🔸 Installing custom tools..."

  for pkg in $CUSTOM_PACKAGES; do
    echo ""
    echo "   Installing: $pkg ..."

    bash "$HOME/dotfiles/custom/install_$pkg.sh"
  done
}

# Installs custom tools using installation scripts from ~/dotfiles/custom/
# - Reads the list of custom packages from the config file
# - For each custom package, executes its corresponding install script
# - Install scripts are expected to be located at ~/dotfiles/custom/install_<package>.sh
# - This allows for flexible installation of tools that require custom setup beyond brew
install_mise_tools() {
  # Read mise packages from config.yml
  MISE_PACKAGES=$(yq -r '.mise[]' "$CONFIG_FILE" | tr '\n' ' ')

  echo ""
  echo "🔸 Installing global mise tools..."

  for pkg in $MISE_PACKAGES; do
    echo "   Installing: $pkg ..."

    $HOME/.local/bin/mise use -g "$pkg" > /dev/null 2>&1
  done

  $HOME/.local/bin/mise install
}

install_global_npm_packages() {
  # Read npm packages from config.yml
  NPM_PACKAGES=$(yq -r '.npm[]' "$CONFIG_FILE" | tr '\n' ' ')

  echo ""
  echo "🔸 Installing global npm packages..."

  for pkg in $NPM_PACKAGES; do
    echo "   Installing: $pkg ..."

    npm install --global "$pkg" > /dev/null 2>&1
  done
}

# Installs global pip packages as specified in config.yml
# - Reads the list of pip packages from the config file
# - Iterates through each package and installs it using 'pip install'
# - All output is suppressed for cleaner terminal display
install_global_pip_packages() {
  # Read pip packages from config.yml
  PIP_PACKAGES=$(yq -r '.pip[]' "$CONFIG_FILE" | tr '\n' ' ')

  echo ""
  echo "🔸 Installing global pip packages..."

  for pkg in $PIP_PACKAGES; do
    echo "   Installing: $pkg ..."

    pip install "$pkg" > /dev/null 2>&1
  done
}

# Ensures Claude Code plugin marketplaces and plugins from config.yml are installed
# - Adds each marketplace (GitHub owner/repo) unless it is already registered
# - Installs each plugin (<plugin>@<marketplace>) unless it is already installed
# - Refreshes marketplaces so already installed plugins can be updated
# - Safe to re-run on fresh and existing installations
install_claude_plugins() {
  CLAUDE="$HOME/.local/bin/claude"

  echo ""
  echo "🔸 Installing Claude Code plugins..."

  if [ ! -x "$CLAUDE" ]; then
    echo "   Claude Code not found at $CLAUDE. Run ./setup.sh --custom first."
    return 1
  fi

  MARKETPLACES=$(yq -r '.claude.marketplaces[]' "$CONFIG_FILE" | tr '\n' ' ')
  PLUGINS=$(yq -r '.claude.plugins[]' "$CONFIG_FILE" | tr '\n' ' ')

  known_repos=$("$CLAUDE" plugin marketplace list --json | jq -r '.[].repo // empty')
  for repo in $MARKETPLACES; do
    if echo "$known_repos" | grep -qxF "$repo"; then
      echo "   Marketplace already added: $repo"
    else
      echo "   Adding marketplace: $repo ..."
      "$CLAUDE" plugin marketplace add "$repo" > /dev/null
    fi
  done

  "$CLAUDE" plugin marketplace update > /dev/null 2>&1

  installed=$("$CLAUDE" plugin list --json | jq -r '.[].id // empty')
  for plugin in $PLUGINS; do
    if echo "$installed" | grep -qxF "$plugin"; then
      echo "   Plugin already installed: $plugin"
    else
      echo "   Installing plugin: $plugin ..."
      "$CLAUDE" plugin install "$plugin" --scope user > /dev/null
    fi
  done

  configure_claude_statusline
}

# Points Claude Code's statusLine at the stowed wrapper (claude/.claude/statusline-wrapper.sh)
# - Only touches the .statusLine key; all other settings are preserved
# - Backs up settings.json before changing it; no-op if already configured
configure_claude_statusline() {
  SETTINGS="$HOME/.claude/settings.json"
  STATUSLINE_CMD="~/.claude/statusline-wrapper.sh"

  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

  if [ "$(jq -r '.statusLine.command // empty' "$SETTINGS")" = "$STATUSLINE_CMD" ]; then
    echo "   Statusline already configured"
    return 0
  fi

  echo "   Configuring statusline ..."
  cp "$SETTINGS" "$SETTINGS.bak"
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {type: "command", command: $cmd, padding: 0}' \
    "$SETTINGS.bak" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
}

# Installs development tools and language runtimes globally using mise
# - Reads the list of mise packages from the config file
# - Iterates through each package (e.g., node, python, ruby)
# - Installs each tool globally using 'mise use -g'
# - All output is suppressed for cleaner terminal display
stow_dotfiles() {
  echo ""
  echo "🔸 Stowing dotfiles..."

  # Read stows from config.yml
  STOWS=$(yq -r '.stows[]' "$CONFIG_FILE" | tr '\n' ' ')

  for stow in $STOWS; do
    echo "   Stowing: $stow ..."
    stow "$stow" --adopt
  done
}

# Uses GNU Stow to symlink dotfiles from the repository to the home directory
# - Reads the list of stow packages from the config file
# - For each package, creates symlinks from ~/dotfiles/<package>/ to ~/
# - This allows version-controlled dotfiles to be easily managed and deployed
# - Stow automatically handles directory structures and prevents conflicts
create_user_specific_files() {
  cat > ~/.gitconfig.local <<EOF
[user]
  name = $NAME
  email = $EMAIL
EOF
}

# === Main script ===

# Check for --dotfiles flag
if [ "$1" = "--dotfiles" ]; then
  prepare
  stow_dotfiles
  echo ""
  echo "✅ Dotfiles stowed successfully!"
  exit 0
fi

# Check for --brew  flag
if [ "$1" = "--brew" ]; then
  prepare
  install_brew_packages
  echo ""
  echo "✅ Brew packages installed successfully!"
  exit 0
fi

# Check for --custom flag
if [ "$1" = "--custom" ]; then
  prepare
  install_custom_tools
  echo ""
  echo "✅ Custom tools installed successfully!"
  exit 0
fi

# Check for --mise flag
if [ "$1" = "--mise" ]; then
  prepare
  install_mise_tools
  echo ""
  echo "✅ Mise tools installed successfully!"
  exit 0
fi

# Check for --npm flag
if [ "$1" = "--npm" ]; then
  prepare
  install_global_npm_packages
  echo ""
  echo "✅ Global npm packages installed successfully!"
  exit 0
fi

# Check for --pip flag
if [ "$1" = "--pip" ]; then
  prepare
  install_global_pip_packages
  echo ""
  echo "✅ Global pip packages installed successfully!"
  exit 0
fi

# Check for --claude flag
if [ "$1" = "--claude" ]; then
  prepare
  install_claude_plugins
  echo ""
  echo "✅ Claude Code plugins installed successfully!"
  exit 0
fi

prepare
ask_for_user_details
install_brew_packages
install_custom_tools
install_mise_tools
install_claude_plugins
install_global_npm_packages
install_global_pip_packages
stow_dotfiles
create_user_specific_files

readme=$(cat <<EOF
# ✅ Setup completed successfully!
EOF
)

echo "$readme" | gum format -t markdown
echo ""
