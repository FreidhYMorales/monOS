# ~/.config/zsh/functions/yazi.zsh - monOS: `y` starts the yazi file manager
# and, on quit (q), changes the shell to the directory yazi was in.
# Quit with Q to stay in the current directory.

y() {
    local tmp cwd
    tmp=$(mktemp -t yazi-cwd.XXXXXX) || return
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n $cwd && $cwd != "$PWD" && -d $cwd ]] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
