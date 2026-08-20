# Workflow

## Daily use

From the repository root:

```bash
./start.sh <lab-name>
```

Example:

```bash
./start.sh authority
```

If no lab name is provided, the launcher asks for one.

On the first run for that lab, it asks only for:

- TARGET IP
- DOMAIN (or UNKNOWN)
- HOSTNAME (or UNKNOWN)
- USERNAME (or NONE)
- PASSWORD (or NONE)

Only the password input is hidden while typing. The resulting `brief.md` is stored only inside the ignored local lab workspace and is set to mode `600`.

The launcher creates:

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

1. Verifies Git and OpenCode are installed.
2. Clones `imjustBuck/CPTS-Checklists` on first use.
3. Fast-forward updates the methodology on later launches.
4. Creates or resumes the selected lab workspace.
5. Opens OpenCode from inside that workspace.
6. Supplies a short bootstrap prompt to resume from local state.

OpenCode discovers the repository `AGENTS.md`, `opencode.json`, and project skills by walking upward from the lab directory to the Git root. This behavior is supported by OpenCode's project rule/config/skill discovery model.

## First lab

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

Example answers:

```text
TARGET IP: 10.10.11.222
DOMAIN [UNKNOWN]: authority.htb
HOSTNAME [UNKNOWN]: dc
USERNAME [NONE]: logger
PASSWORD [NONE] (input hidden):
```

OpenCode then starts with the current lab brief and state already available.

## Editing lab metadata

To update the target, domain, hostname, username, or password for an existing lab:

```bash
./start.sh authority --edit
```

This opens `labs/authority/brief.md` using `$EDITOR`, or `nano` if `$EDITOR` is not set. When the editor closes, the launcher restores mode `600` and resumes the same lab.

## Operator loop

During a lab:

```text
Run a check
   ↓
Give OpenCode the result/output
   ↓
STATE — what changed
NEXT — only 1–3 logical actions
WHY — why those actions now
EVIDENCE — what to preserve
   ↓
notes.md / commands.txt / report-notes.md are updated
```

The goal is not to let the model run a full autonomous attack. The model keeps methodology and documentation organized while the operator remains responsible for the engagement decisions.

## Resuming a lab

Use the same lab name:

```bash
./start.sh authority
```

Existing `brief.md`, notes, commands, evidence, and report notes are preserved. The upstream methodology is updated before OpenCode launches.

## Cheap-model usage

To override the configured OpenCode model for one launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

Use `opencode models` to see the exact provider/model identifiers available in your OpenCode installation.

Recommended strategy:

```text
Routine state/checklist/report updates → cheap/fast model
Complex attack-path reasoning          → stronger model temporarily
```

## If the domain or hostname is unknown

Leave the value blank or use `UNKNOWN`.

The methodology copilot should discover and confirm it during enumeration before suggesting an `/etc/hosts` change. `AGENTS.md` explicitly tells the model not to guess host resolution data.

## Evidence discipline

When a result matters for the final report:

1. Preserve raw output when useful.
2. Capture a clear screenshot if visual proof helps.
3. Put report evidence under `evidence/` with descriptive sequential names.
4. Reference that evidence in `report-notes.md`.
5. Keep noisy/unprocessed outputs in `raw/` until they become useful.

## Updating only the methodology

You can run:

```bash
./setup.sh
```

This updates `.cpts-checklists/` without starting a specific lab.
