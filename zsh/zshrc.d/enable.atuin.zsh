if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
	eval "$(atuin gen-completions --shell zsh)"
fi
