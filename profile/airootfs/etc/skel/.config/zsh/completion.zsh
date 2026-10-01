# ~/.config/zsh/completion.zsh - monOS: completion system (compinit).

# Extra completions from the zsh-completions package live in the standard
# site-functions directory; keep it in fpath even if fpath was changed.
typeset -U fpath
[[ -d /usr/share/zsh/site-functions ]] && fpath=(/usr/share/zsh/site-functions $fpath)

_monos_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_monos_zcache ]] || mkdir -p -- "$_monos_zcache"

zmodload zsh/complist
autoload -Uz compinit
compinit -d "$_monos_zcache/zcompdump-$ZSH_VERSION"

# Cache slow completions (pacman, ...).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_monos_zcache/completion"

# Menu with arrow-key selection.
zstyle ':completion:*' menu select
# Case-insensitive, then partial-word (f.b -> foo.bar) and substring matching.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' squeeze-slashes true

# Colors: files like `ls` (LS_COLORS), headers in the terminal palette.
if [[ -z $LS_COLORS ]] && command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
fi
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

unset _monos_zcache
