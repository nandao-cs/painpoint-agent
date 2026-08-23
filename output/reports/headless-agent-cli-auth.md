# Headless and sandboxed AI agents and CLIs can't complete browser-based OAuth, so teams shuffle long-lived token files between ephemeral environments — an insecure, brittle workaround.

**Score:** 40.4/100  |  **Domain:** IAM  |  **Sources:** 2  |  **Evidence:** 3

## Why it's strong
- Breadth: 2 independent sources, 3 evidence items
- Signal mix: frustration ×1, unmet ×2

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| hackernews | 2026-06-25 | https://news.ycombinator.com/item?id=48670619 | frustration | Codex sandboxes' OAuth is a pain; I manually copy auth.json files around — madness. |
| hackernews | 2026-06-19 | https://news.ycombinator.com/item?id=48596439 | unmet | MCP OAuth lacks DCR; teams hardcode client_id and 'lie' to clients as a workaround. |
| lobsters | 2026-06-18 | https://lobste.rs/s/nqv7yo | unmet | Engineers debate how to authenticate CLIs correctly without leaking long-lived tokens. |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
