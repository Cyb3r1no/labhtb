#!/usr/bin/env bash
set -euo pipefail

LAB_NAME="${1:-}"
TARGET_IP="${2:-}"
shift $(( $# >= 2 ? 2 : $# ))

if [ -z "$LAB_NAME" ] || [ -z "$TARGET_IP" ] || [ "$#" -lt 1 ]; then
  echo "Usage: bash LabTools/sync-hosts.sh <lab-name> <target-ip> <confirmed-name> [more-names...]" >&2
  exit 1
fi

command -v sudo >/dev/null 2>&1 || {
  echo "[labhtb] sudo is required to update /etc/hosts." >&2
  exit 1
}

MARKER="# labhtb:${LAB_NAME}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

NAMES=()
for candidate in "$@"; do
  [ -n "$candidate" ] || continue
  [ "$candidate" != "UNKNOWN" ] || continue
  [ "$candidate" != "NONE" ] || continue

  if [[ ! "$candidate" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "[labhtb] Ignoring unsafe host token: $candidate" >&2
    continue
  fi

  duplicate=0
  for existing in "${NAMES[@]:-}"; do
    if [ "$existing" = "$candidate" ]; then
      duplicate=1
      break
    fi
  done
  [ "$duplicate" -eq 1 ] || NAMES+=("$candidate")
done

if [ "${#NAMES[@]}" -eq 0 ]; then
  echo "[labhtb] No confirmed hostnames were supplied." >&2
  exit 1
fi

awk -v marker="$MARKER" 'index($0, marker) == 0' /etc/hosts > "$TMP"
printf '%s %s %s\n' "$TARGET_IP" "${NAMES[*]}" "$MARKER" >> "$TMP"
sudo tee /etc/hosts < "$TMP" >/dev/null

echo "[labhtb] /etc/hosts synced: $TARGET_IP ${NAMES[*]}"
for candidate in "${NAMES[@]}"; do
  if getent hosts "$candidate" >/dev/null 2>&1; then
    echo "[labhtb] resolved: $candidate"
  else
    echo "[labhtb] warning: resolution check failed for $candidate" >&2
  fi
done
