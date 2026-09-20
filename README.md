# Office IT Infrastructure: Bare Metal, Network, Identity

A documented case study of a production IT environment I designed and built from the ground up for a 15 engineer aerospace startup. The bare metal servers, the entire office network, centralised identity, multi user compute and secure remote access, owned end to end.

> This is an architecture and decisions writeup. No employer data, credentials, IPs, hostnames or proprietary configuration is included. Shared with permission, sanitised.

## The problem

A growing engineering team on per seat workstations. Hardware cost rising with every hire, inconsistent environments, no central identity, and remote access handled by a shared VPN credential that could not be revoked for one person.

## What I built

- **Bare metal server infrastructure.** Provisioned and configured two physical servers from scratch, hardware through OS through roles, plus two high performance CAD workstations. Full ownership of the physical layer.
- **Office network backbone.** Network rack, structured cabling, Layer 2 and 3 switching and routing for the whole office. The physical and logical foundation everything else runs on.
- **Windows Server 2022, Active Directory and Group Policy.** Centralised identity, access control and standardised machine policy, built from scratch.
- **Remote Desktop Services.** A multi user environment replacing per seat workstations for CAD, simulation and office workloads.
- **Cloudflare Zero Trust.** Tunnel plus WARP plus Entra ID SSO and MFA, replacing the shared credential VPN with zero inbound ports.

## Architecture

![diagram](docs/architecture.png)

## Why it is built this way

**Centralised compute over per seat hardware.** A GPU workstation per engineer does not scale linearly with headcount. Consolidating onto one RDS session host cut hardware spend by roughly 40% and made every engineer's environment identical, which removed a whole category of "works on my machine" support.

**AGDLP, not direct permissions.** Accounts go into global groups, global groups into domain local groups, and only domain local groups touch an ACL. It is more setup once, and it means onboarding a new engineer never involves editing a folder permission again.

**Zero Trust over VPN.** A shared VPN credential cannot be revoked for one person without rotating it for everyone. Per user identity with MFA can, and it removes the inbound listener entirely.

**Single DC accepted knowingly.** A second domain controller is the textbook answer. At this headcount the recovery path, a restored VM from backup, is faster and cheaper than running and patching a second DC. Recorded as accepted risk rather than an oversight.

## Outcome

- **~40% reduction in hardware spend** by consolidating workstations onto centralised multi user compute
- Central identity and policy, so the environment is consistent and manageable
- Repeatable OS imaging and scripted onboarding

## Chapters

- [**From local accounts to Zero Trust**](ad-zero-trust/) *(July 2026)*. Rebuild of the RDS environment under Active Directory: AGDLP least privilege permissions, GPO baseline, in place user migration, PowerShell onboarding automation, and Cloudflare Zero Trust replacing the shared credential VPN.

## What I learned

- Designing AD and GPO structure for a small but growing organisation
- RDS sizing, licensing and session management trade offs
- Balancing cost, security and usability against a real budget
- Owning infrastructure end to end, from procurement through build to run and support

## Skills demonstrated

Bare metal server builds · network design and cabling · Layer 2 and 3 switching and routing · Windows Server · Active Directory · Group Policy · RDS · Cloudflare Zero Trust · IT procurement · systems administration
