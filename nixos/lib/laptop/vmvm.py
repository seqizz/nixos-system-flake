"""vmvm — generic microVM pool manager

Manages a pool of pre-defined microVMs (vmvm-1 through vmvm-4) with
dynamic bind mounts and optional package installation.
"""

import argparse
import json
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

BASE_DIR = Path('/devel/microvms')
STATE_FILE = BASE_DIR / 'vmvm-state.json'
VM_COUNT = 4
SHARE_SLOTS = 4
IP_BASE = '192.168.83'
IP_OFFSET = 10  # vmvm-1 = .11, vmvm-2 = .12, etc.
SSH_OPTS = [
    '-o',
    'StrictHostKeyChecking=no',
    '-o',
    'UserKnownHostsFile=/dev/null',
    '-o',
    'LogLevel=ERROR',
]
SSH_USER = 'gurkan'
SSH_PROBE_TIMEOUT = 20
SSH_PROBE_INTERVAL = 1


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {}


def save_state(state: dict) -> None:
    BASE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2) + '\n')


def slot_ip(slot: int) -> str:
    return f'{IP_BASE}.{IP_OFFSET + slot}'


def slot_service(slot: int) -> str:
    return f'microvm@vmvm-{slot}.service'


def slot_share_dir(slot: int, share_idx: int) -> Path:
    return BASE_DIR / f'vmvm-{slot}' / f'share-{share_idx}'


def slot_ssh_keys_dir(slot: int) -> Path:
    return BASE_DIR / f'vmvm-{slot}' / 'ssh-host-keys'


def used_slots(state: dict) -> set:
    return {v['slot'] for v in state.values()}


def find_free_slot(state: dict) -> int | None:
    taken = used_slots(state)
    for i in range(1, VM_COUNT + 1):
        if i not in taken:
            return i
    return None


def run(
    cmd: list[str], check: bool = True, **kwargs
) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, **kwargs)


def run_sudo(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return run(['sudo'] + cmd, **kwargs)


def generate_ssh_keys(slot: int) -> None:
    keys_dir = slot_ssh_keys_dir(slot)
    keys_dir.mkdir(parents=True, exist_ok=True)
    key_file = keys_dir / 'ssh_host_ed25519_key'
    if not key_file.exists():
        print(f'Generating SSH host keys for vmvm-{slot}...')
        run(['ssh-keygen', '-t', 'ed25519', '-f', str(key_file), '-N', ''])


def wait_for_ssh(ip: str, timeout: int = SSH_PROBE_TIMEOUT) -> bool:
    """Probe SSH port until ready or timeout."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((ip, 22), timeout=2):
                return True
        except (ConnectionRefusedError, OSError):
            time.sleep(SSH_PROBE_INTERVAL)
    return False


def ssh_exec(ip: str, command: str) -> subprocess.CompletedProcess:
    """Run a command inside the VM via SSH."""
    return run(
        ['ssh'] + SSH_OPTS + [f'{SSH_USER}@{ip}', command],
        check=False,
    )


def ssh_connect(ip: str) -> None:
    """Interactive SSH into the VM (replaces current process)."""
    os.execvp('ssh', ['ssh'] + SSH_OPTS + [f'{SSH_USER}@{ip}'])


def parse_mount(mount_spec: str) -> tuple[str, str]:
    """Parse -m /host/path:guestname into (host_path, guest_name)."""
    if ':' not in mount_spec:
        print(
            f"Error: invalid mount spec '{mount_spec}',"
            ' expected /host/path:guestname'
        )
        sys.exit(1)
    host_path, guest_name = mount_spec.rsplit(':', 1)
    host_path = str(Path(host_path).resolve())
    if not Path(host_path).is_dir():
        print(f"Error: host directory '{host_path}' does not exist")
        sys.exit(1)
    return host_path, guest_name


def cmd_start(args: argparse.Namespace) -> None:
    state = load_state()

    if args.name in state:
        existing = state[args.name]
        esl = existing['slot']
        print(
            f"Error: '{args.name}' already running"
            f' on vmvm-{esl} ({slot_ip(esl)})'
        )
        print(f'  Stop it first: vmvm stop {args.name}')
        sys.exit(1)

    if not args.mount:
        print('Error: at least one -m /host/path:guestname is required')
        sys.exit(1)

    if len(args.mount) > SHARE_SLOTS:
        print(f'Error: max {SHARE_SLOTS} mounts per VM, got {len(args.mount)}')
        sys.exit(1)

    slot = find_free_slot(state)
    if slot is None:
        print(f'Error: all {VM_COUNT} VM slots are in use')
        print('Running VMs:')
        for name, info in state.items():
            print(f'  {name} → vmvm-{info["slot"]} ({slot_ip(info["slot"])})')
        sys.exit(1)

    ip = slot_ip(slot)
    service = slot_service(slot)

    # Parse mounts
    mounts = {}
    for i, mount_spec in enumerate(args.mount):
        host_path, guest_name = parse_mount(mount_spec)
        mounts[str(i)] = {'host': host_path, 'guest': guest_name}

    # Create share slot directories
    for i in range(SHARE_SLOTS):
        slot_share_dir(slot, i).mkdir(parents=True, exist_ok=True)

    generate_ssh_keys(slot)

    # Bind-mount requested directories to share slots
    for idx_str, mount_info in mounts.items():
        share_dir = slot_share_dir(slot, int(idx_str))
        print(f'  Mounting {mount_info["host"]} → share-{idx_str}')
        run_sudo(['mount', '--bind', mount_info['host'], str(share_dir)])

    # Start the VM
    print(f'Starting vmvm-{slot} ({ip})...')
    run_sudo(['systemctl', 'start', service])

    # Save state early so --stop works even if SSH setup fails
    state[args.name] = {
        'slot': slot,
        'ip': ip,
        'mounts': mounts,
        'packages': args.package or [],
    }
    save_state(state)

    # Wait for SSH
    print('Waiting for SSH...', end='', flush=True)
    if not wait_for_ssh(ip):
        print(' timeout!')
        print(
            f'VM started but SSH not reachable at {ip}:22'
            f' after {SSH_PROBE_TIMEOUT}s'
        )
        print(f'  Try manually: ssh {SSH_USER}@{ip}')
        return
    print(' ready.')

    # Create symlinks for friendly mount names
    for idx_str, mount_info in mounts.items():
        guest_name = mount_info['guest']
        home = f'/home/{SSH_USER}'
        ssh_exec(
            ip,
            f'ln -sfn {home}/mnt/{idx_str} {home}/{guest_name}',
        )

    # Install extra packages if requested
    if args.package:
        pkg_refs = ' '.join(f'nixpkgs#{p}' for p in args.package)
        print(f'Installing packages: {", ".join(args.package)}...')
        result = ssh_exec(ip, f'nix profile install {pkg_refs}')
        if result.returncode != 0:
            print('Warning: package installation failed (VM still running)')

    print(f"\n  VM '{args.name}' running on vmvm-{slot} ({ip})")

    if args.background:
        print(f'  SSH: vmvm ssh {args.name}')
        print(f'  Stop: vmvm stop {args.name}')
    else:
        # Drop into interactive SSH
        ssh_connect(ip)


def cmd_stop(args: argparse.Namespace) -> None:
    state = load_state()

    if args.name not in state:
        print(f"Error: no VM named '{args.name}' is running")
        sys.exit(1)

    info = state[args.name]
    slot = info['slot']
    service = slot_service(slot)

    print(f'Stopping vmvm-{slot}...')
    run_sudo(['systemctl', 'stop', service], check=False)

    # Unmount bind mounts
    for idx_str in info.get('mounts', {}):
        share_dir = slot_share_dir(slot, int(idx_str))
        result = run(['mountpoint', '-q', str(share_dir)], check=False)
        if result.returncode == 0:
            run_sudo(['umount', str(share_dir)], check=False)

    del state[args.name]
    save_state(state)
    print('Done.')


def cmd_ssh(args: argparse.Namespace) -> None:
    state = load_state()

    if args.name not in state:
        print(f"Error: no VM named '{args.name}' is running")
        sys.exit(1)

    ssh_connect(state[args.name]['ip'])


def cmd_list(args: argparse.Namespace) -> None:
    state = load_state()

    if not state:
        print('No VMs running.')
        return

    for name, info in sorted(state.items()):
        slot = info['slot']
        ip = info['ip']
        service = slot_service(slot)

        # Check if actually running
        result = run(
            ['systemctl', 'is-active', '--quiet', service],
            check=False,
        )
        status = 'running' if result.returncode == 0 else 'stopped'

        mounts_str = ', '.join(
            f'{m["host"]}:~/{m["guest"]}'
            for m in info.get('mounts', {}).values()
        )
        pkgs_str = ''
        if info.get('packages'):
            pkgs_str = f'  pkgs=[{", ".join(info["packages"])}]'

        line = f'  {name:20s} vmvm-{slot} ({ip})'
        line += f'  [{status}]  {mounts_str}{pkgs_str}'
        print(line)


def cmd_status(args: argparse.Namespace) -> None:
    state = load_state()

    if args.name:
        if args.name not in state:
            print(f"Error: no VM named '{args.name}' is running")
            sys.exit(1)
        info = state[args.name]
        service = slot_service(info['slot'])
        run(['systemctl', 'status', service, '--no-pager'], check=False)
    else:
        # Show all slot statuses
        for i in range(1, VM_COUNT + 1):
            service = slot_service(i)
            result = run(
                ['systemctl', 'is-active', '--quiet', service],
                check=False,
            )
            status = 'running' if result.returncode == 0 else 'inactive'
            # Find name for this slot
            name = next(
                (n for n, v in state.items() if v['slot'] == i),
                '-',
            )
            print(f'  vmvm-{i} ({slot_ip(i)}): {status:10s}  name={name}')


def main() -> None:
    parser = argparse.ArgumentParser(
        prog='vmvm',
        description='Generic microVM pool manager',
    )
    sub = parser.add_subparsers(dest='command')

    p_start = sub.add_parser('start', help='Start a VM with mounts')
    p_start.add_argument('name', help='Friendly name for this VM instance')
    p_start.add_argument(
        '-m',
        '--mount',
        action='append',
        metavar='HOST:GUEST',
        help='Mount host dir at ~/GUEST inside VM (repeatable, max 4)',
    )
    p_start.add_argument(
        '-p',
        '--package',
        action='append',
        metavar='PKG',
        help='Install extra nixpkgs package inside VM (repeatable)',
    )
    p_start.add_argument(
        '-b',
        '--background',
        action='store_true',
        help="Don't attach to VM after start",
    )

    p_stop = sub.add_parser('stop', help='Stop a named VM')
    p_stop.add_argument('name', help='VM name to stop')

    p_ssh = sub.add_parser('ssh', help='SSH into a running VM')
    p_ssh.add_argument('name', help='VM name to connect to')

    sub.add_parser('list', help='List running VMs')

    p_status = sub.add_parser('status', help='Show VM status')
    p_status.add_argument(
        'name', nargs='?', help='VM name (optional, shows all if omitted)'
    )

    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(0)

    commands = {
        'start': cmd_start,
        'stop': cmd_stop,
        'ssh': cmd_ssh,
        'list': cmd_list,
        'status': cmd_status,
    }
    commands[args.command](args)


if __name__ == '__main__':
    main()
