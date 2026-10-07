#!/usr/bin/env bash
# dnsmagic library - shared between dispatcher scripts and dnsmagic wrappers
# Sourced by: NetworkManager dispatcher (via dnscrypt.nix), dnsmagic-pause, dnsmagic-resume
#
# Commands (set before sourcing if needed):
#   nmcli, resolvectl, systemctl, logger, kdig, sleep
#
# Deliberately does NOT set -euo pipefail: a sourced library must not change the
# caller's error semantics. Callers set their own; the functions here are written
# to survive -e (every command substitution that may legitimately fail is guarded).

# Use provided paths or fall back to command names
: "${nmcli:=nmcli}"
: "${resolvectl:=resolvectl}"
: "${systemctl:=systemctl}"
: "${logger:=logger}"
: "${kdig:=kdig}"
: "${sleep:=sleep}"

DISABLE_FILE="/run/dnscrypt-override.disabled"

# Written by config/nixos/laptop/dnscrypt.nix from secrets.nix. Absent on
# machines without that module, which just means no network is treated as home.
HOME_SSID_FILE="/etc/dnsmagic/home-ssid"
HOME_SSID=""
if [[ -r "$HOME_SSID_FILE" ]]; then
  read -r HOME_SSID < "$HOME_SSID_FILE" || true
fi

log() {
  $logger -t dnsmagic "$*"
}

# resolved's cache is global, not per-link, and survives a link DNS change.
# Switching resolver (dnscrypt/public <-> pi-hole) therefore leaves answers
# from the previous resolver in place: a name that only the pi-hole knows
# stays NXDOMAIN for the full negative TTL (SOA minimum, typically 30min)
# after coming home, and gravity-blocked names stay unblocked.
flush_caches() {
  $resolvectl flush-caches || log "flush-caches failed"
}

connection_id_for_iface() {
  local iface="$1"

  if [[ -n "${CONNECTION_ID:-}" && "$iface" == "${DEVICE_IP_IFACE:-$iface}" ]]; then
    printf '%s\n' "${CONNECTION_ID}"
    return 0
  fi

  $nmcli -g GENERAL.CONNECTION device show "$iface" 2>/dev/null | head -n1
}

is_physical_iface() {
  local iface="$1"
  local type

  [[ -n "$iface" ]] || return 1

  type="$($nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null | head -n1)" || type=""
  [[ "$type" == "wifi" || "$type" == "ethernet" ]]
}

connected_physical_ifaces() {
  $nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null \
    | while IFS=: read -r dev type state rest; do
        [[ "$type" == "wifi" || "$type" == "ethernet" ]] || continue
        [[ "$state" == connected* ]] || continue
        printf '%s\n' "$dev"
      done
}

nm_connectivity_check() {
  local state

  state="$($nmcli -t networking connectivity check 2>/dev/null)" || state="unknown"
  [[ -n "$state" ]] || state="unknown"
  printf '%s\n' "${state,,}"
}

set_dns_from_nm() {
  local iface="$1"
  local reason="${2:-}"
  local raw
  local dns
  local filtered=()

  # Ask NM for DHCP/static DNS known for this active device.
  #
  # nmcli -g packs a MULTI-VALUE field into a single line joined by " | ",
  # and escapes ":" as "\:" in IPv6 addresses unless -e no is passed.
  # "resolvectl dns" rejects both forms ("Failed to parse DNS server address"),
  # so normalise to a plain whitespace-separated address list.
  raw="$($nmcli -e no -g IP4.DNS,IP6.DNS device show "$iface" 2>/dev/null)" || raw=""
  raw="${raw//|/ }"

  # Deliberate word splitting: $raw is a whitespace-separated address list.
  for dns in $raw; do
    [[ -n "$dns" ]] && filtered+=("$dns")
  done

  if (( ${#filtered[@]} > 0 )); then
    log "$reason: using NM/DHCP DNS on $iface: ${filtered[*]}"
    # Log failures: a silent no-op here leaves the link on a stale 127.0.0.1
    # override after dnscrypt-proxy has been stopped.
    if $resolvectl dns "$iface" "${filtered[@]}"; then
      flush_caches
    else
      log "$reason: FAILED to set DNS on $iface: ${filtered[*]}"
    fi
  else
    # No point clearing DNS here; if NM has no DNS, captive portal DNS cannot be restored.
    log "$reason: no NM/DHCP DNS known for $iface; leaving current DNS unchanged"
  fi
}

stop_dnscrypt() {
  $systemctl is-active --quiet dnscrypt-proxy.service || return 0
  log "stopping dnscrypt-proxy"
  $systemctl stop dnscrypt-proxy.service || true
}

dnscrypt_probe() {
  $kdig +short +timeout=2 +retry=0 @127.0.0.1 example.com >/dev/null 2>&1
}

start_dnscrypt() {
  $systemctl start dnscrypt-proxy.service || return 1
  # Wait for proxy to be ready to answer (up to ~6s).
  local i
  for i in 1 2 3 4 5 6; do
    dnscrypt_probe && return 0
    $sleep 1
  done
  return 1
}

set_dnscrypt() {
  local iface="$1"

  if start_dnscrypt; then
    log "dnscrypt healthy, switching $iface to 127.0.0.1"
    $resolvectl dns "$iface" 127.0.0.1 ::1 && flush_caches
  else
    log "dnscrypt unhealthy, falling back to DHCP DNS on $iface"
    stop_dnscrypt
    set_dns_from_nm "$iface" "dnscrypt unhealthy"
  fi
}

# apply_policy <iface> [auto|pause|resume] [connectivity-state]
#
# The third argument short-circuits the connectivity probe; pass it when NM has
# already handed the state over (the connectivity-change dispatcher action).
apply_policy() {
  local iface="$1"
  local force_mode="${2:-auto}"
  local state="${3:-}"
  local conn_id

  is_physical_iface "$iface" || return 0

  if [[ "$force_mode" == "pause" ]]; then
    stop_dnscrypt
    set_dns_from_nm "$iface" "paused"
    return 0
  fi

  conn_id="$(connection_id_for_iface "$iface")" || conn_id=""

  # Home DNS is the pi-hole, which serves gravity blocking plus local-only
  # records; routing through dnscrypt would bypass both. Checked before the
  # connectivity state because a healthy home network also reports "full".
  if [[ -n "$HOME_SSID" && "$conn_id" == "$HOME_SSID" ]]; then
    stop_dnscrypt
    set_dns_from_nm "$iface" "home network"
    return 0
  fi

  # "resume" skips this: the wrapper has just removed the file, and a stale
  # read here would undo the thing the user asked for.
  if [[ "$force_mode" != "resume" && -e "$DISABLE_FILE" ]]; then
    stop_dnscrypt
    set_dns_from_nm "$iface" "manual override disabled"
    return 0
  fi

  [[ -n "$state" ]] || state="$(nm_connectivity_check)"

  case "$state" in
    full)
      set_dnscrypt "$iface"
      ;;
    *)
      # portal|limited|none|unknown: captive portal etc. need DHCP DNS until
      # auth is complete. Keep dnscrypt-proxy stopped so it does not burn
      # retries against blocked upstream resolvers.
      stop_dnscrypt
      set_dns_from_nm "$iface" "connectivity=$state"
      ;;
  esac
}

# Full handling of an NM device event (up / dhcp*-change / reapply).
apply_policy_after_device_event() {
  local iface="$1"

  is_physical_iface "$iface" || return 0

  # Give NM time to push DHCP DNS to resolved/NM state first.
  $sleep 2

  # Restore DHCP DNS before the connectivity check: a stale localhost override
  # pointing at a stopped dnscrypt would make portal detection fail outright.
  set_dns_from_nm "$iface" "pre-connectivity-check"

  apply_policy "$iface" auto
}

apply_policy_all() {
  local force_mode="${1:-auto}"

  while IFS= read -r iface; do
    apply_policy "$iface" "$force_mode"
  done < <(connected_physical_ifaces)
}
