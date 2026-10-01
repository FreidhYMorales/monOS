# ~/.config/zsh/plugins.zsh - monOS: zsh plugins from the Arch packages
# zsh-autosuggestions and zsh-syntax-highlighting (no plugin manager, nothing
# is downloaded). Both use the terminal's ANSI colors (monOS palette).

_monos_plugins=/usr/share/zsh/plugins

# Gray suggestion from history (or completion) as you type: Right/End
# accepts it, Alt-F (or Ctrl-Right) accepts one word.
if [[ -r $_monos_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
    source "$_monos_plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting must be sourced after every other widget is defined,
# so it stays the last plugin (aliases.zsh only defines aliases/functions).
if [[ -r $_monos_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source "$_monos_plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset _monos_plugins
