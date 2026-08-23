# Code, dependency, and container scanners (SAST/SCA) bury teams in CVE findings that lack reachability or exploitability context, with broken suppression and inflated severities, so the few that matter get lost.

**Score:** 39.0/100  |  **Domain:** appsec  |  **Sources:** 3  |  **Evidence:** 6

## Why it's strong
- Breadth: 3 independent sources, 6 evidence items
- Signal mix: unmet ×2, frustration ×4

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| hackernews | 2026-02-20 | https://news.ycombinator.com/item?id=47095265 | unmet | CVE in a function you never call is noise; no reachability |
| hackernews | 2025-11-20 | https://news.ycombinator.com/item?id=45997568 | frustration | Dependabot opens 20-30 PRs/week; critical does not mean exploitable in context |
| github | 2024-11-08 | https://github.com/wazuh/wazuh/issues/26765 | frustration | CVE false-positive disabled by default; called a waste of time |
| github | 2024-04-09 | https://github.com/aquasecurity/trivy/issues/6473 | frustration | Trivy severity inflation; HIGH vanishes in detail view, confuses teams |
| stackexchange | 2022-09-16 | https://security.stackexchange.com/questions/264853/what-is-the-easiest-way-to-find-non-vulnerable-container-images | unmet | Scanners list vulns but not which base image fixes them |
| github | 2017-06-15 | https://github.com/zaproxy/zaproxy/issues/3662 | frustration | ZAP flags SQLi false positive on whitelisted non-data page |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
