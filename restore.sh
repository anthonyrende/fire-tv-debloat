#!/usr/bin/env bash
# Bring packages back.
# Usage: ./restore.sh                 restore everything in bloat.txt
#        ./restore.sh pkg [pkg...]    restore specific packages
source "$(dirname "$0")/lib.sh"

connect
load_state

if (( $# )); then pkgs=("$@"); else mapfile -t pkgs < <(read_list "$ROOT/bloat.txt"); fi

for pkg in "${pkgs[@]}"; do
  case "$(state_of "$pkg")" in
    UNINSTALLED) ash cmd package install-existing "$pkg" >/dev/null 2>&1 && echo "$pkg	reinstalled" ;;
    DISABLED)    ash pm enable "$pkg" >/dev/null 2>&1 && echo "$pkg	enabled" ;;
    ACTIVE)      echo "$pkg	already active" ;;
    MISSING)     echo "$pkg	not on device" ;;
  esac
done

restart_launcher
echo "done — reboot with: adb -s $TV reboot"
