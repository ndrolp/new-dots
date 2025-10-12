#!/usr/bin/env bash
# ADB Bookmark Manager — Save devices by name, connect/pair easily via adb.
# Features: add, list, connect, pair, fzf-connect, fzf-pair

BOOKMARK_FILE="${HOME}/.adb_bookmarks"

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

msg() { echo -e "${GREEN}[INFO]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
die() { echo -e "${RED}[ERR]${RESET} $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [args...]

Commands:
  add <name> <ip> [port]     Add a new device bookmark
  list                       List saved bookmarks
  connect <name>             Connect to device by name
  pair <name>                Pair to device by name (asks for port & code)
  fzf-connect                Pick device via fzf and connect
  fzf-pair                   Pick device via fzf and pair (asks for port & code)
  help                       Show this help message
EOF
}

ensure_file() {
  [[ -f "$BOOKMARK_FILE" ]] || touch "$BOOKMARK_FILE"
}

lookup_bookmark() {
  local name="$1"
  grep -E "^${name}\|" "$BOOKMARK_FILE" || return 1
}

add_bookmark() {
  ensure_file
  local name="$1" ip="$2" port="${3:-5555}"
  [[ -z "$name" || -z "$ip" ]] && die "Usage: add <name> <ip> [port]"
  if lookup_bookmark "$name" >/dev/null; then
    warn "Bookmark '$name' already exists, overwriting..."
    grep -v -E "^${name}\|" "$BOOKMARK_FILE" > "${BOOKMARK_FILE}.tmp"
    mv "${BOOKMARK_FILE}.tmp" "$BOOKMARK_FILE"
  fi
  echo "${name}|${ip}|${port}" >> "$BOOKMARK_FILE"
  msg "Added: ${name} → ${ip}:${port}"
}

list_bookmarks() {
  ensure_file
  if [[ ! -s "$BOOKMARK_FILE" ]]; then
    warn "No bookmarks saved yet."
    return
  fi
  printf "%-15s %-20s %-5s\n" "Name" "IP" "Port"
  printf "%-15s %-20s %-5s\n" "-----" "--------------------" "-----"
  awk -F'|' '{printf "%-15s %-20s %-5s\n", $1, $2, $3}' "$BOOKMARK_FILE"
}

connect_device() {
  ensure_file
  local name="$1"
  [[ -z "$name" ]] && die "Usage: connect <name>"
  local entry
  if ! entry="$(lookup_bookmark "$name")"; then
    die "No bookmark found for '$name'"
  fi
  IFS='|' read -r _ host port <<< "$entry"
  msg "Connecting to $host:$port ..."
  if adb connect "$host:$port"; then
    msg "Connected successfully ✅"
  else
    die "adb connect failed for $host:$port"
  fi
}

pair_device() {
  ensure_file
  local name="$1"
  [[ -z "$name" ]] && die "Usage: pair <name>"
  local entry
  if ! entry="$(lookup_bookmark "$name")"; then
    die "No bookmark found for '$name'"
  fi
  IFS='|' read -r _ host _ <<< "$entry"

  printf "Enter pairing port for %s (default: 37099): " "$host"
  read -r port
  port="${port:-37099}"

  printf "Enter pairing code for %s:%s: " "$host" "$port"
  read -r code

  msg "Pairing with $host:$port..."
  if adb pair "$host:$port" "$code"; then
    msg "Paired successfully ✅"
  else
    die "adb pair failed for $host:$port"
  fi
}

fzf_connect() {
  [[ -s "$BOOKMARK_FILE" ]] || die "No bookmarks available"
  command -v fzf >/dev/null 2>&1 || die "fzf not installed"
  local choice
  choice=$(awk -F'|' '{printf "%s\t%s:%s\n", $1, $2, $3}' "$BOOKMARK_FILE" |
    fzf --height 40% --ansi --prompt="Select device to connect> ")
  [[ -n "$choice" ]] || return 1
  local name=$(echo "$choice" | awk '{print $1}')
  connect_device "$name"
}

fzf_pair() {
  [[ -s "$BOOKMARK_FILE" ]] || die "No bookmarks available"
  command -v fzf >/dev/null 2>&1 || die "fzf not installed"
  local choice
  choice=$(awk -F'|' '{printf "%s\t%s:%s\n", $1, $2, $3}' "$BOOKMARK_FILE" |
    fzf --height 40% --ansi --prompt="Select device to pair> ")
  [[ -n "$choice" ]] || return 1

  local name=$(echo "$choice" | awk '{print $1}')
  local entry
  if ! entry="$(lookup_bookmark "$name")"; then
    die "Could not find bookmark or parse host:port from '$name'"
  fi
  IFS='|' read -r _ host _ <<< "$entry"

  printf "Enter pairing port for %s (default: 37099): " "$host"
  read -r port
  port="${port:-37099}"

  printf "Enter pairing code for %s:%s: " "$host" "$port"
  read -r code

  msg "Pairing with $host:$port..."
  if adb pair "$host:$port" "$code"; then
    msg "Paired successfully ✅"
  else
    die "adb pair failed for $host:$port"
  fi
}

main() {
  local cmd="$1"; shift || true
  case "$cmd" in
    add) add_bookmark "$@" ;;
    list) list_bookmarks ;;
    connect) connect_device "$@" ;;
    pair) pair_device "$@" ;;
    fzf-connect) fzf_connect ;;
    fzf-pair) fzf_pair ;;
    help|"") usage ;;
    *) die "Unknown command: $cmd" ;;
  esac
}

main "$@"
