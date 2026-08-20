# labhtb

A fast, state-driven OpenCode workspace for authorized Hack The Box / CPTS practice labs.

The project keeps the workflow simple:

**Fast discovery → Identity/names → Access validation → Methodology → Evidence → Report**

It uses the latest upstream [`imjustBuck/CPTS-Checklists`](https://github.com/imjustBuck/CPTS-Checklists) as the methodology source without vendoring a stale copy into this repository.

## Why

CPTS labs become slow when the operator has to remember methodology, commands, credentials, attack paths, name resolution, screenshots, and reporting at the same time. `labhtb` keeps those responsibilities organized while leaving engagement decisions in the operator's hands.

OpenCode acts as a methodology copilot, not a blind autonomous pentest agent.

## Quick start

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

On the first launch you provide only:

```text
TARGET IP: 10.10.11.X
DOMAIN: UNKNOWN
HOSTNAME: UNKNOWN
USERNAME: NONE
PASSWORD: NONE
```

Only the password prompt is hidden while typing.

## Fast-start behavior

The first minutes of a fresh lab are optimized for useful facts, not exhaustive slow scans.

Default discovery strategy:

```bash
# 1) Fast all-port discovery
nmap -Pn -n -p- --min-rate 3000 -T4 <TARGET> -oA scans/nmap-allports

# 2) Targeted deep scan against confirmed open ports only
nmap -Pn -n -sC -sV -p<OPEN_PORTS> -T4 <TARGET> -oA scans/nmap-services
```

The copilot should then immediately:

1. identify hostname/domain/FQDN/DC context,
2. synchronize confirmed names into `/etc/hosts`,
3. validate supplied credentials with standard tooling,
4. begin protocol-specific enumeration,
5. avoid repeating checks already completed.

It should **not** use `-p- -sC -sV` as the default initial Nmap scan.

## `/etc/hosts` automation

Name resolution is treated as an early setup task.

If DOMAIN/HOSTNAME are supplied when the lab starts, `start.sh` creates an idempotent managed entry such as:

```text
10.10.11.X dc.authority.htb dc authority.htb # labhtb:authority
```

Only the line marked for that lab is replaced on future runs, preventing duplicate labhtb mappings.

If names are initially `UNKNOWN`, the copilot is instructed to update `/etc/hosts` immediately after hostname/domain/FQDN is confirmed through scan, SMB, LDAP, Kerberos, DNS, or other evidence, then verify resolution with `getent hosts` and continue working.

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

Runtime data is local and ignored by Git:

```text
.cpts-checklists/
labs/
```

Each lab receives:

```text
labs/<lab-name>/
├── brief.md
├── notes.md
├── commands.txt
├── report-notes.md
├── scans/
├── evidence/
├── raw/
└── CPTS-Checklists -> ../../.cpts-checklists
```

`brief.md` is local-only, ignored by Git, and set to mode `600`. It contains startup metadata, including username/password when provided.

## What happens automatically

`./start.sh <lab-name>`:

1. Verifies Git and OpenCode.
2. Clones or updates the latest CPTS-Checklists.
3. Creates/resumes the isolated lab workspace.
4. Creates `scans/`, `raw/`, and `evidence/` directories.
5. Seeds target/domain/hostname state from operator input.
6. Requests `sudo` once and keeps its timestamp active during the OpenCode session.
7. Synchronizes provided hostname/domain into `/etc/hosts` when known.
8. Starts OpenCode in fast-start, state-driven mode.
9. Keeps responses focused on `STATE`, `NEXT`, `WHY`, and `EVIDENCE`.

## Authentication troubleshooting

The copilot follows a short validation chain instead of jumping to unusual explanations:

```text
local vs domain context
        ↓
baseline credential validation (e.g. SMB/NetExec)
        ↓
protocol-specific authorization (e.g. WinRM/NetExec)
        ↓
only then investigate JEA/custom WSMan/edge cases if evidence exists
```

This prevents wasting time on custom SOAP or unsupported hypotheses when standard tools can answer the question quickly.

## Permissions

`opencode.json` uses `permission: "allow"`, and `start.sh` launches OpenCode with `--auto` for a low-friction authorized lab workflow.

OpenCode itself stays as the normal Kali user. `start.sh` pre-authorizes `sudo` so individual commands that genuinely need local elevation can use it without relaunching the whole workspace as root.

Disable sudo keepalive for one launch with:

```bash
LABHTB_SUDO=0 ./start.sh authority
```

## Editing an existing lab

```bash
./start.sh authority --edit
```

This opens the local `brief.md` in `$EDITOR` (or `nano`) and then resumes normally.

## Skills

Only three focused skills are included initially:

- **ad-methodology** — fast AD methodology coverage and next-step reasoning.
- **reporting** — continuous CPTS-style report notes.
- **evidence-tracking** — screenshots, raw outputs, and proof references.

Skills load only when relevant to keep context small and cheap models useful.

## Model selection

Use the current OpenCode model or override one launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

Routine state/checklist work can use a fast inexpensive model. Switch to a stronger model only for genuinely difficult attack-path reasoning.

## Core behavior

`AGENTS.md` is the project brain. It requires the copilot to:

- read current state first,
- prioritize the shortest reliable path to useful facts,
- use two-stage Nmap discovery,
- synchronize confirmed names into `/etc/hosts`,
- validate credentials systematically,
- lazy-load only relevant checklist files,
- give only 1–3 next actions,
- update state/evidence/reporting continuously,
- avoid long-lived automated interactive shells,
- avoid unsupported hypotheses and invented evidence,
- avoid autonomous exploitation unless explicitly requested.

## Documentation

- [Workflow](docs/WORKFLOW.md)
- [Architecture](docs/ARCHITECTURE.md)

## Scope

Use this project only against systems you own or are explicitly authorized to test, including authorized Hack The Box training environments.
