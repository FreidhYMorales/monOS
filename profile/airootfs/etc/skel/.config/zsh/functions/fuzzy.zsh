# ~/.config/zsh/functions/fuzzy.zsh - monOS: fuzzy finders (fzf).
#
#   ffcd [query]    pick a directory below . and cd into it (tree preview)
#   ffe  [query]    pick a file below . and open it in $EDITOR (bat preview)
#   ffec [pattern]  pick a file whose content matches pattern (ripgrep,
#                   case-insensitive) and open it in $EDITOR
#
# .git, node_modules, .venv, target, .cache and __pycache__ are skipped; with
# fd (the default) files ignored by .gitignore are skipped too.

_monos_ff_prune=(.git node_modules .venv target .cache __pycache__)
_monos_ff_opts=(--height=80% --layout=reverse --cycle --preview-window=right:60%)

# List directories (-d) or files (-f) below ., up to $2 levels deep.
_monos_ff_list() {
    local kind=$1 depth=$2 name
    if command -v fd >/dev/null 2>&1; then
        local -a excludes=()
        for name in $_monos_ff_prune; do excludes+=(--exclude "$name"); done
        fd --type "${kind#-}" --hidden --follow --max-depth "$depth" $excludes
    else
        local -a prune=()
        for name in $_monos_ff_prune; do prune+=(-o -name "$name"); done
        find . -mindepth 1 -maxdepth "$depth" \( "${prune[@]:1}" \) -prune \
            -o -type "${kind#-}" -print 2>/dev/null | sed 's|^\./||'
    fi
}

_monos_ff_open() {
    [[ -n $1 ]] || return 1
    ${=EDITOR:-vi} -- "$1"
}

_monos_ff_need() {
    command -v fzf >/dev/null 2>&1 && return 0
    print -u2 "fzf is not installed"
    return 1
}

ffcd() {
    _monos_ff_need || return
    local preview='ls -la --color=always {}' dir
    command -v eza >/dev/null 2>&1 && preview='eza --tree --level=2 --icons=always --color=always {}'
    dir=$(_monos_ff_list -d 7 | fzf $_monos_ff_opts --query="$*" --preview="$preview") || return
    [[ -d $dir ]] && builtin cd -- "$dir"
}

ffe() {
    _monos_ff_need || return
    local preview='cat {}' file
    command -v bat >/dev/null 2>&1 && preview='bat --color=always --style=numbers --line-range=:300 {}'
    file=$(_monos_ff_list -f 5 | fzf $_monos_ff_opts --query="$*" --preview="$preview") || return
    _monos_ff_open "$file"
}

ffec() {
    _monos_ff_need || return
    local preview='cat {}' file name
    command -v bat >/dev/null 2>&1 && preview='bat --color=always --style=numbers --line-range=:300 {}'
    if command -v rg >/dev/null 2>&1; then
        local -a globs=()
        for name in $_monos_ff_prune; do globs+=(--glob "!$name"); done
        file=$(rg --files-with-matches --ignore-case --hidden $globs -- "${1:-}" 2>/dev/null |
            fzf $_monos_ff_opts --preview="$preview") || return
    else
        local -a excludes=()
        for name in $_monos_ff_prune; do excludes+=(--exclude-dir="$name"); done
        file=$(grep -rIil $excludes -- "${1:-}" . 2>/dev/null |
            fzf $_monos_ff_opts --preview="$preview") || return
    fi
    _monos_ff_open "$file"
}
