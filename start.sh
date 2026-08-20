#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="${1:-}"
MODE="${2:-}"

if [ -z "$LAB_NAME" ]; then
  read -r -p "Lab name: " LAB_NAME
fi

if [[ ! "$LAB_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[labhtb] Lab name may contain only letters, numbers, dot, underscore and dash." >&2
  exit 1
fi

if [ -n "$MODE" ] && [ "$MODE" != "--edit" ] && [ "$MODE" != "--recon" ]; then
  echo "Usage: ./start.sh <lab-name> [--edit|--recon]" >&2
  exit 1
fi

bash "$ROOT_DIR/setup.sh"

LAB_DIR="$ROOT_DIR/labs/$LAB_NAME"
mkdir -p "$LAB_DIR/evidence" "$LAB_DIR/scans" "$LAB_DIR/raw"

if [ ! -f "$LAB_DIR/notes.md" ]; then
  cp "$ROOT_DIR/templates/notes.md" "$LAB_DIR/notes.md"
fi

if [ ! -f "$LAB_DIR/report-notes.md" ]; then
  cp "$ROOT_DIR/templates/report-notes.md" "$LAB_DIR/report-notes.md"
fi

touch "$LAB_DIR/commands.txt"
ln -sfn ../../.cpts-checklists "$LAB_DIR/CPTS-Checklists"

# Remove the old helper symlink from existing workspaces if present.
if [ -L "$LAB_DIR/LabTools" ]; then
  rm "$LAB_DIR/LabTools"
fi

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

  sed -i "s|^- Target IP: UNKNOWN$|- Target IP: $TARGET_IP|" "$LAB_DIR/notes.md"
  sed -i "s|^- Hostname: UNKNOWN$|- Hostname: $HOSTNAME|" "$LAB_DIR/notes.md"
  sed -i "s|^- Domain: UNKNOWN$|- Domain: $DOMAIN|" "$LAB_DIR/notes.md"
elif [ "$MODE" = "--edit" ]; then
  "${EDITOR:-nano}" "$LAB_DIR/brief.md"
  chmod 600 "$LAB_DIR/brief.md"
fi

TARGET_IP="$(sed -n 's/^- Target IP: //p' "$LAB_DIR/brief.md" | head -n 1)"

# One bounded automatic recon/enumeration pass per lab.
# Disable for one launch with LABHTB_RECON=0.
if [ "${LABHTB_RECON:-1}" != "0" ]; then
  if [ ! -f "$LAB_DIR/.recon-complete" ] || [ "$MODE" = "--recon" ]; then
    echo
    echo "[labhtb] Running bounded AUTO RECON before OpenCode..."
    if ! bash "$ROOT_DIR/recon.sh" "$TARGET_IP" "$LAB_DIR"; then
      echo "[labhtb] AUTO RECON did not finish cleanly; OpenCode will still start." >&2
    fi
  else
    echo "[labhtb] Existing recon found; skipping. Use --recon to rerun."
  fi
fi

PROMPT="COPILOT MODE. Read brief.md, recon-summary.md if present, notes.md, and only the relevant CPTS-Checklists section. FIRST persist every meaningful recon/enumeration result into notes.md before suggesting anything. The launcher already performs the bounded baseline recon; do not run additional target-facing commands unless I explicitly use RUN:. Recommend exactly one highest-value next action, explain why briefly, and wait for me. Use STATE, LOGGED, NEXT, WHY, EVIDENCE."

cd "$LAB_DIR"

echo
echo "[labhtb] Starting OpenCode in: $LAB_DIR"
echo "[labhtb] Mode: AUTO RECON -> COPILOT"
echo "[labhtb] Methodology: latest CPTS-Checklists"
if [ -n "${LABHTB_MODEL:-}" ]; then
  echo "[labhtb] Model override: $LABHTB_MODEL"
fi
echo

OPENCODE_ARGS=("." "--prompt" "$PROMPT")

if [ -n "${LABHTB_MODEL:-}" ]; then
  OPENCODE_ARGS+=("--model" "$LABHTB_MODEL")
fi

exec opencode "${OPENCODE_ARGS[@]}"
