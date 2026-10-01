# ~/.config/zsh/env.zsh - monOS: environment of interactive shells
# (PATH, editor, pagers). Sourced first by ~/.zshrc.

# ~/.local/bin first (pip --user, cargo install --root, own scripts).
typeset -U path PATH
[[ -d $HOME/.local/bin ]] && path=("$HOME/.local/bin" $path)

# Editor: Neovim when installed, otherwise Vim (always on monOS), then nano.
if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
elif command -v vim >/dev/null 2>&1; then
    export EDITOR=vim
else
    export EDITOR=nano
fi
export VISUAL=$EDITOR

# less: keep colors (-R), smart case-insensitive search (-i).
export PAGER=less
export LESS='-R -i'

# Man pages through bat (syntax-highlighted, same colors as the terminal).
# `col -bx` removes the overstrike formatting first; MANROFFOPT=-c keeps groff
# from emitting SGR sequences that col cannot strip.
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat --language=man --style=plain'"
    export MANROFFOPT='-c'
fi
