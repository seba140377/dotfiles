# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/Users/seba/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

bold=$(tput bold)
normal=$(tput sgr0)
blue=$(tput setaf 4)

VERBOSE="true"
BANNER="true"

# only echo if VERBOSE is set to true
function verbose_echo() {
  if [[ $VERBOSE == "true" ]]; then
    echo "$@"
  fi
}

autoload -Uz compinit
compinit

# DO NOT USE ~ in PATH, use $HOME instead
export PATH="$HOME/.local/bin:$PATH"

# Brew
eval $(/opt/homebrew/bin/brew shellenv)

# Git
LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nano'
else
  export EDITOR='nano'
fi

# Set personal aliases in any file matching *.aliases.zsh in the zshrc.d directory
#
# ZSH aliases
alias zshconfig="code ~/.zshrc"
alias zshreload="source ~/.zshrc"

# === [START] ZINIT ===
# see: https://github.com/vfarcic/dotfiles/blob/main/.zshrc

ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

# Install if not exists
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Commonly used plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light Aloxaf/fzf-tab
zinit light fdellwing/zsh-bat

# OMZ plugin
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# eza complitions
zinit ice as"completion" depth="1"
zinit snippet https://github.com/eza-community/eza/blob/main/completions/zsh/_eza

# vscode completions
zinit ice as"completion" depth="1"
zinit snippet https://github.com/microsoft/vscode/blob/main/resources/completions/zsh/_code

# Load completions
autoload -Uz compinit && compinit
autoload -Uz +X bashcompinit && bashcompinit

# Durch zinit cdreplay werden die Plugins aus dem Cache erneut geladen und aktiviert, ohne dass ein erneuter Download erforderlich ist.
zinit cdreplay -q

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
zstyle ':completion:*' menu yes select

# HISTORY
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color $realpath'

# === [START] ZSHRC.D AND ALIASES ===

verbose_echo ""
verbose_echo "🚀 ${bold}${blue}Enable ZSH Tools${normal}"
verbose_echo ""
files=($HOME/zshrc.d/enable.*.zsh)
if (( ${#files[@]} > 0 )); then
  for f in "${files[@]}"; do
    verbose_echo "   • $(basename "$f")..."
    source "$f"
  done
else
  verbose_echo "   x No zsh enable scripts available."
fi

verbose_echo ""
verbose_echo "🚀 ${bold}${blue}Enable ZSH Functions${normal}"
verbose_echo ""
files=($HOME/zshrc.d/functions.*.zsh)
if (( ${#files[@]} > 0 )); then
  for f in "${files[@]}"; do
    verbose_echo "   • $(basename "$f")..."
    source "$f"
  done
else
  verbose_echo "   x No zsh function scripts available."
fi

verbose_echo ""
verbose_echo "🚀 ${bold}${blue}Enable YADE aliases${normal}"
verbose_echo ""
files=($HOME/zshrc.d/aliases.*.zsh)
if (( ${#files[@]} > 0 )); then
  for f in "${files[@]}"; do
    verbose_echo "   • $(basename "$f")..."
    source "$f"
  done
else
  verbose_echo "   x No zsh alias scripts available."
fi

# # === [END] ZSHRC.D AND ALIASES ===

# if BANNER is set to true, show the welcome banner
if [[ $BANNER == "true" ]]; then
  verbose_echo ""
  # clear
  ~/dotfiles/welcome-banner.sh
fi
