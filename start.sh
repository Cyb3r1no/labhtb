#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_NAME="${1:-}"

if [ -z "$LAB_NAME" ]; then
  read -r -p "Lab name: " LAB_NAME
fi

if [[ ! "$LAB_NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "[labhtb] Use only letters, numbers, dot, underscore or dash for the lab name." >&2
  exit 1
fi

bash "$ROOT_DIR/setup.sh"

LAB_DIR="$ROOT_DIR/labs/$LAB_NAME"
mkdir -p "$LAB_DIR/evidence" "$LAB_DIR/scans" "$LAB_DIR/raw"

[ -f "$LAB_DIR/notes.md" ] || cp "$ROOT_DIR/templates/notes.md" "$LAB_DIR/notes.md"
[ -f "$LAB_DIR/report-notes.md" ] || cp "$ROOT_DIR/templates/report-notes.md" "$LAB_DIR/report-notes.md"
touch "$LAB_DIR/commands.txt"
ln -sfn ../../.cpts-checklists "$LAB_DIR/CPTS-Checklists"

if [ ! -f "$LAB_DIR/brief.md" ]; then
  echo
  echo "[labhtb] New lab: $LAB_NAME"

  TARGET_IP=""
  while [ -z "$TARGET_IP" ]; do
    read -r -p "Target IP: " TARGET_IP
  done

  read -r -p "Username [NONE]: " USERNAME
  read -r -s -p "Password [NONE]: " PASSWORD
  echo

  USERNAME="${USERNAME:-NONE}"
  PASSWORD="${PASSWORD:-NONE}"

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

# Automatic baseline runs once for a new lab, then never repeats by itself.
if [ ! -f "$LAB_DIR/.recon-complete" ]; then
  echo
  echo "[labhtb] Recon..."
  if ! bash "$ROOT_DIR/recon.sh" "$TARGET_IP" "$LAB_DIR"; then
    echo "[labhtb] Recon had an issue; continuing to OpenCode." >&2
  fi
fi

PROMPT="Read brief.md, recon-summary.md if present, notes.md, and only the relevant CPTS-Checklists section. First save all meaningful recon results into notes.md and commands.txt. From now on act as my CPTS copilot: do not run more target-facing commands unless I explicitly use RUN:. Give exactly one best next action, explain why briefly, record every result before moving on, and wait for me. Use STATE, LOGGED, NEXT, WHY, EVIDENCE."

cd "$LAB_DIR"

echo
echo "[labhtb] Opening CPTS Copilot..."
echo

OPENCODE_ARGS=("." "--prompt" "$PROMPT")
if [ -n "${LABHTB_MODEL:-}" ]; then
  OPENCODE_ARGS+=("--model" "$LABHTB_MODEL")
fi

exec opencode "${OPENCODE_ARGS[@]}"
