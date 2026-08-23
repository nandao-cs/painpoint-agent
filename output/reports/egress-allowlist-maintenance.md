# Default-deny outbound egress filtering is best practice, but teams cannot build or maintain the allowlist against dynamic cloud destinations (ELB/CDN), so most quietly abandon egress control.

**Score:** 38.8/100  |  **Domain:** network  |  **Sources:** 1  |  **Evidence:** 5

## Why it's strong
- Breadth: 1 independent sources, 5 evidence items
- Signal mix: unmet ×4, frustration ×1

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| stackexchange | 2013-07-09 | https://security.stackexchange.com/questions/38658/firewall-defined-akamai-ip-range | unmet | Cannot get Akamai ranges to authorize outbound traffic |
| stackexchange | 2013-04-02 | https://security.stackexchange.com/questions/33616/how-to-whitelist-an-amazon-elb-in-any-firewall | unmet | ELB IPs change constantly; cannot maintain an allowlist |
| stackexchange | 2012-12-11 | https://security.stackexchange.com/questions/25289/firewall-philosophy | frustration | Admins resist default-deny-outbound and allow everything instead |
| stackexchange | 2012-03-29 | https://security.stackexchange.com/questions/13267/monitoring-outgoing-network-traffic | unmet | No visibility into what is actually leaving the server |
| stackexchange | 2010-11-23 | https://security.stackexchange.com/questions/758/egress-filtering-on-an-office-network | unmet | Few do egress filtering; forces a policy change per new app |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
