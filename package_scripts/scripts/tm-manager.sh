#!/usr/bin/env bash

# We just use standard fzf here. Tmux will handle the popup window natively.
_fzf_ui() {
    fzf --layout=reverse --border=rounded --margin=2%,2% "$@"
}

new_tmux_session() {
    local target_dir="${1:-$HOME}"
    local fzf_opts=()

    # Conditionally add the toggling TAB bindings if outside of tmux
    if [ "$TERM_PROGRAM" != "tmux" ] && tmux has-session 2>/dev/null; then
        # Store our reload commands safely 
        local fd_cmd="fd -t d -H '' '$target_dir'"
        local tmux_cmd="tmux list-sessions -F '#{session_name}'"

        fzf_opts=(
            --header "TAB: Active sessions"
            # Clear the toggle state file the moment fzf opens
            --bind "start:execute-silent(rm -f /tmp/fzf_tm_toggle)"
            # Check the state file every time TAB is pressed, flip the state, and dynamically inject the right commands
            --bind "tab:transform:if [ -f /tmp/fzf_tm_toggle ]; then rm -f /tmp/fzf_tm_toggle; echo \"change-prompt(📂 Dir > )+reload($fd_cmd)+change-header(TAB: Active sessions)\"; else touch /tmp/fzf_tm_toggle; echo \"change-prompt(🖥️ Session > )+reload($tmux_cmd)+change-header(TAB: Directories)\"; fi"
        )
    fi

    # Pass the options array into fzf
    local full_path=$(fd -t d -H "" "$target_dir" | _fzf_ui --prompt="📂 Dir > " "${fzf_opts[@]}")

    # Strip the trailing slash
    full_path="${full_path%/}"

    if [ -z "$full_path" ]; then
        return 0
    fi

    # If you pressed TAB and selected an active session, attach to it and exit early
    if tmux has-session -t "$full_path" 2>/dev/null; then
        tmux attach-session -t "$full_path"
        return 0
    fi

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

    if [ "$TERM_PROGRAM" = "tmux" ]; then
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

    # Identify the session we are currently inside
    local current_session=$(tmux display-message -p '#S' 2>/dev/null)
    local kill_current=false

    # Use a here-string (<<<) instead of a pipe (|) so we don't spawn a subshell.
    # This allows our 'kill_current' variable to survive after the loop finishes.
    while read -r session; do
        if [ -z "$session" ]; then continue; fi

        if [ "$session" = "$current_session" ]; then
            # Flag it, but don't kill it yet!
            kill_current=true
        else
            tmux kill-session -t "$session"
        fi
    done <<< "$sessions"

    # Commit the final kill if it was flagged
    if [ "$kill_current" = true ]; then
        tmux kill-session -t "$current_session"
    fi
}

# if in tmux, we list the current sessions and also give a "New session"/"Delete session"
# options which can be used to create and switch to a new session or delete sessions
if [ "$TERM_PROGRAM" = "tmux" ]; then
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
