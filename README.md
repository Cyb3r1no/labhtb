# labhtb

A simple CPTS methodology copilot for authorized Hack The Box labs.

The whole workflow is:

```text
./start.sh
   ↓
Recon + basic enumeration once
   ↓
OpenCode reads the results
   ↓
OpenCode saves state immediately
   ↓
One best next step
   ↓
You execute it
   ↓
repeat
```

## Start

First clone:

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh
```

After that, every lab starts the same way:

```bash
./start.sh
```

It asks only for:

```text
Lab name:
Target IP:
Username [NONE]:
Password [NONE]:   # only if a username was supplied
```

That is the normal interface. No flags are required.

## What happens automatically

For a new lab, labhtb:

1. Updates the latest `imjustBuck/CPTS-Checklists` copy.
2. Creates a private local workspace for the lab.
3. Runs one bounded baseline:
   - fast TCP all-port discovery,
   - targeted `-sC -sV` on confirmed ports,
   - SMB identity + anonymous-share baseline when SMB is exposed,
   - LDAP RootDSE when LDAP is exposed,
   - validates the single supplied credential pair on relevant SMB/LDAP/WinRM services when available.
4. Saves raw outputs and commands.
5. Opens OpenCode.
6. Stops autonomous testing.

The baseline does not spray passwords, exploit targets, escalate privileges, move laterally, or chain attacks.

## What OpenCode does

OpenCode is the copilot, not the driver.

After every meaningful result it should:

1. update `notes.md`,
2. maintain the current `PHASE`,
3. record the command,
4. mark methodology progress,
5. update credentials/access/findings,
6. update report notes/evidence when relevant,
7. give exactly one highest-value next action,
8. wait for you.

Normal response:

```text
PHASE
STATE
LOGGED
NEXT
WHY
EVIDENCE
```

## Two useful commands

Inside OpenCode:

```text
/status
```

Shows where you are, what is done, current access/credentials, strongest lead, and one next check.

When you feel lost:

```text
/stuck
```

It reviews the current phase, unfinished methodology, the compact CPTS decision map, and your personal notes if available, then gives one meaningful missed branch.

## Your CPTS study notes

The repository contains `knowledge/cpts-map.md`, a compact phase/trigger map distilled from the operator's CPTS study notes.

If you want OpenCode to also search your full personal notes for familiar commands and examples, put them once at:

```text
labhtb/cpts-notes.md
```

That file is ignored by Git and stays local. `start.sh` exposes it to every lab automatically as `CPTS-NOTES.md`.

This is optional; the project works without it.

## Lab files

Each lab stays local under:

```text
labs/<lab-name>/
├── brief.md
├── recon-summary.md
├── notes.md
├── commands.txt
├── report-notes.md
├── scans/
├── raw/
├── evidence/
├── CPTS-Checklists -> ../../.cpts-checklists
├── CPTS-MAP.md -> ../../knowledge/cpts-map.md
└── CPTS-NOTES.md -> ../../cpts-notes.md   # only if present
```

`labs/`, `.cpts-checklists/`, and `cpts-notes.md` are ignored by Git.

## PHASE model

The copilot always knows which part of the engagement you are in:

```text
RECON
SERVICE_ENUM
INITIAL_ACCESS
AD_ENUM
AD_ATTACK_PATH
WINDOWS_PRIVESC
LINUX_PRIVESC
PIVOTING
PROOF_REPORT
```

This is the main idea of the rebuild: you should not have to remember a 5,000-line notebook while solving a lab. The project should retrieve the relevant methodology only when the current phase needs it.

## If you want OpenCode to run one command

Explicitly write:

```text
RUN: <command>
```

It should execute only that action, save the result, return to Copilot mode, give one next action, and wait.

OpenCode shell actions require approval by project configuration, while reading/updating the lab state is allowed without interruption.

## Resume

Run:

```bash
./start.sh
```

and enter the same lab name. Existing recon, state, commands, evidence, and report notes are reused.

## Scope

Use only against systems you own or are explicitly authorized to test, including authorized Hack The Box training environments.
