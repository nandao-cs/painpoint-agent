# Commercial AI coding agents and IDE extensions run with full developer-workstation privileges and their vendor sandboxes are repeatedly escapable, so a prompt-injected repo, MCP server or dependency turns the dev machine and its credentials into the breach path, leaving teams to hand-roll microVM and bubblewrap isolation.

**Score:** 46.0/100  |  **Domain:** appsec  |  **Sources:** 3  |  **Evidence:** 6

## Why it's strong
- Breadth: 3 independent sources, 6 evidence items
- Signal mix: unmet ×5, frustration ×1

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| lobsters | 2026-08-10 | https://lobste.rs/s/stehhb | unmet | Practitioners hand-roll bubblewrap sandboxes because no product does it |
| hackernews | 2026-08-09 | https://news.ycombinator.com/item?id=49235154 | unmet | Reimplemented CI runner in microVMs to stop trusting hosted execution |
| hackernews | 2026-08-04 | https://news.ycombinator.com/item?id=49168002 | unmet | Built own microVM workbench; found no local-first isolated agent runner |
| lobsters | 2026-07-20 | https://lobste.rs/s/bper0d | unmet | Seven sandbox escapes across four coding-agent vendors; containers called immature |
| lobsters | 2026-07-14 | https://lobste.rs/s/vlr279 | frustration | Full disclosure of arbitrary code execution in the Cursor editor |
| discourse | 2026-07-08 | https://discuss.hashicorp.com/t/hcsec-2026-21-nomad-vulnerable-to-sandbox-escape-in-docker-task-driver/77561 | unmet | Orchestrator advisory: sandbox escape via the Docker task driver |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
