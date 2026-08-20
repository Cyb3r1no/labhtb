#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
OUTDIR="${2:-scans}"
MIN_RATE="${LABHTB_MIN_RATE:-3000}"

if [ -z "$TARGET" ]; then
  echo "Usage: bash LabTools/fast-scan.sh <target-ip> [output-dir]" >&2
  exit 1
fi

command -v nmap >/dev/null 2>&1 || {
  echo "[labhtb] nmap is required." >&2
  exit 1
}

mkdir -p "$OUTDIR"
DISCOVERY="$OUTDIR/nmap-allports"
SERVICES="$OUTDIR/nmap-services"

echo "[labhtb] Stage 1/2: fast TCP all-port discovery against $TARGET"
nmap -Pn -n -p- --min-rate "$MIN_RATE" -T4 "$TARGET" -oA "$DISCOVERY"

OPEN_PORTS="$({
  awk -F'Ports: ' '/Ports: / { print $2 }' "$DISCOVERY.gnmap" \
    | tr ',' '\n' \
    | awk -F/ '$2 == "open" { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1 }' \
    | paste -sd, -
} || true)"

if [ -z "$OPEN_PORTS" ]; then
  echo "[labhtb] No open TCP ports were identified."
  exit 2
fi

echo "[labhtb] Open TCP ports: $OPEN_PORTS"
echo "[labhtb] Stage 2/2: targeted service/default-script scan"
nmap -Pn -n -sC -sV -T4 -p"$OPEN_PORTS" "$TARGET" -oA "$SERVICES"

echo
printf '[labhtb] Discovery complete.\n'
printf '[labhtb] Ports: %s\n' "$OPEN_PORTS"
printf '[labhtb] Files: %s.{nmap,gnmap,xml} and %s.{nmap,gnmap,xml}\n' "$DISCOVERY" "$SERVICES"
