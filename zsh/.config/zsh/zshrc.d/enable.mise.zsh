# if [[ -x ~/.local/bin/mise ]]; then
#   # https://mise.jdx.dev/getting-started.html#activate-mise
#   # eval "$(~/.local/bin/mise activate zsh)"

#   # https://mise.jdx.dev/cli/completion.html#flags
#   ~/.local/bin/mise completion zsh > ~/.local/share/zinit/completions/_mise
# fi

if command -v mise >/dev/null 2>&1; then
  # Generate completions manually since the built-in method does not work
  # !!! Must be regenerated whenever Mise is updated !!!
  #   mkdir -p $HOME/dotfiles/zsh/.config/zsh/completions
  #   mise completion zsh > $HOME/dotfiles/zsh/.config/zsh/completions/_mise

  fpath+=("$ZDOTDIR/completions")
  autoload -Uz _mise
  compdef _mise mise
fi
