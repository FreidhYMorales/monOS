# ~/.config/zsh/integrations.zsh - monOS: prompt and tool hooks. Each one is
# only set up when the tool is installed. Everything works offline.

# Starship prompt. Accounts without their own ~/.config/starship.toml (root)
# use the monOS one from /etc/skel.
if command -v starship >/dev/null 2>&1; then
    if [[ -z $STARSHIP_CONFIG && ! -r ${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml \
        && -r /etc/skel/.config/starship.toml ]]; then
        export STARSHIP_CONFIG=/etc/skel/.config/starship.toml
    fi
    eval "$(starship init zsh)"
fi

# zoxide: `z <part of a path>` jumps to a frequently used directory, `zi` picks one.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# direnv: loads/unloads .envrc files (run `direnv allow` in a directory first).
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# fzf: Ctrl-T inserts files, Alt-C changes directory. Its colors come from
# FZF_DEFAULT_OPTS (monOS palette block in ~/.zshrc).
if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    if command -v bat >/dev/null 2>&1; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
    fi
    if command -v eza >/dev/null 2>&1; then
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons=always --color=always {}'"
    fi
    # Key bindings need the line editor on a terminal (not in `zsh -ic cmd`
    # run from a script or pipe, where fzf's setup only prints errors).
    [[ -o zle && -t 0 ]] && source <(fzf --zsh)
fi

# atuin: Ctrl-R searches the shell history (local SQLite database; sync is
# off unless you log in). Loaded after fzf so Ctrl-R is atuin's. The Up
# arrow keeps the prefix search of keybinds.zsh, and atuin's `?` AI prompt
# (an online service) is not bound: `?` belongs to functions/help-key.zsh.
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow --disable-ai 2>/dev/null \
        || atuin init zsh --disable-up-arrow)"
    bindkey -M emacs '^r' atuin-search
fi
