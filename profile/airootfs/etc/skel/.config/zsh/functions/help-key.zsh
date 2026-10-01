# ~/.config/zsh/functions/help-key.zsh - monOS: `?` after a command runs
# `<command> --help`.
#
# Type `git commit ?` (note the space before `?`) and the line runs as
# `git commit --help`. Everywhere else `?` is inserted as usual: empty line,
# cursor not at the end, `?` glued to a word (`file?.txt`), unbalanced
# quotes, or after a pipe/operator. Type `\?` for a literal one-character
# glob at the end of a line.

_monos_help_key() {
    setopt local_options extended_glob
    local stripped=${BUFFER//\\?/}               # ignore escaped characters
    local singles=${stripped//[^\']/} doubles=${stripped//[^\"]/}
    local cmd=${BUFFER%%[[:space:]]#}            # the line without trailing blanks
    if (( CURSOR != ${#BUFFER} )) \
        || [[ -z $cmd || $cmd == "$BUFFER" ]] \
        || (( ${#singles} % 2 || ${#doubles} % 2 )) \
        || [[ $cmd == *[\|\&\;\(\<\>] ]]; then
        zle self-insert
        return
    fi
    [[ " $cmd " == *' --help '* ]] || cmd+=' --help'
    BUFFER=$cmd
    zle end-of-line
    zle accept-line
}
zle -N _monos_help_key
bindkey -M emacs '?' _monos_help_key
