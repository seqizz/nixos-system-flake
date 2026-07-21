#!/usr/bin/env bash

set -u

upstream="${1:-origin}"
base="${2:-$(git-default-branch)}"
base_ref="${upstream}/${base}"

successes=()
fails=()

abort_rebase_if_needed() {
    # Only abort if a rebase is actually in progress
    if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
        git rebase --abort || true
    fi
}

return_to_base_branch() {
    echo
    echo "=== Returning to local ${base} ==="

    if git show-ref --verify --quiet "refs/heads/${base}"; then
        git switch "$base" || echo "WARNING: failed to switch back to local ${base}"
    else
        # Create local base branch if it does not exist
        git switch -C "$base" "$base_ref" || echo "WARNING: failed to create/switch to local ${base}"
    fi
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git work tree."
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree is dirty. Commit/stash first."
    exit 1
fi

if ! git fetch "$upstream"; then
    echo "Failed to fetch upstream: $upstream"
    exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/${base_ref}"; then
    echo "Base ref does not exist: ${base_ref}"
    exit 1
fi

while read -r branch; do
    # Skip remote HEAD and the base branch itself
    [ "$branch" = "HEAD" ] && continue
    [ "$branch" = "$base" ] && continue

    echo
    echo "=== Rebasing ${branch} onto ${base_ref} ==="

    if ! git switch -C "$branch" "${upstream}/${branch}"; then
        abort_rebase_if_needed
        fails+=("$branch: checkout failed")
        continue
    fi

    if ! git rebase "$base_ref"; then
        abort_rebase_if_needed
        fails+=("$branch: rebase failed")
        continue
    fi

    if ! git push --force-with-lease "$upstream" "$branch"; then
        abort_rebase_if_needed
        fails+=("$branch: push failed")
        continue
    fi

    successes+=("$branch")
done < <(
    git for-each-ref \
        --format='%(refname:lstrip=3)' \
        "refs/remotes/${upstream}"
)

return_to_base_branch

echo
echo "===================="
echo "Successes:"
if [ "${#successes[@]}" -eq 0 ]; then
    echo "  none"
else
    printf '  %s\n' "${successes[@]}"
fi

echo
echo "Failures:"
if [ "${#fails[@]}" -eq 0 ]; then
    echo "  none"
else
    printf '  %s\n' "${fails[@]}"
fi

