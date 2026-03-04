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

_t_widget() {
    zle push-line
    BUFFER="~/scripts/tm-manager.sh"
    zle accept-line
}
zle -N _t_widget
bindkey '^f' _t_widget

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
