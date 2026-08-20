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

On the first run it asks only for:

- TARGET IP
- DOMAIN (or UNKNOWN)
- HOSTNAME (or UNKNOWN)
- USERNAME (or NONE)
- PASSWORD (or NONE)

Only the password input is hidden while typing. `brief.md` stays inside the ignored local lab workspace and is mode `600`.

## Runtime workspace

```text
labs/<lab-name>/
├── brief.md
├── notes.md
├── commands.txt
├── report-notes.md
├── scans/
├── evidence/
├── raw/
├── LabTools -> ../../scripts
└── CPTS-Checklists -> ../../.cpts-checklists
```

The entire `labs/` directory is ignored by Git.

## Startup automation

`start.sh`:

1. Calls `setup.sh` to clone/update `imjustBuck/CPTS-Checklists`.
2. Creates or resumes the lab workspace.
3. Seeds supplied target IP/domain/hostname into state for a new lab.
4. Creates `scans/`, `raw/`, and `evidence/`.
5. Exposes reusable helpers through `LabTools/`.
6. Requests sudo once and refreshes its timestamp while OpenCode is running.
7. If DOMAIN/HOSTNAME are already known, synchronizes them into `/etc/hosts` before OpenCode starts.
8. Starts OpenCode in fast-start/state-driven mode.

OpenCode discovers `AGENTS.md`, `opencode.json`, and `.opencode/skills/` by walking upward to the Git root.

## Fast-start sequence

For a fresh target, optimize for the shortest reliable path to useful facts.

### Phase 1 + 2 — discovery helper

Use:

```bash
bash LabTools/fast-scan.sh <TARGET_IP> scans
```

The helper performs:

```text
fast all-TCP-port discovery
        ↓
extract confirmed open ports
        ↓
targeted -sC -sV only on those ports
        ↓
preserve -oA artifacts
```

Artifacts are stored as:

```text
scans/nmap-allports.{nmap,gnmap,xml}
scans/nmap-services.{nmap,gnmap,xml}
```

The default minimum rate is `3000`. Override when needed:

```bash
LABHTB_MIN_RATE=1500 ./start.sh authority
```

Do not make `-p- -sC -sV` the default first scan.

### Phase 3 — identity and name resolution

As soon as scan/banner/SMB/LDAP/Kerberos/DNS/TLS certificate/HTTP redirect evidence confirms hostname/domain/FQDN:

1. update `notes.md`,
2. keep `brief.md` current when useful,
3. run the host helper immediately,
4. verify the helper output / `getent hosts`,
5. continue enumeration without waiting for a separate operator confirmation.

Example:

```bash
bash LabTools/sync-hosts.sh authority 10.10.11.222 dc.authority.htb dc authority.htb
```

Only confirmed names belong in the command.

The helper manages a lab-specific marker:

```text
10.10.11.222 dc.authority.htb dc authority.htb # labhtb:authority
```

Repeated runs replace that managed line instead of appending duplicate labhtb mappings.

### Phase 4 — credential validation

If credentials are supplied, determine local/domain context and validate them using normal tooling before investigating edge cases.

Preferred reasoning chain:

```text
account context
   ↓
SMB/NetExec baseline validation when SMB exists
   ↓
protocol-specific validation such as WinRM/NetExec
   ↓
only investigate JEA/custom WSMan if evidence points there
```

Separate these states clearly:

- invalid credentials,
- valid credentials but no access to this service,
- successful protocol access.

For a confirmed local account, use the appropriate local-auth mode when supported. For domain accounts, fix name resolution first and use confirmed domain context.

Do not jump from a generic Evil-WinRM error directly to JEA or hand-written SOAP requests.

## Fast service pivots

When the targeted scan confirms useful services:

- **445/SMB** → NetExec early for hostname/domain/signing/account validation/shares.
- **88 + LDAP ports** → confirm domain/DC and `/etc/hosts` before AD tooling.
- **HTTP(S) hostname redirect/certificate** → sync the name before web enumeration.
- **5985/5986 WinRM** → validate authorization first; open port alone does not mean shell access.

## Operator loop

```text
Run / receive a useful result
        ↓
STATE — update what is confirmed
        ↓
NEXT — only 1–3 logical actions
        ↓
WHY — short decision rationale
        ↓
EVIDENCE — preserve useful proof
        ↓
notes.md / commands.txt / report-notes.md
```

Completed scans and checks are tracked so they are not repeated unless new information changes their value.

## First lab

```bash
git clone https://github.com/Cyb3r1no/labhtb.git
cd labhtb
./start.sh authority
```

Example:

```text
TARGET IP: 10.10.11.222
DOMAIN [UNKNOWN]: authority.htb
HOSTNAME [UNKNOWN]: dc
USERNAME [NONE]: logger
PASSWORD [NONE] (input hidden):
```

If domain/hostname are supplied, the launcher can sync name resolution before OpenCode begins.

## Resuming a lab

```bash
./start.sh authority
```

Existing brief, notes, commands, scans, evidence, and report notes are preserved. CPTS-Checklists is updated before OpenCode launches.

## Editing lab metadata

```bash
./start.sh authority --edit
```

This opens `labs/authority/brief.md` using `$EDITOR`, or `nano` if `$EDITOR` is not set. The launcher restores mode `600` and then resumes the lab.

## Permissions

OpenCode tool permissions are auto-approved for this lab workflow. The launcher keeps OpenCode running as the normal Kali user while maintaining a sudo timestamp for commands that genuinely require local elevation.

Disable the sudo behavior for one run with:

```bash
LABHTB_SUDO=0 ./start.sh authority
```

## Cheap-model usage

Override the selected model for one launch:

```bash
LABHTB_MODEL='provider/model' ./start.sh authority
```

Use `opencode models` to see exact provider/model identifiers.

Recommended strategy:

```text
Routine state/checklist/report work → fast inexpensive model
Hard attack-path reasoning          → stronger model temporarily
```

## Evidence discipline

When a result matters for the final report:

1. preserve raw output when useful,
2. capture a clear screenshot when visual proof helps,
3. put report evidence under `evidence/`,
4. keep noisy outputs under `raw/`,
5. reference evidence from `report-notes.md`,
6. never claim evidence exists unless it was actually captured.

## Updating methodology only

```bash
./setup.sh
```

This updates `.cpts-checklists/` without starting a lab.
