#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="${1:-}"

if [ -z "$LAB_NAME" ]; then
  read -r -p "Lab name: " LAB_NAME
fi

if [[ ! "$LAB_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[labhtb] Lab name may contain only letters, numbers, dot, underscore and dash." >&2
  exit 1
fi

"$ROOT_DIR/setup.sh"

LAB_DIR="$ROOT_DIR/labs/$LAB_NAME"
mkdir -p "$LAB_DIR/evidence" "$LAB_DIR/raw"

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
  read -r -p "TARGET IP: " TARGET_IP
  read -r -p "DOMAIN [UNKNOWN]: " DOMAIN
  read -r -p "HOSTNAME [UNKNOWN]: " HOSTNAME
  read -r -p "CREDENTIALS [NONE]: " CREDENTIALS

  DOMAIN="${DOMAIN:-UNKNOWN}"
  HOSTNAME="${HOSTNAME:-UNKNOWN}"
  CREDENTIALS="${CREDENTIALS:-NONE}"

  cat > "$LAB_DIR/brief.md" <<EOF
# Lab Brief

- Lab: $LAB_NAME
- Target IP: $TARGET_IP
- Domain: $DOMAIN
- Hostname: $HOSTNAME
- Credentials: $CREDENTIALS
- Scope: Authorized Hack The Box / CPTS practice lab
EOF

  chmod 600 "$LAB_DIR/brief.md"
fi

PROMPT="Read brief.md and notes.md. Follow the repository AGENTS.md and relevant skills. Use CPTS-Checklists as the methodology source. Begin or resume the lab from current state. Keep responses concise and use STATE, NEXT, WHY, EVIDENCE."

cd "$LAB_DIR"

echo
 echo "[labhtb] Starting OpenCode in: $LAB_DIR"
 echo "[labhtb] Methodology: latest CPTS-Checklists"
 echo

OPENCODE_ARGS=("." "--auto" "--prompt" "$PROMPT")

if [ -n "${LABHTB_MODEL:-}" ]; then
  OPENCODE_ARGS+=("--model" "$LABHTB_MODEL")
fi

exec opencode "${OPENCODE_ARGS[@]}"
