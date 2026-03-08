gwt-sync() {
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

    if [ "$create_new" = true ]; then
        echo "🌿 Creating NEW branch '$branch' at $target_path..."
        
        # Branch off of base_branch if provided, otherwise branch from HEAD
        if [ -n "$base_branch" ]; then
            echo "   (Branching off of: $base_branch)"
            if ! git worktree add -b "$branch" "$target_path" "$base_branch"; then
              echo "❌ Error: git worktree command failed"
              return 1
            fi
        else
            if ! git worktree add -b "$branch" "$target_path"; then
              echo "❌ Error: git worktree command failed"
              return 1
            fi
        fi
    else
        echo "Checking out existing branch '$branch' at $target_path..."
        if ! git worktree add "$target_path" "$branch"; then
          echo "❌ Error: git worktree command failed"
          return 1
        fi
    fi

    local untracked_count=$(git ls-files --others --exclude-standard | wc -l)

    if [ "$untracked_count" -gt 0 ]; then
      if ! git ls-files --others --exclude-standard -z | xargs -0 -I {} cp --parents {} "$target_path/"; then 
        echo "❌ Error: copying untracked files failed"
        return 1
      fi
    fi

    git -C "${target_path}" status > /dev/null 2>&1
    echo "✅ Successfully created and synced."
}
