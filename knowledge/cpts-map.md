# CPTS Decision Map

This is a compact decision index distilled from the operator's CPTS study notes.

It is not a checklist to execute blindly. Use it to decide which branch of the operator's knowledge is relevant now.

## Phase map

### RECON
Goal: identify reachable services, names, and basic target identity.

Typical questions:
- What TCP services are exposed?
- Do banners, TLS certificates, SMB, LDAP, DNS, or redirects reveal a hostname/domain?
- Is this likely Windows, Linux, AD, web-heavy, or a mixed target?

Move on when useful services and identity clues exist.

### SERVICE_ENUM
Goal: turn open ports into useful facts.

Service triggers:

- `21` FTP -> anonymous/login, files, writable locations, version-specific behavior.
- `22` SSH -> version, credentials/keys when evidence exists.
- `25/110/143/465/587/993/995` mail -> SMTP/POP3/IMAP users, auth, relay/misconfiguration branches.
- `53` DNS -> names, records, zone transfer when relevant.
- `80/443/8080/...` web -> hostname/vhost, directories, parameters, technology/CMS/framework-specific enumeration.
- `88` Kerberos + `389/636/3268/3269` LDAP -> Active Directory identity and authenticated AD enumeration when credentials exist.
- `139/445` SMB -> hostname/domain/signing, anonymous/credentialed shares, users/groups where justified, interesting files/SYSVOL.
- `1433` MSSQL -> login context, database permissions, impersonation, xp_cmdshell, linked servers only when evidence supports those branches.
- `3306` MySQL -> databases/tables/files/permissions only when access exists.
- `3389` RDP -> credential validation and access; do not assume open port means usable login.
- `5985/5986` WinRM -> credential/authorization validation before opening an interactive shell.

Do not enumerate every protocol with every tool. Pick the service with the best current lead.

### INITIAL_ACCESS
Goal: convert a validated weakness or credential into a stable foothold.

Record:
- exact identity,
- host,
- protocol,
- privilege level,
- proof,
- credential or exploit source.

Once a shell/session exists, immediately choose Windows or Linux PrivEsc unless the foothold itself exposes a stronger network/AD path.

### WINDOWS_PRIVESC
First questions:
- Who am I, what groups am I in, and what token privileges exist?
- Local Administrators membership?
- Network interfaces/routes/DNS/other reachable subnets?
- Services, scheduled tasks, writable binaries/paths, installed software?
- Stored credentials: Credential Manager, configs, scripts, browser data, DPAPI, shares?
- SAM/LSA/LSASS access only when privilege/evidence makes it relevant.
- Domain context, sessions, local admins, and useful reusable credentials?

A new domain credential or new network path may move the phase to `AD_ENUM` or `PIVOTING`.

### LINUX_PRIVESC
First questions:
- `sudo -l`
- SUID/SGID and capabilities
- cron/systemd jobs
- writable scripts, services, paths, binaries
- configs/database files/secrets/tokens
- shell history and SSH keys
- running processes/services
- mounts, containers, NFS, unusual devices
- interfaces/routes/new subnets
- if domain joined: realm/SSSD/winbind, keytabs, Kerberos ccache

A new internal subnet moves the phase to `PIVOTING`. A domain ticket/keytab/credential may move to `AD_ENUM`.

### AD_ENUM
Think in layers.

1. Identity
   - domain
   - DC hostname/FQDN/IP
   - name resolution

2. Access
   - local vs domain credential context
   - protocol authorization: SMB, LDAP, WinRM, MSSQL when exposed

3. Directory
   - users
   - groups
   - computers
   - shares
   - SYSVOL/scripts
   - user descriptions / interesting attributes
   - GPOs when relevant

4. Kerberos
   - SPNs / Kerberoast candidates
   - accounts without pre-auth / AS-REP candidates
   - tickets/ccache/keytabs when already present

5. Graph
   - BloodHound collection
   - local admin relationships
   - group membership paths
   - ACL edges

6. Infrastructure
   - delegation
   - ADCS
   - DNS
   - trusts / child-parent / cross-forest relationships

Do not run all six layers mechanically. Use current evidence and unfinished methodology coverage.

### AD_ATTACK_PATH
Enter this phase only when a concrete relationship or weakness exists.

Examples of evidence that can justify this phase:
- BloodHound path
- dangerous ACL
- delegation relationship
- vulnerable/misconfigured ADCS template or certificate path
- reusable hash/ticket/certificate
- privileged group relationship
- trust relationship with a viable escalation path
- credential found in SYSVOL/share/description

Once a path is chosen, track each prerequisite and proof step. If it fails, return to the relevant enumeration layer instead of trying random attacks.

### PIVOTING
Trigger when evidence shows another reachable network or internal-only service.

Typical clues:
- second NIC
- new route
- ARP neighbors
- internal DNS
- inaccessible internal host from attack box but reachable from foothold

Common approaches from the operator's study notes include:
- SSH local/dynamic forwarding
- SOCKS + proxychains
- Ligolo-ng
- Chisel
- Windows `netsh portproxy` for specific cases

After the tunnel exists, treat the newly reachable segment as a new recon/service-enumeration scope while preserving the original attack path.

### PROOF_REPORT
Use when objectives are reached or before leaving an important path.

Check:
- Can the attack path be reconstructed?
- Are commands recorded?
- Are credentials/source transitions clear?
- Is before/after privilege proof present?
- Are screenshots/raw outputs referenced?
- Does every finding have impact/remediation notes where needed?

## Major event triggers

### New credential / hash / ticket / certificate
Immediately:
1. record identity, type, scope, source,
2. mark where it has been validated,
3. reconsider only relevant services/hosts,
4. check whether it unlocks AD enumeration, lateral access, or PrivEsc.

### New hostname/domain/FQDN
Immediately:
1. record it,
2. fix name resolution when required,
3. revisit name-based services such as Kerberos, LDAP, SMB, WinRM, and web virtual hosts.

### New shell/session
Immediately:
1. record host/user/privilege/protocol,
2. capture proof,
3. switch to the correct foothold/PrivEsc phase,
4. inspect routes before assuming this is only a local escalation problem.

### New subnet/route
Switch to `PIVOTING` and preserve the route/tunnel details in the step log.

## When stuck

Do not ask "what tool next?" Ask:

1. What PHASE am I in?
2. What services/paths are still unresolved?
3. What changed most recently?
4. Did a new credential/session/route/name create a trigger?
5. Which relevant CPTS checklist branch is still not DONE/ATTEMPTED/BLOCKED?
6. Does the personal `CPTS-NOTES.md` contain a familiar command for that branch?

Then choose one action only.
