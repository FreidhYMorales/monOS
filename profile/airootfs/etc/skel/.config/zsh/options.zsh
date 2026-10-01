# ~/.config/zsh/options.zsh - monOS: history and shell options.

# --- History ---
# Kept in $XDG_STATE_HOME (~/.local/state/zsh/history), shared live between
# open shells, with timestamps and durations (extended format).
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p -m 700 -- "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000
setopt extended_history       # save ": <start>:<duration>;<command>"
setopt share_history          # write each command immediately, read other shells' commands
setopt hist_ignore_dups       # do not record a command equal to the previous one
setopt hist_ignore_space      # commands starting with a space are not recorded
setopt hist_expire_dups_first # trim duplicates first when the history is full
setopt hist_reduce_blanks     # remove superfluous blanks
setopt hist_verify            # `!!` and friends expand into the line instead of running

# --- Directories ---
setopt auto_cd                # `dir` alone changes into it
setopt auto_pushd             # cd pushes the old directory (cd -<TAB> lists them)
setopt pushd_ignore_dups
setopt pushd_silent

# --- Completion behavior (the completion system itself: completion.zsh) ---
setopt complete_in_word       # complete from the cursor, not only at the end of the word
setopt always_to_end          # move the cursor to the end after a completion

# --- Misc ---
setopt interactive_comments   # allow `# comments` on the command line
setopt no_beep
setopt no_flow_control        # free Ctrl-S / Ctrl-Q
