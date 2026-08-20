# labhtb

A simple CPTS copilot for authorized Hack The Box labs.

## Use it

First time only:

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
```

Every lab/session after that:

```bash
./start.sh
```

That is the normal workflow.

`start.sh` asks for the lab name. For a new lab it asks only for:

```text
Target IP
Username (optional)
Password (optional)
```

Domain and hostname start as `UNKNOWN` and are discovered during the lab.

## What happens automatically

For a new lab only:

1. Update the local CPTS-Checklists copy.
2. Run one bounded baseline recon:
   - fast TCP port discovery,
   - targeted service/version scan,
   - SMB baseline when available,
   - LDAP RootDSE baseline when available.
3. Save recon output locally.
4. Open OpenCode.
5. OpenCode records the recon results and gives one best next action.

Recon does not repeat automatically when you resume the same lab.

## After recon

OpenCode becomes the copilot:

```text
You execute a step
      ↓
Give OpenCode the result
      ↓
It records the result immediately
      ↓
It gives ONE next action
      ↓
Waits for you
```

Response format:

```text
STATE
LOGGED
NEXT
WHY
EVIDENCE
```

If you explicitly want OpenCode to execute one command, use:

```text
RUN: <command>
```

It should run only that command, record the result, then return to copilot mode.

## Saved per lab

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
└── CPTS-Checklists
```

`labs/` is ignored by Git.

## The rule

**Baseline recon is automatic. You do the lab. The copilot remembers everything and tells you the next best step.**

Use only on systems you own or are explicitly authorized to test.
