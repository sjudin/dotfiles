gwt-sync() {
    emulate -L zsh
    local create_new=false

    # Check for the -b flag and shift arguments if found
    if [[ "$1" == "-b" ]]; then
      create_new=true
      shift
    fi

    if [ -z "$2" ]; then
      echo "Usage: gwt-sync [-b] <path> <branch> [base_branch]"
      return 1
    fi

    local target_path=$1
    local branch=$2
    local base_branch=$3

    # If the provided path is an existing directory (like ../), 
    # automatically append the branch name to create the folder inside it.
    if [ -d "$target_path" ]; then
      # The %/ strips any trailing slashes the user might have typed 
      # so we don't end up with weird paths like ..///my-branch
      target_path="${target_path%/}/$branch"
    fi

    if [ -e "$target_path" ]; then
      echo "❌ Error: '$target_path' already exists. Aborting to prevent overwriting."
      return 1
    fi

    # Resolve both paths before doing repository-root-relative operations.
    target_path=${target_path:a}
    local repo_root
    repo_root=$(git -c core.fsmonitor=false rev-parse --show-toplevel) || return 1

    local tracked_output untracked_output selected_output patch
    local -a changed_files untracked_files selected_files tracked_paths copy_files
    local file picker_status
    tracked_output=$(git -c core.fsmonitor=false -C "$repo_root" diff \
      --name-only --no-renames -z HEAD --) || return 1
    untracked_output=$(git -c core.fsmonitor=false -C "$repo_root" ls-files \
      --others --exclude-standard -z) || return 1
    [[ -n "$tracked_output" ]] && changed_files=("${(@0)${tracked_output%$'\0'}}")
    [[ -n "$untracked_output" ]] && untracked_files=("${(@0)${untracked_output%$'\0'}}")

    if (( ${#changed_files} + ${#untracked_files} )); then
      if ! command -v fzf >/dev/null; then
        echo "❌ Error: fzf is required to select files to carry over."
        return 1
      fi
      # fzf normally accepts the hovered row when nothing is selected.
      # Override Enter so only explicit Tab selections are carried over.
      selected_output=$(printf '%s\0' "${changed_files[@]}" "${untracked_files[@]}" |
        FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf --read0 --print0 --multi \
          --prompt='Carry over> ' \
          --header='Tab: select files | Enter: carry selected | Enter with none / Esc: clean worktree' \
          --bind='enter:transform:if [ "$FZF_SELECT_COUNT" -eq 0 ]; then echo abort; else echo accept; fi')
      picker_status=$?
      case $picker_status in
        0) [[ -n "$selected_output" ]] && selected_files=("${(@0)${selected_output%$'\0'}}") ;;
        1|130) ;; # No match or cancelled picker means no local files carried over.
        *) echo "❌ Error: file picker failed"; return 1 ;;
      esac
    fi

    for file in "${selected_files[@]}"; do
      if (( ${untracked_files[(Ie)$file]} )); then
        copy_files+=("$file")
      else
        tracked_paths+=(":(literal)$file")
      fi
    done
    # Combine staged and unstaged changes, leaving them unstaged at the target.
    # Disable rename detection so each selected path is independent.
    if (( ${#tracked_paths} )); then
      patch=$(git -c core.fsmonitor=false -C "$repo_root" diff --binary \
        --no-ext-diff --no-textconv --no-renames HEAD -- "${tracked_paths[@]}") || return 1
    fi

    if [ "$create_new" = true ]; then
        echo "🌿 Creating NEW branch '$branch' at $target_path..."
        
        # Branch off of base_branch if provided, otherwise branch from HEAD
        if [ -n "$base_branch" ]; then
            echo "   (Branching off of: $base_branch)"
            if ! git -c core.fsmonitor=false worktree add -b "$branch" "$target_path" "$base_branch"; then
              echo "❌ Error: git worktree command failed"
              return 1
            fi
        else
            if ! git -c core.fsmonitor=false worktree add -b "$branch" "$target_path"; then
              echo "❌ Error: git worktree command failed"
              return 1
            fi
        fi
    else
        echo "Checking out existing branch '$branch' at $target_path..."
        if ! git -c core.fsmonitor=false worktree add "$target_path" "$branch"; then
          echo "❌ Error: git worktree command failed"
          return 1
        fi
    fi

    # Check every untracked destination before applying any tracked changes.
    local destination parent
    for file in "${copy_files[@]}"; do
      destination="$target_path/$file"
      if [[ -e "$destination" || -L "$destination" ]]; then
        echo "❌ Error: '$file' already exists in the target; nothing copied."
        echo "   The new worktree remains at $target_path."
        return 1
      fi
      parent=${destination:h}
      while [[ "$parent" != "$target_path" ]]; do
        if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
          echo "❌ Error: unsafe destination directory '$parent'; nothing copied."
          echo "   The new worktree remains at $target_path."
          return 1
        fi
        parent=${parent:h}
      done
    done

    if [[ -n "$patch" ]]; then
      if ! print -r -- "$patch" | git -c core.fsmonitor=false -C "$target_path" apply --check; then
        echo "❌ Error: selected changes do not apply; nothing copied."
        echo "   The new worktree remains at $target_path."
        return 1
      fi
      if ! print -r -- "$patch" | git -c core.fsmonitor=false -C "$target_path" apply; then
        echo "❌ Error: applying selected changes failed. Worktree: $target_path"
        return 1
      fi
    fi
    if (( ${#copy_files} )); then
      if ! (cd "$repo_root" && cp -P --parents -- "${copy_files[@]}" "$target_path/"); then
        echo "❌ Error: copying selected untracked files failed; target may be partially synced."
        return 1
      fi
    fi
    echo "✅ Successfully created worktree; carried over ${#selected_files} selected file(s)."

    # ==========================================
    # TMUX INTEGRATION
    # ==========================================
    echo "" # Add a blank line for readability

    # read -q waits for a single keystroke (y/n) without requiring the Enter key!
    if read -q "choice?🖥️  Create and switch to a Tmux session for this worktree? (y/N) "; then
        echo "" # Newline after the prompt

        # Use 'pwd -P' to guarantee the absolute, physical path (bypassing symlinks)
        local full_path=$(cd "$target_path" && pwd -P)

        local hashed_path=$(echo "$full_path" | md5sum | head -c 4)
        local base_dir=$(basename "$full_path")
        local session_name="${base_dir}-${hashed_path}"

        # If tmux server isn't running at all, start it and attach
        if ! tmux ls > /dev/null 2>&1; then
            tmux new-session -c "$full_path" -As "$session_name"
            return 0
        # If server is running but session doesn't exist, create it in the background
        elif ! tmux has-session -t "$session_name" 2> /dev/null; then
            tmux new-session -c "$full_path" -Ads "$session_name"
        fi

        # Safely switch or attach depending on whether we are currently inside tmux
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$session_name"
        else
            tmux attach-session -t "$session_name"
        fi
    else
        echo "" # Clean newline if they say no
    fi
}
