# Architecture

## Design goal

`labhtb` is intentionally small. It is not a new attack framework and it does not replace the tools taught in CPTS.

Its job is to provide a thin workflow layer around OpenCode so the operator reaches useful facts quickly without losing methodology, state, evidence, or reporting.

The core loop is:

```text
Fast discovery
    ↓
Identity / names
    ↓
Access validation
    ↓
Current State
    ↓
Next 1–3 Actions
    ↓
Evidence / Report Notes
    └──────────────→ back into Current State
```

## Static project layer

Committed and reused by every lab:

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

Persistent project instructions. It defines:

- fast two-stage discovery,
- hostname/domain resolution discipline,
- systematic credential validation,
- methodology before random attacks,
- concise state-driven guidance,
- continuous evidence/report tracking,
- no unsupported hypotheses,
- no autonomous exploitation without an explicit operator request.

### opencode.json

Project-local OpenCode configuration. Permissions are auto-approved for the isolated authorized lab workflow.

### Skills

Specialized instructions are loaded only when relevant:

```text
ad-methodology     → fast AD methodology and next-step decisions
reporting          → CPTS-style report notes
evidence-tracking  → evidence naming and proof tracking
```

This keeps routine context small enough for inexpensive models.

## External methodology layer

`CPTS-Checklists` remains upstream instead of being copied into this repository.

```text
imjustBuck/CPTS-Checklists
          ↓
       setup.sh
          ↓
.cpts-checklists/
```

First use performs a shallow clone. Later launches perform a fast-forward-only update.

## Runtime lab layer

Each target receives an isolated local workspace:

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

The whole `labs/` directory is ignored by Git.

### brief.md

Small bootstrap file containing target identity and optional username/password. It is local-only and mode `600`.

It can be edited with:

```bash
./start.sh <lab-name> --edit
```

### notes.md

Compact operational source of truth. It tracks:

- target identity,
- fast-start progress,
- hostname/domain/DC context,
- `/etc/hosts` state,
- account context,
- services and hosts,
- credentials/tickets/hashes,
- foothold,
- important AD observations,
- attack-path hypotheses,
- completed/pending methodology coverage.

### scans/

Structured discovery output. Initial Nmap work is intentionally two-stage:

```text
scans/nmap-allports.*   → fast all-port discovery
scans/nmap-services.*   → targeted -sC/-sV against confirmed open ports
```

### commands.txt

Chronological command log so the report does not depend on shell history or memory.

### report-notes.md

Only report-worthy material. Findings are captured during the lab instead of reconstructed at the end.

### evidence/

Screenshots, raw proof, and artifacts intended to support report claims.

### raw/

Noisy or unprocessed tool output that may become useful later.

## Name-resolution layer

Correct name resolution is treated as part of target initialization, not optional cleanup.

If DOMAIN/HOSTNAME are supplied at startup, `start.sh` creates a managed `/etc/hosts` entry after sudo authorization.

Example:

```text
10.10.11.X dc.authority.htb dc authority.htb # labhtb:authority
```

Only the entry carrying that lab marker is replaced on future launches, avoiding duplicate mappings.

When names are initially unknown, AGENTS.md requires the copilot to synchronize confirmed hostname/domain/FQDN immediately after discovery and verify with `getent hosts`.

## Privilege model

OpenCode itself runs as the normal Kali user.

`start.sh` validates sudo once and refreshes the sudo timestamp while OpenCode is active. This gives individual commands access to local elevation without turning the entire agent process into root and without changing project ownership.

## Startup flow

```text
./start.sh <lab-name>
        ↓
update CPTS-Checklists
        ↓
create/resume workspace
        ↓
seed operator-provided state
        ↓
create scans/raw/evidence directories
        ↓
authorize sudo
        ↓
sync known names into /etc/hosts
        ↓
start OpenCode in FAST-START mode
        ↓
read brief.md + notes.md
        ↓
fast all-port discovery if needed
        ↓
targeted service scan
        ↓
identity / credential validation
        ↓
protocol-specific methodology
```

## Decision-speed strategy

The project is optimized to avoid expensive dead ends:

1. Never default to `-p- -sC -sV` in one initial Nmap pass.
2. Establish names early because AD/Kerberos/LDAP/WinRM tooling depends on them.
3. Validate supplied credentials with normal tooling before debugging exotic protocol behavior.
4. Distinguish invalid credentials from valid credentials that lack a specific service permission.
5. Do not infer JEA/custom WSMan from a generic WinRM failure.
6. Do not hand-build protocol requests when standard tools can answer the question faster.
7. Do not repeat completed scans/checks unless new information changes their value.
8. Keep next actions limited to 1–3 items.

## Context and token strategy

1. `notes.md` carries compact state instead of replaying the conversation.
2. The full CPTS checklist repository is not read every turn.
3. Only phase-relevant checklist files are opened.
4. Skills are loaded on demand.
5. Responses stay short and action-focused.
6. Large outputs live in `scans/` or `raw/` instead of being repeatedly pasted into context.

## Trust boundaries

Committed files contain reusable workflow/methodology only.

Ignored runtime paths contain target-specific or potentially sensitive data:

```text
.cpts-checklists/
labs/
.env
loot/
output/
credential/ticket/key file patterns
```

Real lab artifacts should never be committed to the public repository.

## Why no full autonomous agent

The operator is practicing CPTS decision-making. Full autonomous exploitation would remove that practice.

```text
Operator owns:
- authorization
- execution decisions
- exploitation approval
- interpretation review

Copilot owns:
- fast state building
- methodology coverage
- name-resolution hygiene
- next-step suggestions
- evidence reminders
- report-note maintenance
```

## Future extensions

Add only features proven useful during real labs, such as:

- `/status` compact state summary,
- `/report-review`,
- specialized BloodHound analysis,
- optional web/pivot methodology skills,
- structured machine-readable state if Markdown becomes insufficient.

Avoid orchestration, databases, MCP servers, or dozens of skills until real usage proves they save time.
