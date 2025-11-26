"""git-ptb: Push The Branch with optional GitLab push options.

Usage: git ptb [modifiers] [assignee]

Modifiers (order doesn't matter):
  s - skip CI (ci.skip)
  m - create merge request
  r - remove source branch after merge
  d - mark as draft

Examples:
  git ptb          # plain push
  git ptb s        # skip CI
  git ptb ms       # MR + skip CI (same as 'sm')
  git ptb mrd joe  # MR + remove branch + draft + assign to joe
"""

import subprocess
import sys

MODIFIERS = {
    's': ['ci.skip'],
    'm': ['merge_request.create', 'merge_request.target={default_branch}'],
    'r': ['merge_request.remove_source_branch'],
    'd': ['merge_request.draft'],
}


def get_branch():
    return subprocess.check_output(
        ['git', 'symbolic-ref', '--short', 'HEAD'], text=True
    ).strip()


def get_default_branch():
    return subprocess.check_output(['git-default-branch'], text=True).strip()


def main():
    modifiers = set(sys.argv[1]) if len(sys.argv) > 1 else set()
    assignee = sys.argv[2] if len(sys.argv) > 2 else None

    # Validate modifiers
    unknown = modifiers - set(MODIFIERS.keys())
    if unknown:
        print(f'Unknown modifier(s): {", ".join(unknown)}', file=sys.stderr)
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    branch = get_branch()
    default_branch = get_default_branch()

    # Build push options
    opts = []
    for mod in modifiers:
        for opt in MODIFIERS[mod]:
            opts.extend(['-o', opt.format(default_branch=default_branch)])

    if assignee:
        opts.extend(['-o', f'merge_request.assign={assignee}'])

    cmd = ['git', 'push'] + opts + ['origin', branch]
    print(f'+ {" ".join(cmd)}')
    sys.exit(subprocess.call(cmd))


if __name__ == '__main__':
    main()
