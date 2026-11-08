if [[ "$CLAUDECODE" != "1" ]]; then
    alias cat='bat'

    export MANPAGER="bat -l man -p"
fi
