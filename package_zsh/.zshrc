# zmodload zsh/zprof

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

new_tmux_session() {
    local full_path=$(fd -t d -H "" "${1:-$HOME}" | fzf)
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
export PATH=$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH

export VISUAL=nvim;
export EDITOR=nvim;

# Use clang and clang++ instead of gcc
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
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

# ==========================================
# FZF Smart Caching
# ==========================================
FZF_CACHE="$HOME/.fzf_cache.zsh"
# Regenerate if cache is missing, or if the fzf binary is newer than the cache
if [[ ! -f "$FZF_CACHE" ]] || [[ "$(command -v fzf)" -nt "$FZF_CACHE" ]]; then
    fzf --zsh >| "$FZF_CACHE"
fi
source "$FZF_CACHE"

# ==========================================
# Oh-My-Posh Smart Caching
# ==========================================
OMP_CACHE="$HOME/.omp_cache.zsh"
OMP_CONFIG="$HOME/.config/oh-my-posh/avit.toml"
# Regenerate if cache is missing, config is updated, or oh-my-posh is updated
if [[ ! -f "$OMP_CACHE" ]] || [[ "$OMP_CONFIG" -nt "$OMP_CACHE" ]] || [[ "$(command -v oh-my-posh)" -nt "$OMP_CACHE" ]]; then
    oh-my-posh init zsh --config "$OMP_CONFIG" >| "$OMP_CACHE"
fi
source "$OMP_CACHE"

source $HOME/.aliases

# Fast keychain loading
if [[ -S "$SSH_AUTH_SOCK" ]]; then
    # SSH agent is already running and connected (e.g., inside tmux or VSCode)
    :
elif [[ -f "$HOME/.keychain/$HOST-sh" ]]; then
    # Read the cached environment variables instantly
    source "$HOME/.keychain/$HOST-sh"
else
    # Fallback: only run the slow keychain command if nothing else worked
    eval $(keychain --eval id_ed25519 --quiet)
fi

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
zinit wait lucid for \
 atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions   \
    Aloxaf/fzf-tab \
    OMZP::git \
    OMZP::command-not-found \
    OMZP::colored-man-pages

# zprof
