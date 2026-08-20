# labhtb

A simple OpenCode copilot for authorized Hack The Box / CPTS practice labs.

The workflow is now intentionally split into two parts:

**AUTO RECON → COPILOT**

The goal is to save time on the boring beginning of a lab without letting OpenCode turn into an autonomous pentest agent.

`labhtb` uses the latest upstream [`imjustBuck/CPTS-Checklists`](https://github.com/imjustBuck/CPTS-Checklists) as the methodology source without copying it into this repository.

## What happens automatically

On the first launch of a lab, `start.sh` runs one bounded recon/enumeration pass before OpenCode starts.

It performs:

1. Fast TCP all-port discovery.
2. Targeted `-sC -sV` only against confirmed open ports.
3. NetExec SMB identity + anonymous-share baseline when 445 is open and `nxc` is installed.
4. LDAP RootDSE baseline when 389/636 is open.
5. Saves the results locally.
6. Stops.

It does **not** automatically perform authenticated enumeration, spraying, exploitation, privilege escalation, lateral movement, or tool chaining.

## Quick start

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

On the first launch:

```text
TARGET IP: 10.10.11.X
DOMAIN [UNKNOWN]:
HOSTNAME [UNKNOWN]:
USERNAME [NONE]:
PASSWORD [NONE]:
```

Then the flow is:

```text
start.sh
   ↓
AUTO RECON
   ↓
recon-summary.md + scans/ + raw/
   ↓
OpenCode reads and logs the results
   ↓
COPILOT gives ONE highest-value next action
   ↓
you execute it
   ↓
OpenCode logs the result immediately
   ↓
next action
```

## What AUTO RECON saves

Each lab has a private local workspace:

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
└── CPTS-Checklists -> ../../.cpts-checklists
```

Typical recon artifacts:

```text
scans/nmap-allports.nmap
scans/nmap-services.nmap
raw/nxc-smb-baseline.txt
raw/ldap-rootdse.txt
```

Only files relevant to the exposed services are created.

The entire `labs/` directory is ignored by Git.

## COPILOT mode

After baseline recon finishes, OpenCode becomes the methodology assistant.

For every meaningful result it should first update:

- `notes.md`
- `commands.txt`
- `report-notes.md` when relevant
- methodology progress (`DONE`, `ATTEMPTED`, `BLOCKED`, `PENDING`)

Only after saving the state should it give the next step.

Normal response format:

```text
STATE
LOGGED
NEXT
WHY
EVIDENCE
```

`NEXT` should normally contain **one action only**.

## Re-run recon

Recon runs once per lab by default.

To deliberately run the bounded baseline again:

```bash
./start.sh authority --recon
```

To skip automatic recon for one launch:

```bash
LABHTB_RECON=0 ./start.sh authority
```

## If you want OpenCode to execute one command

Use `RUN:` inside OpenCode:

```text
RUN: nxc smb 10.10.11.10 -u user -p 'pass' --shares
```

It should execute only that action, save the result, return to Copilot mode, and stop after recommending one next step.

Shell execution remains approval-gated so the model cannot silently start another enumeration chain.

## Resume a lab

```bash
./start.sh authority
```

If recon already completed, it is skipped and OpenCode resumes from existing state.

## Edit target information

```bash
./start.sh authority --edit
```

This opens the local `brief.md` and then resumes the lab.

## CPTS methodology

`CPTS-Checklists` is used as a **decision guide**, not a list of commands to execute blindly.

The copilot should answer:

- What have we already checked?
- What did we learn?
- What is still relevant?
- What is the single best next check?

When new credentials, hosts, privileges, trusts, or sessions appear, it should reassess only the relevant paths instead of restarting enumeration from zero.

## Status

Inside OpenCode:

```text
status
```

The copilot should summarize target identity, access, valid credentials, important findings, completed checks, current best lead, and the highest-value pending step without running anything.

## Model selection

Use the model already selected in OpenCode, or override one launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

A cheap/fast model is usually enough for state tracking, checklist coverage, and report notes. Switch to a stronger model only for difficult attack-path reasoning.

## Core rule

**Automation handles the repetitive baseline. You handle the engagement. The copilot remembers, documents, and guides.**

## Scope

Use this project only against systems you own or are explicitly authorized to test, including authorized Hack The Box training environments.
