# Workflow

## Daily use

From the repository root:

```bash
bash start.sh <lab-name>
```

Example:

```bash
bash start.sh authority
```

On the first run for that lab, the launcher asks for:

- TARGET IP
- DOMAIN (or UNKNOWN)
- HOSTNAME (or UNKNOWN)
- CREDENTIALS (or NONE)

It then creates a private runtime workspace under:

```text
labs/<lab-name>/
├── brief.md
├── notes.md
├── commands.txt
├── report-notes.md
├── evidence/
├── raw/
└── CPTS-Checklists -> ../../.cpts-checklists
```

The entire `labs/` directory is ignored by Git.

## What happens automatically

`start.sh` calls `setup.sh`, which:

1. Verifies Git and OpenCode are available.
2. Clones `imjustBuck/CPTS-Checklists` on first use.
3. Fast-forward updates that methodology on future launches.
4. Opens OpenCode inside the selected lab workspace.
5. Supplies a short startup prompt telling OpenCode to resume from local state.

Because OpenCode discovers `AGENTS.md` and project skills by traversing upward to the Git worktree, lab directories inherit the project instructions and `.opencode/skills/` automatically.

## Operator loop

During a lab:

```text
Run a check
   ↓
Give OpenCode the output
   ↓
STATE — what changed
NEXT — only 1–3 logical actions
WHY — why those actions now
EVIDENCE — what to preserve
   ↓
notes.md / commands.txt / report-notes.md are updated
```

## Cheap-model usage

To force a configured OpenCode model for the session:

```bash
LABHTB_MODEL='provider/model' bash start.sh authority
```

Keep a cheap/fast model for routine checklist tracking and state updates. Switch to a stronger model only when attack-path reasoning becomes genuinely difficult.

## Returning to a lab

Run the same command again:

```bash
bash start.sh authority
```

Existing `brief.md`, notes, commands, evidence and report notes are preserved. The methodology repository is updated before OpenCode opens.
