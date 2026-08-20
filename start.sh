#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="${1:-}"
CHECKLIST_DIR="$ROOT_DIR/.cpts-checklists"
CHECKLIST_REPO="https://github.com/imjustBuck/CPTS-Checklists.git"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[labhtb] Missing required command: $1" >&2
    exit 1
  }
}

need git
need opencode

if [ -z "$LAB_NAME" ]; then
  read -r -p "Lab name: " LAB_NAME
fi

if [[ ! "$LAB_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[labhtb] Use only letters, numbers, dot, underscore or dash for the lab name." >&2
  exit 1
fi

# Keep the external CPTS methodology current automatically.
if [ -d "$CHECKLIST_DIR/.git" ]; then
  echo "[labhtb] Updating CPTS-Checklists..."
  git -C "$CHECKLIST_DIR" pull --ff-only >/dev/null || true
elif [ -e "$CHECKLIST_DIR" ]; then
  echo "[labhtb] $CHECKLIST_DIR exists but is not a Git repository." >&2
  exit 1
else
  echo "[labhtb] Getting CPTS-Checklists..."
  git clone --depth 1 "$CHECKLIST_REPO" "$CHECKLIST_DIR" >/dev/null
fi

LAB_DIR="$ROOT_DIR/labs/$LAB_NAME"
mkdir -p "$LAB_DIR/evidence" "$LAB_DIR/scans" "$LAB_DIR/raw"

[ -f "$LAB_DIR/notes.md" ] || cp "$ROOT_DIR/templates/notes.md" "$LAB_DIR/notes.md"
[ -f "$LAB_DIR/report-notes.md" ] || cp "$ROOT_DIR/templates/report-notes.md" "$LAB_DIR/report-notes.md"
touch "$LAB_DIR/commands.txt"

ln -sfn ../../.cpts-checklists "$LAB_DIR/CPTS-Checklists"
ln -sfn ../../knowledge/cpts-map.md "$LAB_DIR/CPTS-MAP.md"

# Optional full personal notes. Keep them local and out of Git.
if [ -f "$ROOT_DIR/cpts-notes.md" ]; then
  ln -sfn ../../cpts-notes.md "$LAB_DIR/CPTS-NOTES.md"
elif [ -L "$LAB_DIR/CPTS-NOTES.md" ]; then
  rm -f "$LAB_DIR/CPTS-NOTES.md"
fi

if [ ! -f "$LAB_DIR/brief.md" ]; then
  echo
  echo "[labhtb] New lab: $LAB_NAME"

  TARGET_IP=""
  while [ -z "$TARGET_IP" ]; do
    read -r -p "Target IP: " TARGET_IP
  done

  read -r -p "Username [NONE]: " USERNAME
  USERNAME="${USERNAME:-NONE}"

  PASSWORD="NONE"
  if [ "$USERNAME" != "NONE" ]; then
    read -r -s -p "Password [NONE]: " PASSWORD
    echo
    PASSWORD="${PASSWORD:-NONE}"
  fi

  cat > "$LAB_DIR/brief.md" <<EOF
# Lab Brief

- Lab: $LAB_NAME
- Target IP: $TARGET_IP
- Domain: UNKNOWN
- Hostname: UNKNOWN
- Username: $USERNAME
- Password: $PASSWORD
- Scope: Authorized Hack The Box / CPTS practice lab
EOF

  chmod 600 "$LAB_DIR/brief.md"
  sed -i "s|^- Target IP: UNKNOWN$|- Target IP: $TARGET_IP|" "$LAB_DIR/notes.md"
fi

TARGET_IP="$(sed -n 's/^- Target IP: //p' "$LAB_DIR/brief.md" | head -n 1)"
USERNAME="$(sed -n 's/^- Username: //p' "$LAB_DIR/brief.md" | head -n 1)"
PASSWORD="$(sed -n 's/^- Password: //p' "$LAB_DIR/brief.md" | head -n 1)"

# Rebuilt baseline runs once for each lab. Existing old lab markers do not block it.
if [ ! -f "$LAB_DIR/.baseline-v2-complete" ]; then
  echo
  echo "[labhtb] Baseline recon + enumeration..."
  if LABHTB_USER="$USERNAME" LABHTB_PASS="$PASSWORD" \
      bash "$ROOT_DIR/recon.sh" "$TARGET_IP" "$LAB_DIR"; then
    touch "$LAB_DIR/.baseline-v2-complete"
  else
    echo "[labhtb] Baseline had an issue; opening Copilot anyway." >&2
  fi
fi

PROMPT="Read brief.md, recon-summary.md if present, notes.md, CPTS-MAP.md, and only the relevant CPTS-Checklists section. Read CPTS-NOTES.md only when useful if it exists. First persist all meaningful baseline results into notes.md. Maintain PHASE. From now on act as my CPTS copilot: record each result before moving on, recommend exactly one best next action, and wait. Do not run target-facing commands unless I explicitly use RUN:."

cd "$LAB_DIR"

echo
echo "[labhtb] Opening CPTS Copilot..."
echo "[labhtb] Use /status anytime. Use /stuck when you lose the path."
echo

OPENCODE_ARGS=("." "--prompt" "$PROMPT")
if [ -n "${LABHTB_MODEL:-}" ]; then
  OPENCODE_ARGS+=("--model" "$LABHTB_MODEL")
fi

exec opencode "${OPENCODE_ARGS[@]}"
