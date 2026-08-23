# Teams hand AI agents broad, long-lived production credentials with no way to scope, least-privilege, rotate, revoke, or audit a non-human/agent identity, so agents end up with more access than senior engineers.

**Score:** 62.5/100  |  **Domain:** IAM  |  **Sources:** 1  |  **Evidence:** 4

## Why it's strong
- Breadth: 1 independent sources, 4 evidence items
- Signal mix: unmet_need ×4, frustration ×3

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| hackernews | 2026-06-17 | https://news.ycombinator.com/item?id=48572665 | unmet_need | DIY guardrails so an LLM agent cannot run unsafe writes against the database |
| hackernews | 2026-06-05 | https://news.ycombinator.com/item?id=48411192 | unmet_need,frustration | No clean way to scope agent access; duct-taped into prompts, security review exploded |
| hackernews | 2026-02-19 | https://news.ycombinator.com/item?id=47075823 | frustration,unmet_need | Gave agent prod API keys/filesystem; threat model was essentially hope |
| hackernews | 2026-02-10 | https://news.ycombinator.com/item?id=46966307 | frustration,unmet_need | Agents get cloud admin creds to be useful — more prod access than senior engineers |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
