# Runbooks — Migrate · Retire · Onboard · Offboard

Sanitized versions of the production runbooks. `CORP` / `corp.example.com`
stand in for the real domain; `RDSHOST` for the session host; `DC01` for the
domain controller. Procedures and gotchas are real — both Runbook A gotchas
were hit live before being codified here.

---

## Runbook A — migrate one user (local → domain)

**On DC01 (pre-flight):**

```powershell
# 1. Create the account (right OU, no must-change-at-logon)
New-ADUser -Name "first.last" -SamAccountName "first.last" `
  -Path "OU=Users,OU=Company,DC=corp,DC=example,DC=com" `
  -AccountPassword (Read-Host -AsSecureString "Password") `
  -Enabled $true -ChangePasswordAtLogon $false

# 2. Role group -> RDS access follows membership
Add-ADGroupMember G-RDSUsers "first.last"

# 3. Verify BOTH known gotchas before touching the profile
Get-ADUser first.last -Properties Enabled,pwdLastSet |
  Select-Object Name,Enabled,pwdLastSet
```

Gotchas (both hit in production):

- **Sub-complexity password at creation → the account lands disabled.**
  Confirm `Enabled = True`.
- **`pwdLastSet = 0` (must-change flag) breaks NLA RDP** with "The Local
  Security Authority cannot be contacted." Fix:
  `Set-ADUser first.last -ChangePasswordAtLogon $false`.

**On RDSHOST (off-hours):**

1. `quser` — confirm the user has no active session; log them off if they do.
2. **Backup gate:** confirm a recent `wbadmin` image exists before touching
   any profile.
3. ForensiT User Profile Wizard → select the local profile → assign to
   `CORP\first.last` → migrate **in place** (desktop + CAD settings
   preserved).
4. Verify: RDP in as the domain account → desktop and application settings
   intact.
5. **Leave the local account enabled** — it is the parallel-run rollback
   until Runbook B.

---

## Runbook B — retire a local account (after soak)

Run per account only after **≥1 week of clean domain logins** for that user.

```powershell
# On RDSHOST — confirm the local account is genuinely idle
Get-LocalUser userN | Select-Object Name,Enabled,LastLogon

Disable-LocalUser userN     # step 1: disable, soak another week
Remove-LocalUser userN      # step 2: delete after the soak
```

**Never delete `C:\Users\<profile>`** — ForensiT re-owned that folder to the
domain SID in place; it IS the user's live profile now. Remove the account
object only.

---

## Runbook C — onboard a new hire

One script + three checkboxes. See [`New-AstroUser.ps1`](New-AstroUser.ps1).

```powershell
.\New-AstroUser.ps1 -Name <firstname> -Role Engineer `
    -TempPassword (Read-Host -AsSecureString "Temp pwd")
# Role: Engineer (adds G-Engineers -> DL-*-RW resource groups)
#       Office   (G-RDSUsers only)
```

Then:

1. **M365 account** — create in the admin center + assign a license (AD is
   not Entra-synced here; two separate identities). The M365 account is what
   WARP / Cloudflare Access authenticates.
2. **WARP enrollment** — install the WARP client, join the Zero Trust team,
   sign in with their own M365 account. macOS: allow Local Network access
   for the RDP client.
3. **First login** — RDP to the session host as `CORP\<name>` with the temp
   password, then change it INSIDE the session: **Ctrl+Alt+End → Change a
   password** (see the NLA gotcha above for why not at-logon).

---

## Runbook D — offboard a leaver

```powershell
# On DC01 — step 1 kills all domain access at once (RDS, shares, everything)
Disable-ADAccount <name>

# Note their groups, then strip memberships:
Get-ADUser <name> -Properties MemberOf | Select -Expand MemberOf
Get-ADUser <name> -Properties MemberOf |
  ForEach-Object { $_.MemberOf } |
  ForEach-Object { Remove-ADGroupMember $_ -Members <name> -Confirm:$false }
```

1. **Disable the AD account** (above) — first, the moment offboarding is
   decided.
2. **M365** — block sign-in in the admin center (this also kills WARP
   re-auth, since the Zero Trust IdP is Entra), transfer OneDrive/mailbox,
   then remove the license.
3. **Data** — transfer anything needed from the profile. **Never delete
   `C:\Users\<profile>`** (Runbook B rule — it may be a ForensiT re-owned
   folder).
4. **Soak ≥30 days**, then delete the account object:
   `Remove-ADUser <name> -Confirm:$false`. The profile folder stays.
