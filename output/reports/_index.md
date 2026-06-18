# Pain Point Index

| Rank | ID | Score | Domain | Sources | Status | Statement |
|---|---|---|---|---|---|---|
| 1 | `selfhosted-email-deliverability` | **56.2** | email | 1 | validated | Teams self-hosting or switching email providers struggle with deliverability, spam handling, and poor support from incumbents. |
| 2 | `cert-lifespan-automation` | **43.8** | network | 1 | validated | Short-lived TLS/SSL certificate mandates force teams to automate renewal across sprawling infra, and many still rotate manually. |
| 3 | `fim-tooling-burden` | **37.9** | endpoint | 1 | validated | Existing file-integrity-monitoring tools are too noisy and high-maintenance, so teams cannot trust they would catch real tampering. |
| 4 | `mcp-server-security` | **37.0** | cloud | 1 | validated | The explosion of MCP servers creates an unmanaged supply-chain/risk surface with no standard way to vet them. |
| 5 | `siem-cost-complexity` | **35.0** | monitoring | 1 | validated | SIEM / log analytics platforms are too expensive and complex; teams want open-source security data lakes they control. |
| 6 | `backup-ransomware-resilience` | **35.0** | backup | 1 | validated | Teams cannot confidently verify their backups are immutable, untampered, and actually restorable after a ransomware attack. |
| 7 | `privileged-admin-audit` | **31.2** | compliance | 1 | validated | Organizations lack an easy, tamper-evident way to record what privileged admins actually run on production servers. |
| 8 | `ad-entitlement-visibility` | **31.2** | IAM | 1 | validated | Admins cannot easily see who belongs to which Active Directory groups, or what access those grant, without domain-admin rights. |
| 9 | `vuln-feed-aggregation` | **23.8** | vuln-mgmt | 1 | validated | Security teams lack a good way to aggregate and prioritize which vulnerability feeds to actually monitor. |

_Generated from data/painpoints.db. Top candidates have enriched briefs in this folder. Populate output/approved.txt to gate Phase 3._