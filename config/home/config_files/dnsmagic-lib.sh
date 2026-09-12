#!/usr/bin/env bash
# dnsmagic library - shared between dispatcher scripts and dnsmagic wrappers
# Sourced by: NetworkManager dispatcher (via dnscrypt.nix), dnsmagic-pause, dnsmagic-resume
#
# Commands (set before sourcing if needed):
#   nmcli, resolvectl, systemctl, logger, kdig, sleep

set -euo pipefail

# Use provided paths or fall back to command names
: "${nmcli:=nmcli}"
: "${resolvectl:=resolvectl}"
: "${systemctl:=systemctl}"
: "${logger:=logger}"
: "${kdig:=kdig}"
: "${sleep:=sleep}"

DISABLE_FILE="/run/dnscrypt-override.disabled"

log() {
  $logger -t dnsmagic "$*"
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

  type="$($nmcli -g GENERAL.TYPE device show "$iface" 2>/dev/null | head -n1)"
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

set_dns_from_nm() {
  local iface="$1"
  local raw
  local dns
  local filtered=()

  raw="$($nmcli -e no -g IP4.DNS,IP6.DNS device show "$iface" 2>/dev/null)"
  raw="${raw//|/ }"

  for dns in $raw; do
    [[ -n "$dns" ]] && filtered+=("$dns")
  done

  if (( ${#filtered[@]} > 0 )); then
    log "using NM/DHCP DNS on $iface: ${filtered[*]}"
    $resolvectl dns "$iface" "${filtered[@]}" \
      || log "FAILED to set DNS on $iface: ${filtered[*]}"
  else
    log "no NM/DHCP DNS known for $iface; leaving current DNS unchanged"
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
  local i
  for i in 1 2 3 4 5 6; do
    dnscrypt_probe && return 0
    $sleep 1
  done
  return 1
}

apply_policy() {
  local iface="$1"
  local force_mode="${2:-auto}"  # 'pause' or 'resume' or 'auto'
  local conn_id

  is_physical_iface "$iface" || return 0

  conn_id="$(connection_id_for_iface "$iface")"

  if [[ "$force_mode" == "pause" ]]; then
    stop_dnscrypt
    set_dns_from_nm "$iface"
    log "paused on $iface: forced DHCP DNS"
    return 0
  fi

  if [[ "$force_mode" == "resume" ]]; then
    local state
    state="$($nmcli -t networking connectivity check 2>/dev/null)" || state="unknown"
    state="${state,,}"
    [[ -n "$state" ]] || state="unknown"

    case "$state" in
      full)
        if start_dnscrypt; then
          log "resumed on $iface: connectivity=full, dnscrypt healthy, switching to 127.0.0.1"
          $resolvectl dns "$iface" 127.0.0.1 ::1
        else
          log "resumed on $iface: dnscrypt unhealthy, falling back to DHCP DNS"
          stop_dnscrypt
          set_dns_from_nm "$iface"
        fi
        ;;
      *)
        stop_dnscrypt
        set_dns_from_nm "$iface"
        log "resumed on $iface: connectivity=$state, using DHCP DNS"
        ;;
    esac
    return 0
  fi

  # auto mode: check override file and connectivity
  if [[ -e "$DISABLE_FILE" ]]; then
    stop_dnscrypt
    set_dns_from_nm "$iface"
    return 0
  fi

  local state
  state="$($nmcli -t networking connectivity check 2>/dev/null)" || state="unknown"
  state="${state,,}"
  [[ -n "$state" ]] || state="unknown"

  case "$state" in
    full)
      if start_dnscrypt; then
        $resolvectl dns "$iface" 127.0.0.1 ::1
      else
        stop_dnscrypt
        set_dns_from_nm "$iface"
      fi
      ;;
    *)
      stop_dnscrypt
      set_dns_from_nm "$iface"
      ;;
  esac
}

apply_policy_all() {
  local force_mode="${1:-auto}"

  while IFS= read -r iface; do
    apply_policy "$iface" "$force_mode"
  done < <(connected_physical_ifaces)
}