"""git-ptb: Push The Branch with optional GitLab push options.

Usage: git ptb [modifiers] [assignee]

Modifiers (order doesn't matter):
  s - skip CI (ci.skip)
  m - create merge request
  r - remove source branch after merge
  d - mark as draft
  a - amend staged changes into last commit (--amend --no-edit)
  f - force push (uses --force-with-lease)
  F - force push (without lease, fuk it)

Examples:
  git ptb          # plain push
  git ptb s        # skip CI
  git ptb ms       # MR + skip CI (same as 'sm')
  git ptb mfs      # MR + force-with-lease + skip CI
  git ptb mrd joe  # MR + remove branch + draft + assign to joe
  git ptb as       # amend staged files, then push (force-with-lease) + skip CI
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


def has_staged_changes():
    # Exit code 1 means the index differs from HEAD, i.e. something is staged
    return subprocess.call(['git', 'diff', '--cached', '--quiet']) != 0


def amend_staged():
    # No -a/-u: only what is already in the index gets folded into HEAD
    cmd = ['git', 'commit', '--amend', '--no-edit']
    print(f'+ {" ".join(cmd)}')
    rc = subprocess.call(cmd)
    if rc != 0:
        sys.exit(rc)


def main():
    modifiers = set(sys.argv[1]) if len(sys.argv) > 1 else set()
    assignee = sys.argv[2] if len(sys.argv) > 2 else None

    # Validate modifiers
    unknown = modifiers - set(MODIFIERS.keys()) - {'a', 'f', 'F'}
    if unknown:
        print(f'Unknown modifier(s): {", ".join(unknown)}', file=sys.stderr)
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    # Check for conflicting force flags
    if 'f' in modifiers and 'F' in modifiers:
        print(
            'Error: Cannot use both "f" and "F" modifiers together',
            file=sys.stderr,
        )
        sys.exit(1)

    if 'a' in modifiers:
        if not has_staged_changes():
            print(
                'Error: nothing staged, refusing to amend',
                file=sys.stderr,
            )
            sys.exit(1)
        amend_staged()

    branch = get_branch()
    default_branch = get_default_branch()

    # Build push options
    opts = []
    for mod in modifiers:
        if mod in MODIFIERS:
            for opt in MODIFIERS[mod]:
                opts.extend(['-o', opt.format(default_branch=default_branch)])

    if assignee:
        opts.extend(['-o', f'merge_request.assign={assignee}'])

    # Add force flag if requested; amend rewrites HEAD, so it needs one too
    if 'F' in modifiers:
        opts.append('--force')
    elif 'f' in modifiers or 'a' in modifiers:
        opts.append('--force-with-lease')

    cmd = ['git', 'push'] + opts + ['origin', branch]
    print(f'+ {" ".join(cmd)}')
    sys.exit(subprocess.call(cmd))


if __name__ == '__main__':
    main()
