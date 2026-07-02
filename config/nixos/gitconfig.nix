{
  config,
  pkgs,
  ...
}: {
  environment.etc = {
    "gitignore".text = ''
      .envrc
      /default.nix
      *.swp
      *.pyc
    '';
    "gitconfig".text = ''
      [init]
          # What is this hipster bullshit "main"? THERE IS NO "SLAVE" IN THIS FUCKING CONTEXT.
          defaultBranch = master
      [core]
          pager = ${pkgs.delta}/bin/delta --dark
          excludesfile = /etc/gitignore
      [pull]
        ff = only
      [alias]
          # foksheet: Send the last change amended to last commit quickly, except on master branch
          fs = "!CURBRANCH=$(git symbolic-ref --short HEAD) && if [ \"''${CURBRANCH}\" = \"$(git-default-branch)\" ]; then echo \"Cant do this on $(git-default-branch) bro\" && exit 1; fi  && git add -u && git commit -a --amend --no-edit && git push --force-with-lease origin ''${CURBRANCH}"

          # fs makes it a bit carefully for remote refs, ffs doesn't care
          ffs = "!CURBRANCH=$(git symbolic-ref --short HEAD) && if [ \"''${CURBRANCH}\" = \"$(git-default-branch)\" ]; then echo \"Cant do this on $(git-default-branch) bro\" && exit 1; fi  && git add -u && git commit -a --amend --no-edit && git push origin +''${CURBRANCH}"

          # Checkout the master branch, update it
          # and remove the source branch if it is already merged on upstream
          reclean = "!CURBRANCH=$(git symbolic-ref --short HEAD) && if [ \"''${CURBRANCH}\" = \"$(git-default-branch)\" ]; then echo \"Cant do this on $(git-default-branch) bro\" && exit 1; fi  && git checkout $(git-default-branch) && git pull && git branch -d ''${CURBRANCH}"

          # I am just lazy
          new = checkout -b
          stashshow = stash show -p

          # checkout latest upstream (good for getting force-pushes)
          getlast = !sh -c 'git fetch --all && git reset --hard origin/$(git symbolic-ref --short HEAD)'

          # checkout to branch of given merge request (for gitlab)
          # usage: git mr <source> <MR number> (git mr origin 1010)
          mr = !sh -c 'git fetch $1 merge-requests/$2/head:mr-$1-$2 && git checkout mr-$1-$2' -

          # checkout to branch of given pull request (for github)
          # usage: git pr <source> <PR number> (git pr origin 1010)
          pr = !sh -c 'git fetch $1 pull/$2/head:$2 && git checkout $2' -

          # stash the whole thing, including untracked files, requires comment
          stashfull = stash --include-untracked -m

          # commit with message without quoting (git cm my space separated summary)
          cm = "!f() { git commit -m \"$*\"; }; f"

          # reword all branch commits, skips the pick/reword todo list step
          # usage: git reword [base-branch|N] (default: git-default-branch; integer N -> last N commits)
          reword = "!f() { if [ -n \"$1\" ] && [ \"$1\" -eq \"$1\" ] 2>/dev/null; then BASE=\"HEAD~$1\"; else BASE=\"''${1:-$(git-default-branch)}\"; fi; GIT_SEQUENCE_EDITOR=\"sed -i 's/^pick/reword/'\" git rebase -i \"''${BASE}\"; }; f"

          # Show latest changed branches
          recents = for-each-ref --sort=committerdate --format='%(committerdate:iso8601)  %(align:40,left)%(refname:short)%(end)  %(subject)' refs/heads refs/remotes

      [safe]
          directory = *

      [diff]
          colorMoved = default
          colorMovedWS = allow-indentation-change

      [rerere]
          enabled = true
          autoupdate = true

      [branch]
          sort = committerdate
    '';
  };

  # Fun tip: If you add an executable like git-x to your path, you can
  # call it with `git x`.
  environment.systemPackages = with pkgs; [
    (pkgs.writeScriptBin "git-fullgrep" ''
      # grep across all local and remote branches
      if [ -z "$1" ]; then
        echo "Usage: git fullgrep <pattern> [git-grep-options...]"
        exit 1
      fi
      pattern="$1"
      shift
      echo "Fetching all remotes..."
      git fetch --all
      git grep -n --heading "$pattern" "$@" $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes)
    '')
    (pkgs.writeScriptBin "git-cleanmerged" ''
      git fetch --all && for branch in $(git branch -l | grep -v `git-default-branch`); do git branch -d $branch ; done && git remote prune origin
    '')
    # Push The Branch with optional GitLab push options (see script for usage)
    (pkgs.writers.writePython3Bin "git-ptb" {} (builtins.readFile ./scripts/git-ptb.py))
  ];
}
