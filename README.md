# Office IT Infrastructure — Bare-Metal Servers, Network & Windows Server/RDS

A documented case study of a production IT environment I designed and built
from the ground up for a 15+ engineer aerospace startup: the bare-metal
servers, the entire office network, centralized identity, multi-user compute,
and secure remote access — owned end to end.

> This is an architecture & decisions writeup. No employer data, credentials,
> IPs, hostnames, or proprietary configuration is included. Shared with
> permission, sanitized.

## The problem
A growing engineering team on per-seat workstations: rising hardware cost,
inconsistent environments, no central identity, ad-hoc remote access.

## What I built
- **Bare-metal server infrastructure** — provisioned and configured 2 physical
  servers from scratch (hardware → OS → roles), plus 2 high-performance CAD
  workstations. Full ownership of the physical layer.
- **Office network backbone** — designed and built the complete network for the
  whole office (15+ engineers): network rack, structured cabling, Layer 2/3
  switching and routing. The physical + logical foundation everything else runs on.
- **Windows Server 2022 + Active Directory + Group Policy** — centralized
  identity, access control, and standardized machine policy, built from scratch.
- **Remote Desktop Services (RDS)** — multi-user environment replacing per-seat
  workstations for CAD/simulation/office workloads.
- **VPN remote access** — secure connectivity for the distributed team.

## Outcome
- **~40% reduction in hardware spend** by consolidating workstations onto
  centralized multi-user compute
- Central identity + policy → consistent, manageable, more secure environment
- Repeatable OS imaging and onboarding

## Architecture (sanitized)
![diagram](docs/architecture.png)

## Chapters
- [**From local accounts to Zero Trust**](ad-zero-trust/) *(July 2026)* —
  rebuild of the RDS environment under Active Directory: AGDLP least-privilege
  permissions, GPO baseline, in-place user migration, PowerShell onboarding
  automation, and Cloudflare Zero Trust (tunnel + WARP + Entra ID SSO/MFA)
  replacing the shared-credential VPN.

## What I learned
- Designing AD/GPO structure for a small but growing org
- RDS sizing, licensing, and session management trade-offs
- Balancing cost, security, and usability in a real budget
- Owning infrastructure end-to-end: procurement → build → run → support

## Skills demonstrated
Bare-metal server builds · network design & cabling · Layer 2/3 switching &
routing · Windows Server · Active Directory · Group Policy · RDS · VPN ·
network infrastructure · IT procurement · systems administration
