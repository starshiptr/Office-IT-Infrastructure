# From Local Accounts to Zero Trust — AD + RDS Rebuild

Rebuild of a production multi-user RDS environment (Windows Server 2022,
GPU CAD workloads) from per-machine local accounts to centralized identity
and Zero Trust remote access.

> Sanitized: domain names, OU paths, hostnames, and group names in this
> chapter are placeholders. Architecture, procedures, and gotchas are real.

## Before

- Every user = a local account created by hand on the RDS host; no central
  identity, no groups, no policy
- Remote access via a single shared VPN credential
- Offboarding = remembering to delete accounts on that one box

## After

- Active Directory domain; RDS host domain-joined
- **AGDLP permission model** — accounts → role groups (`G-Engineers`) →
  resource groups (`DL-<share>-RW`) → NTFS ACLs. Access follows group
  membership; ACLs are touched exactly once
- **GPO baseline** on the session host: shutdown rights restricted to
  Administrators, disconnected sessions end after 8 h, idle sessions
  disconnect after 3 h
- **Cloudflare Zero Trust** for remote access: outbound-only `cloudflared`
  tunnel (zero inbound ports), WARP client on user devices, per-user
  SSO + MFA against Entra ID. Raw RDP (3389) is never exposed
- **Onboarding = one command** ([`New-AstroUser.ps1`](New-AstroUser.ps1)):
  account + role groups + a self-check line. Offboarding = disable one
  account and access dies everywhere at once

## Migration approach — parallel run, no big bang

Users were migrated one at a time, off-hours, with rollback at every step:

1. Domain account created alongside the existing local one
2. In-place profile conversion (ForensiT User Profile Wizard) — the local
   profile is re-owned to the domain SID where it sits, preserving the
   desktop and CAD (SolidWorks) settings
3. User cuts over to domain login; the local account stays enabled as the
   rollback path
4. Local account is disabled after ≥1 week of clean domain logins, deleted
   after a further soak

Full procedures in [`runbooks.md`](runbooks.md) (migrate · retire ·
onboard · offboard).

## Gotchas worth knowing

- A password that fails complexity at `New-ADUser` time lands the account
  **created but disabled** — silently. Always verify `Enabled = True`
- `pwdLastSet = 0` (the "must change password at next logon" flag) breaks
  NLA RDP with *"The Local Security Authority cannot be contacted."* A new
  hire's first logon **is** an NLA RDP session — so the onboarding script
  deliberately skips the flag and users change their password in-session
  (`Ctrl+Alt+End` → Change a password)
- After a ForensiT migration, **never delete `C:\Users\<profile>`** when
  retiring the local account — the folder was re-owned in place and *is*
  the live domain profile. Remove the account object only
- Zero Trust ≠ new inbound surface: the tunnel is outbound-only; the
  firewall stays closed

## Deliberately descoped

- **FSLogix profile containers** — single session host, local profiles
  proven. Complexity with no payoff until a second host exists
- **Domain password-policy hardening** — small team, RDP reachable only
  through Zero Trust SSO + MFA; the gate is at identity, not the password

## Files

- [`New-AstroUser.ps1`](New-AstroUser.ps1) — onboarding automation
  (sanitized reference version)
- [`runbooks.md`](runbooks.md) — migrate / retire / onboard / offboard
