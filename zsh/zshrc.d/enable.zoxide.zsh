# do not load in claude code
if command -v zoxide &>/dev/null && [[ "$CLAUDECODE" != "1" ]]; then
	eval "$(zoxide init --cmd cd zsh)"
fi
