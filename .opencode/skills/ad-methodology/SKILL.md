---
name: ad-methodology
description: Guide authorized CPTS Active Directory labs using the current lab state and local CPTS-Checklists. Use for AD enumeration coverage, attack-path reasoning, next-step decisions, or when the operator is stuck.
---

# AD Methodology

Use `notes.md` as current state and `CPTS-Checklists/Windows & AD/` plus other relevant checklist sections as the primary methodology.

## Process

1. Read `notes.md` first.
2. Read only checklist files relevant to the current phase.
3. Identify what is confirmed, completed, attempted and still pending.
4. Recommend only the next 1–3 logical actions.
5. Explain briefly why each action matters now.
6. Prefer enumeration and state-building before exploitation.
7. Do not repeat completed checks unless new information changes their value.
8. Update `notes.md` after meaningful results.

## Fast-start rules

For a fresh target, prioritize useful facts in this order:

1. Fast all-port discovery.
2. Targeted `-sC -sV` only against confirmed open ports.
3. Hostname/domain/DC identity.
4. `/etc/hosts` update as soon as names are confirmed.
5. Credential validation and local-vs-domain account classification.
6. Protocol-specific enumeration based on exposed services.

Avoid `nmap -p- -sC -sV` as the default first scan. Prefer fast discovery such as:

`nmap -Pn -n -p- --min-rate 3000 -T4 <TARGET> -oA scans/nmap-allports`

Then target only open ports:

`nmap -Pn -n -sC -sV -p<OPEN_PORTS> -T4 <TARGET> -oA scans/nmap-services`

## Name resolution

When hostname/domain/FQDN is confirmed by evidence:

- update `notes.md`,
- keep `brief.md` current when useful,
- update `/etc/hosts` immediately and idempotently,
- avoid duplicates/conflicts,
- verify with `getent hosts`,
- continue enumeration without waiting for operator confirmation.

Never guess names.

## Credential and WinRM validation

If supplied credentials or WinRM behave unexpectedly:

1. Determine local vs domain context from evidence.
2. Validate credentials with a baseline protocol such as SMB/NetExec when available.
3. Validate WinRM authorization separately with NetExec before debugging Evil-WinRM.
4. Separate `invalid credentials` from `valid credentials but no WinRM access`.
5. Investigate JEA/custom WSMan only when standard tooling or server responses provide evidence.
6. Avoid hand-written SOAP/raw protocol requests unless standard tooling cannot answer the question.

## Reassessment triggers

When new credentials, hashes, tickets, privileges, hosts, trusts or sessions are discovered, reassess only relevant paths such as:

- Authentication/access validation
- SMB / LDAP / Kerberos / WinRM / MSSQL where present
- Shares and accessible files
- Users / groups / computers
- BloodHound collection and attack paths
- ACL relationships
- Delegation
- ADCS
- Credential reuse
- Lateral movement opportunities

Tool choice follows the methodology. Prefer NetExec, BloodHound, Certipy, Impacket and native utilities when appropriate.

Keep responses concise and use:

STATE
NEXT
WHY
EVIDENCE
