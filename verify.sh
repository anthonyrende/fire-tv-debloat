#!/usr/bin/env bash
# Show the current state of every package in bloat.txt.
# Anything ACTIVE was re-enabled (usually by an OS update) — run ./debloat.sh.
source "$(dirname "$0")/lib.sh"

connect
load_state

active=0
while read -r pkg; do
  s=$(state_of "$pkg")
  [[ "$s" == ACTIVE ]] && { active=$((active + 1)); s="ACTIVE  <-- needs debloat"; }
  printf '%-45s %s\n' "$pkg" "$s"
done < <(read_list "$ROOT/bloat.txt")

echo
echo "disabled on device: $(grep -c . <<<"$S_DISABLED")"
echo "animation scale:    $(ash settings get global window_animation_scale)"
if ash pidof com.amazon.tv.launcher >/dev/null; then echo "launcher:           running"; else echo "launcher:           NOT running (try restore or restart_launcher)"; fi
(( active == 0 )) && echo "status:             clean" || echo "status:             $active package(s) came back"
