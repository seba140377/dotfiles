if command -v zellij >/dev/null 2>&1; then
  # Does not work see: Zellij-GitHub-Issue https://github.com/zellij-org/zellij/issues/1933
  # eval "$(zellij setup --generate-completion zsh)"

  # Generate completions manually since the built-in method does not work
  # !!! Must be regenerated whenever Zellij is updated !!!
  #   mkdir -p $HOME/projects/seba140377/src/dotfiles/zsh/.config/zsh/completions
  #   zellij setup --generate-completion zsh > $HOME/projects/seba140377/src/dotfiles/zsh/.config/zsh/completions/_zellij

  fpath+=("$ZDOTDIR/completions")
  autoload -Uz _zellij
  compdef _zellij zellij
fi
