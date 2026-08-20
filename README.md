# labhtb

A lightweight OpenCode workspace for authorized Hack The Box / CPTS practice labs.

The project keeps the workflow simple:

**Methodology → State → Next actions → Evidence → Report notes**

It uses the latest upstream [`imjustBuck/CPTS-Checklists`](https://github.com/imjustBuck/CPTS-Checklists) as the methodology source without vendoring a stale copy into this repository.

## Why

CPTS labs can become difficult to manage because the operator has to remember methodology, commands, credentials, attack paths, screenshots, and reporting at the same time. `labhtb` keeps those responsibilities organized while leaving the actual testing decisions in the operator's hands.

OpenCode acts as a methodology copilot, not an autonomous pentest agent.

## Quick start

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

On the first launch for a lab you provide only:

```text
TARGET IP: 10.10.11.X
DOMAIN: UNKNOWN
HOSTNAME: UNKNOWN
CREDENTIALS: NONE
```

The launcher then opens OpenCode inside a private per-lab workspace.

## Project layout

```text
labhtb/
├── AGENTS.md
├── opencode.json
├── setup.sh
├── start.sh
├── .opencode/
│   └── skills/
│       ├── ad-methodology/
│       │   └── SKILL.md
│       ├── reporting/
│       │   └── SKILL.md
│       └── evidence-tracking/
│           └── SKILL.md
├── templates/
│   ├── notes.md
│   └── report-notes.md
├── docs/
│   ├── WORKFLOW.md
│   └── ARCHITECTURE.md
└── .gitignore
```

Runtime data is created locally and ignored by Git:

```text
.cpts-checklists/
labs/
```

Each lab gets:

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

## What happens automatically

`./start.sh <lab-name>`:

1. Verifies Git and OpenCode are available.
2. Clones or fast-forward updates the latest CPTS-Checklists copy.
3. Creates or resumes the selected lab workspace.
4. Preserves existing notes, evidence, commands, and report material.
5. Starts OpenCode with project instructions and auto-approved permissions.
6. Keeps responses focused on `STATE`, `NEXT`, `WHY`, and `EVIDENCE`.

## Skills

The project intentionally starts with only three focused skills:

- **ad-methodology** — methodology coverage and next-step reasoning for AD work.
- **reporting** — continuous CPTS-style report notes.
- **evidence-tracking** — screenshots, raw outputs, and proof references.

Skills are loaded only when relevant, which keeps context smaller and makes inexpensive models practical for routine work.

## Model selection

Use the model already selected in OpenCode, or override it for a launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

A cheap/fast model is usually enough for state tracking, checklist coverage, and report-note maintenance. Switch to a stronger model only for difficult attack-path reasoning.

## OpenCode behavior

`AGENTS.md` is the project brain. OpenCode reads it automatically when working under this Git repository. The rules require the copilot to:

- read current state before suggesting actions,
- lazy-load only relevant checklist files,
- give at most 1–3 next actions,
- explain why those actions are next,
- update notes and reporting continuously,
- avoid inventing evidence or results,
- avoid autonomous exploitation unless explicitly requested.

`opencode.json` currently uses auto-allow permissions for a low-friction lab workflow.

## Documentation

- [Workflow](docs/WORKFLOW.md)
- [Architecture](docs/ARCHITECTURE.md)

## Scope

Use this project only against systems you own or are explicitly authorized to test, including authorized Hack The Box training environments.
