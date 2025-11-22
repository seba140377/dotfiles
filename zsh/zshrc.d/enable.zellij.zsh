if command -v zellij &> /dev/null; then
  zellij setup --generate-completion zsh > ~/.local/share/zinit/completions/_zellij
fi
