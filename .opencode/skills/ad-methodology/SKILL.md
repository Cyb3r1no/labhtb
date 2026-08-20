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

1. Fast all-port discovery using `bash LabTools/fast-scan.sh <TARGET_IP> scans`.
2. Targeted service/default-script enumeration from the helper output.
3. Hostname/domain/DC identity.
4. `/etc/hosts` update as soon as names are confirmed.
5. Credential validation and local-vs-domain account classification.
6. Protocol-specific enumeration based on exposed services.

Do not default to `nmap -p- -sC -sV`.

## Fast service pivots

- SMB/445 → NetExec early for hostname/domain/signing, credential context, shares and access.
- Kerberos/88 + LDAP/389/636/3268/3269 → confirm domain/DC identity and name resolution before AD tooling.
- HTTP(S) redirect/certificate hostname → sync the confirmed name immediately, then enumerate the name-based target.
- WinRM/5985/5986 → validate authorization with NetExec before Evil-WinRM troubleshooting.
- Supplied credentials → determine local/domain context once, validate deliberately, then reuse only where relevant.

## Name resolution

When hostname/domain/FQDN is confirmed by evidence:

1. Update `notes.md` and `brief.md` when useful.
2. Run:
   `bash LabTools/sync-hosts.sh <LAB_NAME> <TARGET_IP> <CONFIRMED_NAME> [MORE_CONFIRMED_NAMES...]`
3. Include only confirmed aliases.
4. Verify the helper output / `getent hosts` result.
5. Continue enumeration immediately.

Never guess names.

## Credential and WinRM validation

If supplied credentials or WinRM behave unexpectedly:

1. Determine local vs domain context from evidence.
2. Validate credentials with SMB/NetExec when SMB is available.
3. Use local-auth mode for confirmed local accounts when appropriate.
4. Use confirmed domain/name-resolution context for domain accounts.
5. Validate WinRM authorization separately with NetExec before debugging Evil-WinRM.
6. Separate `invalid credentials` from `valid credentials but no WinRM access`.
7. Investigate JEA/custom WSMan only when standard tooling or server responses provide evidence.
8. Avoid hand-written SOAP/raw protocol requests unless standard tooling cannot answer the question.

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
