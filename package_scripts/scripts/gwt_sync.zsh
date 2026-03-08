_gwt_sync() {
  local context state state_descr line
  typeset -A opt_args

  _arguments -C \
    '1:target directory:_dirs' \
    '2:git branch:->branches'

  if [[ "$state" == branches ]]; then
    # Store branches in a proper array first
    local -a my_branches
    my_branches=(${(f)"$(git branch --all --format='%(refname:short)' 2>/dev/null | grep -v 'HEAD')"})
    
    # _wanted tells fzf-tab: "Here is a list of 'branches', please render them under the header 'git branch'"
    _wanted branches expl 'git branch' compadd -a my_branches
  fi
}

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


