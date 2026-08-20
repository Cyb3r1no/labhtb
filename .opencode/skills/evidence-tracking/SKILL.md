---
name: evidence-tracking
description: Track screenshots, command outputs and artifacts needed for an authorized CPTS lab report. Use when a result proves access, a vulnerability, an attack path, a privilege change, credential exposure, or other report-worthy behavior.
---

# Evidence Tracking

For meaningful actions and findings:

1. Decide whether proof should be preserved.
2. Recommend a clear filename under `evidence/`.
3. Prefer raw tool output plus a screenshot for important findings when practical.
4. Reference saved evidence from `notes.md` or `report-notes.md`.
5. Never claim evidence exists unless it actually exists.

Use sequential, descriptive names when practical:

- `001-nmap-initial.txt`
- `002-smb-enum.txt`
- `003-bloodhound-path.png`
- `004-certipy-find.txt`

Evidence should make it possible to reconstruct and support the report without relying on memory.
