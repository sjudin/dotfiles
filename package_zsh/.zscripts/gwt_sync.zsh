gwt-sync() {
    if [ -z "$2" ]; then
      echo "Usage: gwt-sync <path> <branch>"
      return 1
    fi

    local target_path=$1
    local branch=$2

    if [ -e "$target_path" ]; then
      echo "❌ Error: '$target_path' already exists. Aborting to prevent overwriting."
      return 1
    fi

    echo "Creating worktree at $target_path on branch $branch..."

    if ! git worktree add "$target_path" "$branch"; then
      echo "❌ Error: git worktree command failed"
      return 1
    fi

    local untracked_count=$(git ls-files --others --exclude-standard | wc -l)

    if [ "$untracked_count" -gt 0 ]; then
      if ! git ls-files --others --exclude-standard -z | xargs -0 -I {} cp --parents {} "$target_path/"; then 
        echo "❌ Error: copying untracked files failed"
        return 1
      fi
    fi

    git status > /dev/null 2>&1
    echo "✅ Successfully created and synced."
}


