#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
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

mkdir -p "$ROOT_DIR/labs"

if [ -d "$CHECKLIST_DIR/.git" ]; then
  echo "[labhtb] Updating CPTS-Checklists..."
  git -C "$CHECKLIST_DIR" pull --ff-only
elif [ -e "$CHECKLIST_DIR" ]; then
  echo "[labhtb] $CHECKLIST_DIR exists but is not a Git repository." >&2
  echo "[labhtb] Rename/remove it and run setup again." >&2
  exit 1
else
  echo "[labhtb] Cloning latest CPTS-Checklists..."
  git clone --depth 1 "$CHECKLIST_REPO" "$CHECKLIST_DIR"
fi

echo "[labhtb] Workspace dependencies are ready."
