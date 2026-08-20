# Architecture

## Design goal

`labhtb` is intentionally small. It is not a new attack framework and it does not replace the tools taught in CPTS.

Its job is to provide a thin workflow layer around OpenCode so the operator can focus on methodology and evidence instead of remembering every pending check.

The core loop is:

```text
Methodology
    ↓
Current State
    ↓
Next 1–3 Actions
    ↓
Evidence
    ↓
Report Notes
    └──────────────→ back into Current State
```

## Static project layer

These files are committed to Git and reused by every lab:

```text
AGENTS.md
opencode.json
setup.sh
start.sh
.opencode/skills/
templates/
docs/
```

### AGENTS.md

The persistent project instructions. It defines the operator experience and decision rules:

- methodology before random attacks,
- concise state-driven guidance,
- continuous evidence tracking,
- continuous reporting,
- no autonomous exploitation without an explicit operator request.

### opencode.json

Project-local OpenCode configuration. The v1 configuration uses automatic permission approval to minimize interruptions in an isolated training workflow.

### Skills

Skills hold specialized instructions that should not occupy context all the time.

```text
ad-methodology     → AD methodology and next-step decisions
reporting          → CPTS-style report notes
evidence-tracking  → evidence naming and proof tracking
```

OpenCode advertises available skills and loads a skill body only when the model decides it is relevant.

## External methodology layer

`CPTS-Checklists` remains an upstream dependency rather than copied project content.

```text
imjustBuck/CPTS-Checklists
          ↓
       setup.sh
          ↓
.cpts-checklists/
```

On first use `setup.sh` performs a shallow clone. Later launches perform a fast-forward-only update.

Benefits:

- no duplicated checklist repository,
- upstream improvements are easy to receive,
- the copilot always has a local filesystem copy it can read quickly,
- lab data remains independent of the methodology source.

## Runtime lab layer

Each target receives an isolated workspace:

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

The whole `labs/` directory is ignored by Git.

### brief.md

Small engagement bootstrap file containing the initial target context, including target identity and optional username/password. It is local-only, created with restrictive permissions where supported, and can be edited later with:

```bash
./start.sh <lab-name> --edit
```

### notes.md

The operational source of truth. It should remain concise enough that a cheap model can read it repeatedly without consuming unnecessary context.

It tracks:

- target identity,
- services and hosts,
- credentials/tickets/hashes,
- current foothold,
- important AD observations,
- attack-path hypotheses,
- completed and pending methodology coverage.

### commands.txt

A lightweight chronological command log. It prevents the final report from depending on shell history or memory.

### report-notes.md

Only report-worthy material belongs here. Findings are captured while the lab is active rather than reconstructed at the end.

### evidence/

Screenshots, raw proof, and artifacts intended to support report claims.

### raw/

Unprocessed tool outputs that may be useful later but do not yet deserve a report evidence reference.

## Startup flow

```text
./start.sh <lab-name>
        ↓
    setup.sh
        ↓
update methodology
        ↓
create/resume labs/<lab-name>
        ↓
load templates if new
        ↓
start OpenCode in lab directory
        ↓
OpenCode discovers project config,
AGENTS.md and skills by walking upward
        ↓
read brief.md + notes.md
        ↓
resume methodology
```

## Context and token strategy

The architecture is designed for inexpensive models.

1. `notes.md` is the compact state instead of replaying the entire conversation.
2. The full CPTS checklist repository is not read on every turn.
3. Only checklist files related to the current phase should be opened.
4. Skills are loaded on demand.
5. Responses are limited to the next 1–3 actions.
6. Raw tool output can be stored in files instead of repeatedly pasted into context.

This makes a cheap model suitable for routine tracking while preserving the option to switch models when reasoning becomes difficult.

## Trust boundaries

Committed project files contain reusable methodology instructions only.

Ignored runtime paths contain target-specific and potentially sensitive material:

```text
.cpts-checklists/
labs/
.env
loot/
output/
credential/ticket/key file patterns
```

`brief.md` is created with restrictive local permissions where supported.

The repository may be public, but real lab artifacts should never be committed.

## Why no autonomous agent in v1

The operator is studying CPTS methodology. Full autonomous exploitation would remove the exact decision-making practice the project is intended to reinforce.

The v1 copilot therefore owns organization, not the engagement:

```text
Operator owns:
- authorization
- execution decisions
- exploitation approval
- interpretation review

Copilot owns:
- state tracking
- methodology coverage
- next-step suggestions
- evidence reminders
- report-note maintenance
```

## Future extensions

Add features only after real lab use proves they save time. Likely candidates include:

- `/status` command for a compact methodology summary,
- `/report-review` for missing evidence/remediation checks,
- specialized BloodHound analysis skill,
- optional web/pivoting methodology skills,
- structured machine-readable state if Markdown becomes insufficient.

Avoid adding orchestration, MCP servers, databases, or dozens of skills until there is a demonstrated need.
