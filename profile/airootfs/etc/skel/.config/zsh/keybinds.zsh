# ~/.config/zsh/keybinds.zsh - monOS: line editor key bindings (emacs mode).
# Ctrl-R (atuin), Ctrl-T / Alt-C (fzf) are bound in integrations.zsh and
# `?` (run --help) in functions/help-key.zsh.

bindkey -e

# Bind a widget to every sequence given (terminfo value plus the sequences
# common terminals send in normal and application cursor mode).
_monos_bind() {
    local widget=$1 seq
    shift
    for seq in "$@"; do
        [[ -n $seq ]] && bindkey -M emacs "$seq" "$widget"
    done
}

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

_monos_bind beginning-of-line  "${terminfo[khome]}" '^[[H' '^[OH' '^[[1~' '^[[7~'   # Home
_monos_bind end-of-line        "${terminfo[kend]}"  '^[[F' '^[OF' '^[[4~' '^[[8~'   # End
_monos_bind delete-char        "${terminfo[kdch1]}" '^[[3~'                         # Delete
_monos_bind overwrite-mode     "${terminfo[kich1]}" '^[[2~'                         # Insert
_monos_bind backward-word      '^[[1;5D' '^[[5D' '^[Od'                             # Ctrl-Left
_monos_bind forward-word       '^[[1;5C' '^[[5C' '^[Oc'                             # Ctrl-Right
_monos_bind backward-kill-word '^H'                                                  # Ctrl-Backspace
_monos_bind kill-word          '^[[3;5~'                                             # Ctrl-Delete
_monos_bind reverse-menu-complete "${terminfo[kcbt]}" '^[[Z'                         # Shift-Tab
# Up/Down: walk the history entries that start with what is already typed.
_monos_bind up-line-or-beginning-search   "${terminfo[kcuu1]}" '^[[A' '^[OA'
_monos_bind down-line-or-beginning-search "${terminfo[kcud1]}" '^[[B' '^[OB'

# Esc Esc: toggle `sudo ` at the start of the line (on an empty line, of the
# previous command).
_monos_sudo_toggle() {
    [[ -z $BUFFER ]] && zle up-history
    [[ -z $BUFFER ]] && return 1
    if [[ $BUFFER == 'sudo '* ]]; then
        BUFFER=${BUFFER#sudo }
        (( CURSOR = CURSOR > 5 ? CURSOR - 5 : 0 ))
    else
        BUFFER="sudo $BUFFER"
        (( CURSOR += 5 ))
    fi
}
zle -N _monos_sudo_toggle
bindkey -M emacs '^[^[' _monos_sudo_toggle

# Alt-1 .. Alt-9: insert the command run N commands ago at the cursor
# (Alt-1 = previous command). Replaces Alt-<digit> as digit argument.
_monos_insert_history_nth() {
    local n=${WIDGET##*-} cmd
    cmd=$(fc -ln -$n -$n 2>/dev/null)
    cmd=${cmd#"${cmd%%[![:space:]]*}"}   # trim leading blanks
    if [[ -n $cmd ]]; then
        LBUFFER+=$cmd
    else
        zle -M "no history entry $n commands back"
        return 1
    fi
}
for _monos_n in {1..9}; do
    zle -N monos-history-$_monos_n _monos_insert_history_nth
    bindkey -M emacs "^[$_monos_n" monos-history-$_monos_n
done
unset _monos_n
