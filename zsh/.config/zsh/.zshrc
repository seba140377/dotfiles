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

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

eval "$(mise activate zsh)"

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# === [START] ZSHRC.D AND ALIASES ===

verbose_echo ""
verbose_echo "🚀 ${bold}${blue}Enable ZSH Tools${normal}"
verbose_echo ""
files=($ZDOTDIR/zshrc.d/enable.*.zsh)
if (( ${#files[@]} > 0 )); then
    for f in "${files[@]}"; do
        verbose_echo "   • $(basename "$f")..."
        source "$f"
    done
else
    verbose_echo "   x No zsh enable scripts available."
fi

# verbose_echo ""
# verbose_echo "🚀 ${bold}${blue}Enable ZSH Functions${normal}"
# verbose_echo ""
# files=($ZDOTDIR/zshrc.d/functions.*.zsh)
# if (( ${#files[@]} > 0 )); then
#     for f in "${files[@]}"; do
#         verbose_echo "   • $(basename "$f")..."
#         source "$f"
#     done
# else
#     verbose_echo "   x No zsh function scripts available."
# fi

verbose_echo ""
verbose_echo "🚀 ${bold}${blue}Enable aliases${normal}"
verbose_echo ""
files=($ZDOTDIR/zshrc.d/aliases.*.zsh)
if (( ${#files[@]} > 0 )); then
    for f in "${files[@]}"; do
        verbose_echo "   • $(basename "$f")..."
        source "$f"
    done
else
    verbose_echo "   x No zsh alias scripts available."
fi

# # === [END] ZSHRC.D AND ALIASES ===
