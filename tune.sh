#!/usr/bin/env bash
# Speed tweaks: faster animations, clear caches, push Kodi cache config.
source "$(dirname "$0")/lib.sh"

SCALE="${ANIM_SCALE:-0.5}"   # 1 = stock, 0.5 = snappy, 0 = instant (choppy)

connect

for key in window_animation_scale transition_animation_scale animator_duration_scale; do
  ash settings put global "$key" "$SCALE"
done
echo "animation scale: $SCALE"

ash pm trim-caches 999G >/dev/null 2>&1 || true
echo "app caches trimmed"
echo "storage: $(ash df -h /data | awk 'NR==2 {print $4 " free of " $2}')"

KODI_DIR=/sdcard/Android/data/org.xbmc.kodi/files/.kodi/userdata
if [[ -f "$ROOT/kodi/advancedsettings.xml" ]] && ash pm list packages org.xbmc.kodi | grep -q kodi; then
  if adb -s "$TV" push "$ROOT/kodi/advancedsettings.xml" "$KODI_DIR/" >/dev/null 2>&1; then
    echo "kodi advancedsettings.xml pushed (restart Kodi to apply)"
  else
    echo "kodi: couldn't push config (open Kodi once so its folder exists, then re-run)"
  fi
fi
