# reload .zshrc to apply config changes in the current shell
function zshreload() {
    local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
    if [[ -f "$zshrc" ]]; then
        source "$zshrc"
        echo ""
        echo "✅ Reloaded $zshrc"
    else
        echo "❌ $zshrc not found" >&2
        return 1
    fi
}
