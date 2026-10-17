#!/usr/bin/env bash
# Shared helpers. Sourced by every script; not meant to be run directly.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$ROOT/.env" ]] && source "$ROOT/.env"
: "${TV_IP:?Set TV_IP in .env (cp .env.example .env)}"
TV="${TV_IP}:${TV_PORT:-5555}"

# Packages matching this are never touched, even if listed in bloat.txt.
# Removing these can black-screen the TV.
PROTECTED_RE='launcher|settings|input|ime|framework|systemui|cloud9|webview|overlay|tiramisu|oobe|turnstile|firehomestarter|tifobserver|consents|identity|tcomm|^com\.amazon\.dcp|^android$|^com\.android\.'

die() { echo "error: $*" >&2; exit 1; }

# adb shell on the TV. -n stops adb from eating the caller's stdin (breaks while-read loops).
ash() { adb -s "$TV" shell -n "$@" | tr -d '\r'; }

connect() {
  adb connect "$TV" >/dev/null 2>&1 || true
  local state
  state=$(adb -s "$TV" get-state 2>/dev/null || true)
  [[ "$state" == device ]] || die "TV not reachable at $TV (state: ${state:-none}). Check ADB debugging is on and accept the prompt on the TV."
  echo "connected: $TV — $(ash getprop ro.build.version.name)"
}

# Print package names from a list file, ignoring comments and blank lines.
read_list() { grep -vE '^[[:space:]]*(#|$)' "$1" | sed 's/[[:space:]]*#.*//; s/[[:space:]]*$//' || true; }

# Snapshot package state from the TV (call before state_of).
load_state() {
  S_ACTIVE=$(ash pm list packages | sed 's/^package://')
  S_ALL=$(ash pm list packages -u | sed 's/^package://')
  S_DISABLED=$(ash pm list packages -d | sed 's/^package://')
}

# ACTIVE | DISABLED | UNINSTALLED (for user 0, still on system partition) | MISSING
state_of() {
  local p=$1
  if ! grep -qxF "$p" <<<"$S_ALL"; then echo MISSING
  elif ! grep -qxF "$p" <<<"$S_ACTIVE"; then echo UNINSTALLED
  elif grep -qxF "$p" <<<"$S_DISABLED"; then echo DISABLED
  else echo ACTIVE
  fi
}

# Fixes the "home screen stuck loading" hang after disabling packages.
restart_launcher() {
  ash am force-stop com.amazon.tv.launcher >/dev/null 2>&1 || true
  ash monkey -p com.amazon.tv.launcher -c android.intent.category.HOME 1 >/dev/null 2>&1 || true
  echo "launcher restarted"
}

wait_for_boot() {
  echo "waiting for TV to boot..."
  sleep 15
  for _ in $(seq 1 60); do
    adb connect "$TV" >/dev/null 2>&1 || true
    if [[ "$(adb -s "$TV" get-state 2>/dev/null || true)" == device ]] &&
       [[ "$(ash getprop sys.boot_completed 2>/dev/null || true)" == 1 ]]; then
      sleep 10  # let the launcher settle
      echo "booted"
      return 0
    fi
    sleep 3
  done
  die "TV didn't come back within ~3 minutes"
}
