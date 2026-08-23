# CI/CD pipelines authenticate to cloud accounts through OIDC federation whose trust policies are almost impossible to scope correctly, so one loose audience or subject claim silently grants any repo, fork or pull request production access.

**Score:** 46.1/100  |  **Domain:** appsec  |  **Sources:** 2  |  **Evidence:** 4

## Why it's strong
- Breadth: 2 independent sources, 4 evidence items
- Signal mix: unmet ×3, frustration ×1, wtp ×1

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| lobsters | 2026-08-14 | https://lobste.rs/s/qhxzrd | unmet | OWASP catalogues ten CI/CD risks teams still have no tooling for |
| lobsters | 2026-08-10 | https://lobste.rs/s/ipt1em | unmet | GitHub Actions OIDC lacks audience constraints; loose trust policies let any repo assume roles |
| hackernews | 2026-08-09 | https://news.ycombinator.com/item?id=49235154 | frustration,wtp | Team rebuilt Actions runners in isolated microVMs over trust and reliability worries |
| lobsters | 2026-08-04 | https://lobste.rs/s/krevdg | unmet | npm packages compromised through pipeline credentials, cascading into every dependent build |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
