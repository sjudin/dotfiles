# zmodload zsh/zprof

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

xset r rate 300 40

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

new_tmux_session() {
    local full_path=$(fdfind -t d -H "" "${1:-$HOME}" | fzf)
    if [ -z "$full_path" ]; then
        return 0
    fi

    local hashed_path=$(echo "$full_path" | md5sum | head -zc 4; printf "\n")
    local base_dir=$(basename "$full_path")
    local session_name=$(basename "${base_dir}-${hashed_path}")

    # special case if tmux is not running, in that case we need to start
    # and attach to the session right away
    if ! tmux run 2> /dev/null; then
        tmux new-session -c "$full_path" -As "$session_name"
        return 0

    # If the session does not exist, we create it
    elif ! tmux has-session -t "$session_name" 2> /dev/null; then
        tmux new-session -c "$full_path" -Ads "$session_name"
    fi

    if [ $TERM_PROGRAM = tmux ]; then
        # if inside tmux then we use switch
        tmux switch -t "$session_name"
    else
        # if outside of tmux then we use attach
        tmux attach-session -t "$session_name"
    fi
}

t() {
    # if in tmux, we list the current sessions and also give a "New session"
    # option which can be used to create and switch to a new session
    if [ $TERM_PROGRAM = tmux ]; then
        local tmux_session=$((tmux list-sessions -F '#{session_name}'; printf '%s\n' "New session") | fzf)
        if [ "$tmux_session" = "New session" ]; then
            new_tmux_session "$1"
        elif [ -n "$tmux_session" ]; then
            tmux switch -t "$tmux_session"
        fi
    # if not in tmux then we create/switch to a session
    else
        new_tmux_session "$1"
    fi
}

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/local/go/bin:$PATH

export VISUAL=nvim;
export EDITOR=nvim;

# Use clang and clang++ instead of gcc
export CC=$(realpath `which clang`)
export CXX=$(realpath `which clang++`)
export LD=/usr/bin/lld

export FZF_DEFAULT_COMMAND='fdfind --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# History
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'


# User configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

source $HOME/.aliases

eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/avit.toml)"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Plugins
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found
zinit snippet OMZP::colored-man-pages

zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions   

# zprof
