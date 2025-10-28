#!/usr/bin/env bash

clear

# installl brew
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed. Skipping installation."
fi

# install mise
if [ ! -f "$HOME/.local/bin/mise" ]; then
  curl https://mise.run | sh
else
  echo "Mise already installed. Skipping installation."
fi

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

# Installs Homebrew packages (formulas and casks) as specified in config.yml
# - Reads the list of brew packages from the config file
# - Iterates through each package and checks if it's a cask or formula
# - Installs casks using 'brew install --cask' for GUI applications
# - Installs formulas using 'brew install' for CLI tools and libraries
# - All output is suppressed for cleaner terminal display
install_custom_tools() {
  # Read custom packages from config.yml
  CUSTOM_PACKAGES=$(yq -r '.custom[]' "$CONFIG_FILE" | tr '\n' ' ')

  echo ""
  echo "🔸 Installing brew formulas and casks..."

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
    stow "$stow"
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

# prepare
# ask_for_user_details
# install_brew_packages
install_custom_tools
# install_mise_tools
# install_global_npm_packages
# stow_dotfiles
# create_user_specific_files

readme=$(cat <<EOF
# Finished setup!

## Please complete the following tasks to finalise the setup:

- Apply the changes to your ~/.zshrc

> Note: If you encounter any issues, please contact the author.
EOF
)

echo "$readme" | gum format
