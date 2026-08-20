# labhtb

A simple OpenCode copilot for authorized Hack The Box / CPTS practice labs.

The idea is intentionally small:

**You test → OpenCode records → OpenCode gives one next step → you continue**

`labhtb` uses the latest upstream [`imjustBuck/CPTS-Checklists`](https://github.com/imjustBuck/CPTS-Checklists) as the methodology source without copying it into this repository.

## What labhtb is

It is a **CPTS methodology copilot**.

It helps you:

- remember what has already been tested,
- keep credentials, hosts, services, access, and attack paths organized,
- mark completed/attempted methodology steps immediately,
- record commands as you go,
- maintain report notes while the lab is still active,
- decide the single highest-value next action.

It is **not** an autonomous pentest agent.

By default OpenCode does not run scans or attack commands for you.

## Quick start

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

On the first launch for a lab:

```text
TARGET IP: 10.10.11.X
DOMAIN [UNKNOWN]:
HOSTNAME [UNKNOWN]:
USERNAME [NONE]:
PASSWORD [NONE]:
```

Then OpenCode opens in **COPILOT mode**.

## Normal workflow

```text
You run a command
        ↓
Give OpenCode the command/output
        ↓
OpenCode immediately updates local state
        ↓
OpenCode gives ONE next action
        ↓
You run it
        ↓
repeat
```

Every meaningful result should be persisted before the next recommendation.

OpenCode responds with:

```text
STATE
LOGGED
NEXT
WHY
EVIDENCE
```

`NEXT` should normally contain only one action or one command.

## What gets saved

Each lab has its own local ignored workspace:

```text
labs/<lab-name>/
├── brief.md
├── notes.md
├── commands.txt
├── report-notes.md
├── evidence/
└── CPTS-Checklists -> ../../.cpts-checklists
```

### `notes.md`
Current state plus completed, attempted, blocked, and pending methodology checks.

### `commands.txt`
Important commands in chronological order.

### `report-notes.md`
Report-worthy findings are recorded while you work instead of being reconstructed at the end.

### `evidence/`
Screenshots and proof for the final report.

The entire `labs/` directory is ignored by Git.

## CPTS-Checklists updates

`setup.sh` automatically clones the methodology on first use and fast-forward updates it on later launches.

You can update it manually with:

```bash
./setup.sh
```

## If you want OpenCode to execute one thing

Use an explicit `RUN:` request inside OpenCode, for example:

```text
RUN: nxc smb 10.10.11.10 -u user -p 'pass' --shares
```

OpenCode should execute only that requested action, save the result, return to COPILOT mode, and stop after recommending one next step.

Shell execution is configured to require approval, so normal methodology guidance and file logging stay low-friction while target-facing execution remains deliberate.

## Resume a lab

```bash
./start.sh authority
```

Existing state, commands, report notes, and evidence are preserved.

## Edit target information

```bash
./start.sh authority --edit
```

This opens the local `brief.md` and then resumes the lab.

## Status

Inside OpenCode simply say:

```text
status
```

The copilot should summarize current target identity, access, credentials, findings, completed work, strongest lead, and the highest-value pending check without running anything.

## Model selection

Use the model already selected in OpenCode, or override one launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

A cheap/fast model is usually enough for state tracking, checklist coverage, and report-note maintenance. Switch to a stronger model only when attack-path reasoning becomes difficult.

## Core rule

**The operator tests. The copilot remembers, organizes, documents, and points to the next best step.**

## Scope

Use this project only against systems you own or are explicitly authorized to test, including authorized Hack The Box training environments.
