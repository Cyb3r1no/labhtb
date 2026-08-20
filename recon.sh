#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
LAB_DIR="${2:-}"

if [ -z "$TARGET" ] || [ -z "$LAB_DIR" ]; then
  echo "Usage: bash recon.sh <target-ip> <lab-dir>" >&2
  exit 1
fi

command -v nmap >/dev/null 2>&1 || {
  echo "[labhtb] nmap is required for automatic recon." >&2
  exit 1
}

mkdir -p "$LAB_DIR/scans" "$LAB_DIR/raw"

ALL="$LAB_DIR/scans/nmap-allports"
SERVICES="$LAB_DIR/scans/nmap-services"
SUMMARY="$LAB_DIR/recon-summary.md"

run_bounded() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$1" "${@:2}"
  else
    "${@:2}"
  fi
}

echo
printf '[labhtb] AUTO RECON — bounded discovery/enumeration only\n'
printf '[labhtb] Target: %s\n' "$TARGET"

# Stage 1: discover TCP ports quickly.
echo "[labhtb] 1/4 Fast TCP port discovery..."
nmap -Pn -n -p- --min-rate "${LABHTB_MIN_RATE:-3000}" -T4 "$TARGET" -oA "$ALL"

OPEN_PORTS="$({
  awk -F'Ports: ' '/Ports: / { print $2 }' "$ALL.gnmap" \
    | tr ',' '\n' \
    | awk -F/ '$2 == "open" { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1 }' \
    | paste -sd, -
} || true)"

if [ -z "$OPEN_PORTS" ]; then
  cat > "$SUMMARY" <<EOF
# Recon Summary

- Target: $TARGET
- Open TCP Ports: none discovered
- Automatic recon: COMPLETE
- Enumeration: no TCP service enumeration possible
EOF
  touch "$LAB_DIR/.recon-complete"
  echo "[labhtb] No open TCP ports discovered."
  exit 0
fi

echo "[labhtb] Open TCP ports: $OPEN_PORTS"

# Stage 2: service/version/default-script scan only on confirmed ports.
echo "[labhtb] 2/4 Targeted service enumeration..."
nmap -Pn -n -sC -sV -T4 -p"$OPEN_PORTS" "$TARGET" -oA "$SERVICES"

SMB_RESULT="not run"
LDAP_RESULT="not run"

has_port() {
  case ",$OPEN_PORTS," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

# Stage 3: one bounded SMB identity/null-session check when SMB exists.
if has_port 445 && command -v nxc >/dev/null 2>&1; then
  echo "[labhtb] 3/4 SMB baseline enumeration with NetExec..."
  {
    echo '### NetExec SMB identity'
    run_bounded 45 nxc smb "$TARGET" || true
    echo
    echo '### NetExec SMB anonymous share check'
    run_bounded 45 nxc smb "$TARGET" -u '' -p '' --shares || true
  } | tee "$LAB_DIR/raw/nxc-smb-baseline.txt"
  SMB_RESULT="raw/nxc-smb-baseline.txt"
else
  echo "[labhtb] 3/4 SMB baseline skipped (445 closed or nxc unavailable)."
fi

# Stage 4: bounded LDAP RootDSE discovery when LDAP exists.
LDAP_PORTS=""
for p in 389 636; do
  if has_port "$p"; then
    LDAP_PORTS="${LDAP_PORTS:+$LDAP_PORTS,}$p"
  fi
done

if [ -n "$LDAP_PORTS" ]; then
  echo "[labhtb] 4/4 LDAP RootDSE enumeration..."
  run_bounded 60 nmap -Pn -n -p"$LDAP_PORTS" --script ldap-rootdse "$TARGET" -oN "$LAB_DIR/raw/ldap-rootdse.txt" || true
  LDAP_RESULT="raw/ldap-rootdse.txt"
else
  echo "[labhtb] 4/4 LDAP baseline skipped (389/636 closed)."
fi

cat > "$SUMMARY" <<EOF
# Recon Summary

- Target: $TARGET
- Open TCP Ports: $OPEN_PORTS
- Port discovery: scans/nmap-allports.nmap
- Service enumeration: scans/nmap-services.nmap
- SMB baseline: $SMB_RESULT
- LDAP RootDSE: $LDAP_RESULT
- Automatic recon: COMPLETE

## Boundary

This automatic phase stops here. It performs discovery and basic unauthenticated enumeration only. Further enumeration, credential use, exploitation, or lateral movement belongs to the operator/Copilot loop.
EOF

touch "$LAB_DIR/.recon-complete"
printf '\n[labhtb] AUTO RECON complete. OpenCode will review and log the results.\n'
