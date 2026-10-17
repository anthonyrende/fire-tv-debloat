#!/usr/bin/env bash
# One command after a Fire OS update: debloat -> tune -> reboot -> fix launcher -> verify.
# Usage: ./post-update.sh [--no-reboot]
source "$(dirname "$0")/lib.sh"
cd "$ROOT"

echo "== debloat =="; ./debloat.sh
echo; echo "== tune ==";  ./tune.sh

if [[ "${1:-}" != "--no-reboot" ]]; then
  echo; echo "== reboot =="
  adb -s "$TV" reboot
  wait_for_boot
  restart_launcher
fi

echo; echo "== verify =="; ./verify.sh
