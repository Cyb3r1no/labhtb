#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
LAB_DIR="${2:-}"
USER_NAME="${LABHTB_USER:-NONE}"
USER_PASS="${LABHTB_PASS:-NONE}"

if [ -z "$TARGET" ] || [ -z "$LAB_DIR" ]; then
  echo "Usage: recon.sh <target-ip> <lab-dir>" >&2
  exit 1
fi

command -v nmap >/dev/null 2>&1 || {
  echo "[labhtb] nmap is required." >&2
  exit 1
}

mkdir -p "$LAB_DIR/scans" "$LAB_DIR/raw"

ALL="$LAB_DIR/scans/nmap-allports"
SERVICES="$LAB_DIR/scans/nmap-services"
SUMMARY="$LAB_DIR/recon-summary.md"
COMMANDS="$LAB_DIR/commands.txt"

bounded() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  else
    "$@"
  fi
}

has_port() {
  case ",$OPEN_PORTS," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

log_command() {
  printf '%s\n' "$1" >> "$COMMANDS"
}

echo
printf '[labhtb] 1/4 Fast TCP discovery\n'
log_command "nmap -Pn -n -p- --min-rate ${LABHTB_MIN_RATE:-3000} -T4 $TARGET -oA scans/nmap-allports"
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
- Baseline: COMPLETE
- Next: Copilot should review whether UDP, filtering, routing, or target availability needs attention.
EOF
  echo "[labhtb] No open TCP ports discovered."
  exit 0
fi

printf '[labhtb] Open ports: %s\n' "$OPEN_PORTS"

echo "[labhtb] 2/4 Targeted service enumeration"
log_command "nmap -Pn -n -sC -sV -T4 -p$OPEN_PORTS $TARGET -oA scans/nmap-services"
nmap -Pn -n -sC -sV -T4 -p"$OPEN_PORTS" "$TARGET" -oA "$SERVICES"

SMB_BASELINE="not applicable"
LDAP_BASELINE="not applicable"
AUTH_BASELINE="not supplied"

# Basic SMB identity / anonymous access only.
if has_port 445 && command -v nxc >/dev/null 2>&1; then
  echo "[labhtb] 3/4 SMB baseline"
  log_command "nxc smb $TARGET"
  log_command "nxc smb $TARGET -u '' -p '' --shares"
  {
    echo '### SMB identity'
    bounded 45 nxc smb "$TARGET" || true
    echo
    echo '### Anonymous shares'
    bounded 45 nxc smb "$TARGET" -u '' -p '' --shares || true
  } | tee "$LAB_DIR/raw/smb-baseline.txt"
  SMB_BASELINE="raw/smb-baseline.txt"
else
  echo "[labhtb] 3/4 SMB baseline skipped"
fi

# LDAP RootDSE is useful for domain/DC identity and is unauthenticated.
LDAP_PORTS=""
for p in 389 636; do
  if has_port "$p"; then
    LDAP_PORTS="${LDAP_PORTS:+$LDAP_PORTS,}$p"
  fi
done

if [ -n "$LDAP_PORTS" ]; then
  echo "[labhtb] 4/4 LDAP RootDSE baseline"
  log_command "nmap -Pn -n -p$LDAP_PORTS --script ldap-rootdse $TARGET -oN raw/ldap-rootdse.txt"
  bounded 60 nmap -Pn -n -p"$LDAP_PORTS" --script ldap-rootdse "$TARGET" \
    -oN "$LAB_DIR/raw/ldap-rootdse.txt" || true
  LDAP_BASELINE="raw/ldap-rootdse.txt"
else
  echo "[labhtb] 4/4 LDAP baseline skipped"
fi

# If the operator supplied one credential pair, validate it only against the
# most useful AD access protocols that are actually exposed. No spraying.
if [ "$USER_NAME" != "NONE" ] && [ -n "$USER_NAME" ] && \
   [ "$USER_PASS" != "NONE" ] && [ -n "$USER_PASS" ] && \
   command -v nxc >/dev/null 2>&1; then
  AUTH_BASELINE="raw/auth-baseline.txt"
  : > "$LAB_DIR/$AUTH_BASELINE"

  if has_port 445; then
    echo "[labhtb] Validating supplied credential on SMB"
    log_command "nxc smb $TARGET -u '$USER_NAME' -p '<PASSWORD>'"
    log_command "nxc smb $TARGET -u '$USER_NAME' -p '<PASSWORD>' --shares"
    {
      echo '### SMB credential validation'
      bounded 45 nxc smb "$TARGET" -u "$USER_NAME" -p "$USER_PASS" || true
      echo
      echo '### SMB shares with supplied credential'
      bounded 45 nxc smb "$TARGET" -u "$USER_NAME" -p "$USER_PASS" --shares || true
      echo
    } >> "$LAB_DIR/$AUTH_BASELINE"
  fi

  if { has_port 389 || has_port 636; }; then
    echo "[labhtb] Validating supplied credential on LDAP"
    log_command "nxc ldap $TARGET -u '$USER_NAME' -p '<PASSWORD>'"
    {
      echo '### LDAP credential validation'
      bounded 45 nxc ldap "$TARGET" -u "$USER_NAME" -p "$USER_PASS" || true
      echo
    } >> "$LAB_DIR/$AUTH_BASELINE"
  fi

  if has_port 5985 || has_port 5986; then
    echo "[labhtb] Validating supplied credential on WinRM"
    log_command "nxc winrm $TARGET -u '$USER_NAME' -p '<PASSWORD>'"
    {
      echo '### WinRM credential validation'
      bounded 45 nxc winrm "$TARGET" -u "$USER_NAME" -p "$USER_PASS" || true
      echo
    } >> "$LAB_DIR/$AUTH_BASELINE"
  fi

  if [ ! -s "$LAB_DIR/$AUTH_BASELINE" ]; then
    rm -f "$LAB_DIR/$AUTH_BASELINE"
    AUTH_BASELINE="supplied, but no supported AD access protocol was exposed"
  fi
fi

cat > "$SUMMARY" <<EOF
# Recon Summary

- Target: $TARGET
- Open TCP Ports: $OPEN_PORTS
- Port discovery: scans/nmap-allports.nmap
- Service enumeration: scans/nmap-services.nmap
- SMB baseline: $SMB_BASELINE
- LDAP RootDSE: $LDAP_BASELINE
- Supplied credential baseline: $AUTH_BASELINE
- Baseline: COMPLETE

## Boundary

The automatic phase ends here. It performs discovery, basic unauthenticated enumeration, and validation of the single credential pair supplied by the operator when relevant. It does not spray passwords, exploit, escalate privileges, move laterally, or chain attacks.
EOF

printf '\n[labhtb] Baseline complete.\n'
