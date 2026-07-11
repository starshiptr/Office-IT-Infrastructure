<#
.SYNOPSIS
    One-command user onboarding: creates the AD account and assigns role
    groups. Run on the domain controller.

.DESCRIPTION
    Sanitized reference version of the production script — the domain, OU
    path, and group names are placeholders; the logic is unchanged.

    AGDLP means onboarding never touches an ACL: the role group is the only
    thing this script assigns. Resource permissions (DL-* groups -> NTFS)
    were configured once and never per-user.

.EXAMPLE
    .\New-AstroUser.ps1 -Name jane.doe -Role Engineer `
        -TempPassword (Read-Host -AsSecureString "Temp pwd")
#>
param(
    [Parameter(Mandatory)] [string]$Name,
    [Parameter(Mandatory)] [ValidateSet('Engineer', 'Office')] [string]$Role,
    [Parameter(Mandatory)] [SecureString]$TempPassword
)

$UserOU = 'OU=Users,OU=Company,DC=corp,DC=example,DC=com'

# Deliberate: -ChangePasswordAtLogon $false. The must-change flag
# (pwdLastSet = 0) breaks NLA RDP with "The Local Security Authority cannot
# be contacted" — and a new hire's first logon IS an NLA RDP session. Users
# change the temp password inside the session instead (Ctrl+Alt+End).
New-ADUser -Name $Name -SamAccountName $Name `
    -Path $UserOU `
    -AccountPassword $TempPassword `
    -Enabled $true -ChangePasswordAtLogon $false

# Role groups. G-RDSUsers gates RDS access; G-Engineers nests into the
# DL-<share>-RW resource groups (AGDLP), lighting up every engineering share.
Add-ADGroupMember -Identity 'G-RDSUsers' -Members $Name
if ($Role -eq 'Engineer') {
    Add-ADGroupMember -Identity 'G-Engineers' -Members $Name
}

# Self-check. Gotcha this catches: a password that fails domain complexity
# at creation time lands the account created-but-DISABLED, silently.
Get-ADUser $Name -Properties Enabled, MemberOf |
    Select-Object Name, Enabled,
    @{ n = 'Groups'; e = { ($_.MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }) -join ', ' } }
