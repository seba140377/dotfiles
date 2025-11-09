if [[ -x ~/.local/bin/mise ]]; then
  # https://mise.jdx.dev/getting-started.html#activate-mise
  eval "$(~/.local/bin/mise activate zsh)"

  # https://mise.jdx.dev/cli/completion.html#flags
  ~/.local/bin/mise completion zsh > ~/.local/share/zinit/completions/_mise
fi
