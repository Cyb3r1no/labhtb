---
name: reporting
description: Maintain concise CPTS-style report notes for authorized labs. Use after meaningful findings, attack-path validation, privilege escalation, lateral movement, or when reviewing report readiness.
---

# CPTS Reporting

Maintain `report-notes.md` continuously instead of waiting until the end of the lab.

For each meaningful finding record:

- Finding title
- Affected host/object
- Discovery method
- Relevant command(s)
- Evidence/artifact reference
- Validation or exploitation steps
- Impact
- Remediation
- Missing screenshots or proof

## Rules

- Never invent evidence, commands, outputs or screenshots.
- Clearly mark missing information.
- Preserve enough context to reconstruct the attack path later.
- Keep chronology in `notes.md` / `commands.txt`; keep `report-notes.md` focused on report-worthy material.
- When a finding changes access or privilege, capture before/after state.
- Prefer precise technical notes over polished prose during the lab; polish only when preparing the final report.
