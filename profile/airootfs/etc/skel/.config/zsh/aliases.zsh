# ~/.config/zsh/aliases.zsh - monOS: aliases. Sourced last by ~/.zshrc so
# that no alias (above all the global `--help` one) leaks into the code of
# the tools and plugins sourced before. `\name` or `command name` bypasses
# an alias, e.g. `\ls`, `command cat`.

alias c='clear'
alias lg='lazygit'

# --- Listing (eza) ---
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons=auto --group-directories-first'              # grid
    alias l='eza -lh --icons=auto --group-directories-first'           # long
    alias ll='eza -lha --icons=auto --group-directories-first --git'   # long, hidden, git status
    alias la='eza -a --icons=auto --group-directories-first'           # grid, hidden
    alias lt='eza --tree --level=2 --icons=auto --group-directories-first'  # tree (lt -L 4 for deeper)
    alias ld='eza -lhD --icons=auto'                                   # directories only
fi

# --- bat ---
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain --paging=never'
    # Global alias: `<command> --help` shows the help through bat (colored).
    # Interactive only (this file is only read by interactive shells). Quote
    # it to get the raw output: `cmd '--help'` or `cmd \--help`.
    alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --color=always'
fi

# --- df -> duf (keeps `df -h` and `df <path>` working) ---
if command -v duf >/dev/null 2>&1; then
    _monos_df() {
        if (( $# )) && [[ -e ${@[-1]} ]]; then
            duf -- "${@[-1]}"
        else
            duf
        fi
    }
    alias df='_monos_df'
fi

# --- Packages ---
# Runs as root: pacman; with yay installed: yay (calls sudo itself and also
# covers the AUR); otherwise: sudo pacman (queries without sudo).
_monos_pkg() {
    if (( EUID == 0 )); then
        command pacman "$@"
    elif command -v yay >/dev/null 2>&1; then
        command yay "$@"
    elif [[ $1 == -Q* || $1 == -Ss* ]]; then
        command pacman "$@"
    else
        command sudo pacman "$@"
    fi
}
# Remove orphans: packages installed as dependencies that nothing needs.
_monos_pkg_orphans() {
    local -a orphans
    orphans=(${(f)"$(command pacman -Qtdq)"})
    if (( ! ${#orphans} )); then
        print 'No orphaned packages.'
        return 0
    fi
    _monos_pkg -Rns -- $orphans
}
alias up='_monos_pkg -Syu'    # update the system (and AUR packages with yay)
alias un='_monos_pkg -Rns'    # uninstall a package with its unneeded dependencies
alias pl='_monos_pkg -Qs'     # search the installed packages
alias pa='_monos_pkg -Ss'     # search the repositories (and the AUR with yay)
alias pc='_monos_pkg -Sc'     # clean the package cache
alias po='_monos_pkg_orphans' # remove orphaned packages
