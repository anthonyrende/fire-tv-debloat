#!/usr/bin/env bash
# Uninstall (user 0) or disable every package in bloat.txt. Safe to re-run.
# Usage: ./debloat.sh [list-file]
source "$(dirname "$0")/lib.sh"

LIST="${1:-$ROOT/bloat.txt}"
[[ -f "$LIST" ]] || die "list not found: $LIST"

connect
load_state
mkdir -p "$ROOT/logs"
LOG="$ROOT/logs/results-$(date +%Y%m%d-%H%M%S).tsv"

while read -r pkg; do
  if [[ "$pkg" =~ $PROTECTED_RE ]]; then
    status="SKIPPED (protected pattern)"
  else
    case "$(state_of "$pkg")" in
      MISSING)     status="NOT ON DEVICE" ;;
      UNINSTALLED) status="already uninstalled" ;;
      DISABLED)    status="already disabled" ;;
      ACTIVE)
        out=$(ash pm uninstall -k --user 0 "$pkg" 2>&1 || true)
        if [[ "$out" == *Success* ]]; then
          status=UNINSTALLED
        else
          out2=$(ash pm disable-user --user 0 "$pkg" 2>&1 || true)
          if   [[ "$out2" == *disabled* ]];             then status=DISABLED
          elif [[ "$out2" == *"protected package"* ]];  then status="BLOCKED (protected by Amazon)"
          else status="BLOCKED: $(head -n1 <<<"$out2")"
          fi
        fi ;;
    esac
  fi
  printf '%s\t%s\n' "$pkg" "$status" | tee -a "$LOG"
done < <(read_list "$LIST")

ln -sf "$(basename "$LOG")" "$ROOT/logs/latest.tsv"
restart_launcher
echo "log: $LOG"
