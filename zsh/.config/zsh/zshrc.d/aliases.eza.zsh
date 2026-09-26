# Better ls
alias ls='eza --icons auto'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons auto --git'

# Tree view
alias tree='eza --tree --icons auto'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls
