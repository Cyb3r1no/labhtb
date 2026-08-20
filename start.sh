#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="${1:-}"
EDIT_MODE="${2:-}"
SUDO_KEEPALIVE_PID=""

cleanup() {
  if [ -n "$SUDO_KEEPALIVE_PID" ]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

brief_value() {
  local key="$1"
  sed -n "s/^- ${key}: //p" "$LAB_DIR/brief.md" | head -n 1
}

sync_known_hosts() {
  [ -f "$LAB_DIR/brief.md" ] || return 0
  command -v sudo >/dev/null 2>&1 || return 0
  sudo -n true >/dev/null 2>&1 || return 0

  local target_ip domain hostname fqdn marker tmp
  local -a names=()
  local candidate existing

  target_ip="$(brief_value 'Target IP')"
  domain="$(brief_value 'Domain')"
  hostname="$(brief_value 'Hostname')"

  [ -n "$target_ip" ] || return 0

  add_name() {
    candidate="$1"
    [ -n "$candidate" ] || return 0
    [ "$candidate" != "UNKNOWN" ] || return 0
    for existing in "${names[@]:-}"; do
      [ "$existing" = "$candidate" ] && return 0
    done
    names+=("$candidate")
  }

  if [ -n "$hostname" ] && [ "$hostname" != "UNKNOWN" ]; then
    if [[ "$hostname" == *.* ]]; then
      add_name "$hostname"
    elif [ -n "$domain" ] && [ "$domain" != "UNKNOWN" ]; then
      fqdn="${hostname}.${domain}"
      add_name "$fqdn"
      add_name "$hostname"
    else
      add_name "$hostname"
    fi
  fi

  # HTB/CPTS labs commonly require the discovered/provided domain itself
  # to resolve to the current target. Only add it when it is known.
  if [ -n "$domain" ] && [ "$domain" != "UNKNOWN" ]; then
    add_name "$domain"
  fi

  [ "${#names[@]}" -gt 0 ] || return 0

  marker="# labhtb:${LAB_NAME}"
  tmp="$(mktemp)"
  awk -v marker="$marker" 'index($0, marker) == 0' /etc/hosts > "$tmp"
  printf '%s %s %s\n' "$target_ip" "${names[*]}" "$marker" >> "$tmp"
  sudo tee /etc/hosts < "$tmp" >/dev/null
  rm -f "$tmp"

  echo "[labhtb] /etc/hosts synced: $target_ip ${names[*]}"
  for candidate in "${names[@]}"; do
    if ! getent hosts "$candidate" >/dev/null 2>&1; then
      echo "[labhtb] Warning: resolution check failed for $candidate" >&2
    fi
  done
}

if [ -z "$LAB_NAME" ]; then
  read -r -p "Lab name: " LAB_NAME
fi

if [[ ! "$LAB_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[labhtb] Lab name may contain only letters, numbers, dot, underscore and dash." >&2
  exit 1
fi

if [ -n "$EDIT_MODE" ] && [ "$EDIT_MODE" != "--edit" ]; then
  echo "[labhtb] Unknown option: $EDIT_MODE" >&2
  echo "Usage: ./start.sh <lab-name> [--edit]" >&2
  exit 1
fi

bash "$ROOT_DIR/setup.sh"

LAB_DIR="$ROOT_DIR/labs/$LAB_NAME"
mkdir -p "$LAB_DIR/evidence" "$LAB_DIR/raw" "$LAB_DIR/scans"

if [ ! -f "$LAB_DIR/notes.md" ]; then
  cp "$ROOT_DIR/templates/notes.md" "$LAB_DIR/notes.md"
fi

if [ ! -f "$LAB_DIR/report-notes.md" ]; then
  cp "$ROOT_DIR/templates/report-notes.md" "$LAB_DIR/report-notes.md"
fi

touch "$LAB_DIR/commands.txt"
ln -sfn ../../.cpts-checklists "$LAB_DIR/CPTS-Checklists"

if [ ! -f "$LAB_DIR/brief.md" ]; then
  echo
  echo "[labhtb] New lab: $LAB_NAME"

  TARGET_IP=""
  while [ -z "$TARGET_IP" ]; do
    read -r -p "TARGET IP: " TARGET_IP
  done

  read -r -p "DOMAIN [UNKNOWN]: " DOMAIN
  read -r -p "HOSTNAME [UNKNOWN]: " HOSTNAME
  read -r -p "USERNAME [NONE]: " USERNAME
  read -r -s -p "PASSWORD [NONE] (input hidden): " PASSWORD
  echo

  DOMAIN="${DOMAIN:-UNKNOWN}"
  HOSTNAME="${HOSTNAME:-UNKNOWN}"
  USERNAME="${USERNAME:-NONE}"
  PASSWORD="${PASSWORD:-NONE}"

  cat > "$LAB_DIR/brief.md" <<EOF
# Lab Brief

- Lab: $LAB_NAME
- Target IP: $TARGET_IP
- Domain: $DOMAIN
- Hostname: $HOSTNAME
- Username: $USERNAME
- Password: $PASSWORD
- Scope: Authorized Hack The Box / CPTS practice lab
EOF

  chmod 600 "$LAB_DIR/brief.md"

  # Seed the most important state immediately so the model does not spend
  # context rediscovering values already supplied by the operator.
  sed -i "s|^- Target IP: UNKNOWN$|- Target IP: $TARGET_IP|" "$LAB_DIR/notes.md"
  sed -i "s|^- Hostname: UNKNOWN$|- Hostname: $HOSTNAME|" "$LAB_DIR/notes.md"
  sed -i "s|^- Domain: UNKNOWN$|- Domain: $DOMAIN|" "$LAB_DIR/notes.md"
elif [ "$EDIT_MODE" = "--edit" ]; then
  "${EDITOR:-nano}" "$LAB_DIR/brief.md"
  chmod 600 "$LAB_DIR/brief.md"
fi

# Give the OpenCode session access to sudo when a lab command needs it,
# without running the entire OpenCode process as root. Disable with LABHTB_SUDO=0.
if [ "${LABHTB_SUDO:-1}" != "0" ] && command -v sudo >/dev/null 2>&1; then
  echo
  echo "[labhtb] Authorizing sudo for this lab session..."
  if sudo -v; then
    (
      while kill -0 "$$" >/dev/null 2>&1; do
        sudo -n -v >/dev/null 2>&1 || exit 0
        sleep 50
      done
    ) &
    SUDO_KEEPALIVE_PID=$!
    echo "[labhtb] Sudo session active. OpenCode may use sudo when required."
    sync_known_hosts
  else
    echo "[labhtb] Sudo authorization failed; continuing with normal user permissions." >&2
  fi
fi

PROMPT="Read brief.md and notes.md first. Follow AGENTS.md and load only relevant project skills. Use CPTS-Checklists as the methodology source. FAST-START: if discovery is fresh, do fast all-port discovery first, then targeted service enumeration; immediately sync any confirmed hostname/domain/FQDN into /etc/hosts; validate supplied credentials with standard tooling before investigating unusual protocol behavior. Resume from current state, avoid repeating completed work, and keep responses concise using STATE, NEXT, WHY, EVIDENCE."

cd "$LAB_DIR"

echo
echo "[labhtb] Starting OpenCode in: $LAB_DIR"
echo "[labhtb] Methodology: latest CPTS-Checklists"
echo "[labhtb] Mode: fast-start / state-driven"
if [ -n "${LABHTB_MODEL:-}" ]; then
  echo "[labhtb] Model override: $LABHTB_MODEL"
fi
echo

OPENCODE_ARGS=("." "--auto" "--prompt" "$PROMPT")

if [ -n "${LABHTB_MODEL:-}" ]; then
  OPENCODE_ARGS+=("--model" "$LABHTB_MODEL")
fi

opencode "${OPENCODE_ARGS[@]}"
