# fire-tv-debloat

Debloat + tune scripts for an Insignia NS-43DF710 (Fire TV Edition), via ADB over Wi-Fi. No root.
Tested on Fire OS 8.1.8.5 (RS8185/3891).

## Setup (once)
1. On the TV: Settings → My Fire TV → About → click the device name 7× → Developer Options → **ADB debugging** on.
2. Install adb (`sudo apt install adb`, or Google's platform-tools zip if the distro version is old).
3. `cp .env.example .env` and set `TV_IP`.
4. First connection: run any script and accept the RSA prompt on the TV.

## After a Fire OS update
```bash
./post-update.sh        # debloat → tune → reboot → restart launcher → verify
```

## Scripts
| Script | What it does |
|---|---|
| `post-update.sh` | Runs the whole pipeline. `--no-reboot` to skip the reboot. |
| `debloat.sh [list]` | Uninstalls (user 0) or disables everything in `bloat.txt`. Idempotent. Logs to `logs/`. |
| `verify.sh` | Shows each package's state; flags anything an update brought back. |
| `tune.sh` | Animation scale (default 0.5), clears caches, pushes Kodi cache config. |
| `restore.sh [pkg…]` | Re-enables / reinstalls packages. No args = everything in `bloat.txt`. |

## Notes
- Nothing is deleted from the system partition — `restore.sh` or a factory reset brings everything back.
- `lib.sh` has a `PROTECTED_RE` guard: launcher/settings/input/framework/etc. are skipped even if listed.
- If the home screen hangs on "loading" after debloating: the scripts restart the launcher automatically; manually it's
  `adb shell am force-stop com.amazon.tv.launcher`.
- 4 packages are protected by Amazon on FOS 8.1 and can't be touched via ADB (see bottom of `bloat.txt`) — block their traffic with Pi-hole / NextDNS instead.
- Add packages one or two at a time, reboot, test.
