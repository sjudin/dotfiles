#!/usr/bin/env bash

# We just use standard fzf here. Tmux will handle the popup window natively.
_fzf_ui() {
    fzf --layout=reverse --border=rounded --margin=2%,2% "$@"
}

new_tmux_session() {
    local full_path=$(fd -t d -H "" "${1:-$HOME}" | _fzf_ui --prompt="📂 Dir > ")
    if [ -z "$full_path" ]; then
        return 0
    fi

    # Strip the trailing slash
    full_path="${full_path%/}"

    local hashed_path=$(echo "$full_path" | md5sum | head -c 4)
    local base_dir=$(basename "$full_path")
    local session_name="${base_dir}-${hashed_path}"

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

delete_tmux_session() {
    # The --multi flag enables TAB to select multiple items. 
    # Added a --header so you don't forget the hotkeys!
    local sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | \
        _fzf_ui --multi --prompt="🗑️ Delete > " --header="TAB: select | ENTER: delete | ESC: cancel")
    if [ -z "$sessions" ]; then
        return 0
    fi

    # Read each selected line and kill the corresponding session
    echo "$sessions" | while read -r session; do
        tmux kill-session -t "$session"
    done
}

# if in tmux, we list the current sessions and also give a "New session"/"Delete session"
# options which can be used to create and switch to a new session or delete sessions
if [ $TERM_PROGRAM = tmux ]; then
    tmux_session=$((tmux list-sessions -F '#{session_name}'; echo "New session"; echo "Delete session") | _fzf_ui --prompt="🖥️ Session > ")

    if [ "$tmux_session" = "New session" ]; then
        new_tmux_session "$1"
    elif [ "$tmux_session" = "Delete session" ]; then
        delete_tmux_session
    elif [ -n "$tmux_session" ]; then
        tmux switch -t "$tmux_session"
    fi
else
    # if not in tmux then we create/switch to a session
    new_tmux_session "$1"
fi
