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
