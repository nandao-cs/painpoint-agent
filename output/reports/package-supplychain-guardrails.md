# Developers have no practical install-time guardrails against malicious packages in OS/language registries (AUR, npm, PyPI), so supply-chain compromises slip into builds.

**Score:** 42.0/100  |  **Domain:** appsec  |  **Sources:** 2  |  **Evidence:** 8

## Why it's strong
- Breadth: 2 independent sources, 8 evidence items
- Signal mix: unmet ×4, frustration ×4

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| lobsters | 2026-08-04 | https://lobste.rs/s/krevdg | unmet | Keyv and related npm packages compromised in supply-chain attack |
| lobsters | 2026-07-31 | https://lobste.rs/s/0mixjj | frustration | Arch disables AUR package adoption after repeated malicious uploads |
| hackernews | 2026-07-27 | https://news.ycombinator.com/item?id=49075417 | unmet | Wants to try AI-coded projects but fears credential theft; asks best sandbox approach |
| lobsters | 2026-06-18 | https://lobste.rs/s/e325gb | frustration | AUR helper release shaped by the AURpocalypse malicious-package wave |
| hackernews | 2026-06-17 | https://news.ycombinator.com/item?id=48570033 | unmet | Builders shipping a package firewall because registries lack install-time guardrails. |
| lobsters | 2026-06-11 | https://lobste.rs/s/ta0sem | frustration | Hundreds of AUR packages backdoored by infostealer; users got no warning. |
| hackernews | 2026-06-02 | https://news.ycombinator.com/item?id=48368376 | unmet | One command needed to harden npm/pnpm/yarn/bun/uv against supply-chain attacks. |
| hackernews | 2026-06-01 | https://news.ycombinator.com/item?id=48359644 | frustration | Malicious npm packages slipped into Red Hat cloud services. |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
