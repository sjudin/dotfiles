# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:/usr/local/go/bin:$PATH

export VISUAL=nvim;
export EDITOR=nvim;

# Use clang and clang++ instead of gcc
export CC=$(realpath `which clang`)
export CXX=$(realpath `which clang++`)
export LD=/usr/bin/lld

# export FZF_DEFAULT_COMMAND='fdfind --type file --hidden --follow --color=always --exclude={.cache,.git,build,.clangd}'
export FZF_DEFAULT_COMMAND='fdfind --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

xset r rate 300 40

eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/avit.toml)"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    command-not-found
    colored-man-pages
    )

source $ZSH/oh-my-zsh.sh

# User configuration

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

source $HOME/.aliases

