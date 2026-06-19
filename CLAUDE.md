# Pain Point Discovery Agent

## Mission
Identify validated, high-severity pain points in IT and cybersecurity by mining
forums and discussion sources, rank them by solvability and market signal, and
(in a separate, gated phase) engage communities to gather more solution data.

## Phases — never skip the gate between 2 and 3
1. DISCOVER  → scrape sources, extract candidate pain points
2. VALIDATE  → score, dedupe, rank, write briefs.
2.5 THESIS   → for each NEW strong pain point, synthesize an investment thesis,
               complement it with current news from Readwise, score it with the
               Adoption-Horizon × Pain-Imminence multipliers, and write it to the
               Notion "Investment Theses" DB (agents/thesis.md). Idempotent.
2.6 TREND    → AI×Security trend radar: scripts/ai_trends.py computes pain-velocity
               (lens #1), each rising theme is validated against capital + adoption
               signals (lens #3), surviving themes become AI-Trend theses; all
               theses re-scored by the same multipliers. STOP after this.
               Human reviews briefs + theses.
3. ENGAGE    → only on explicit human approval per-painpoint, post & monitor

## Hard rules
- Phase 3 posting requires the file `output/approved.txt` to contain the
  painpoint ID. Never post otherwise.
- Respect each forum's ToS and rate limits in config/sources.yaml.
- Never fabricate a data source. Every claim links to a real URL with a
  scraped timestamp.
- Store everything in data/painpoints.db. Idempotent runs (re-running never
  duplicates rows).

## Definition of a "strong" pain point
A pain point qualifies as a candidate only if it has:
- A clear one-sentence problem statement (the user's words paraphrased)
- ≥ N distinct sources discussing it (default N=8, set in scoring.yaml)
- Recency: activity within the configured lookback window
- Evidence of unmet need (people complaining no good solution exists, or
  hacking together workarounds)
- Willingness-to-pay signal (mentions of budget, "would pay", switching tools)

## Workflow commands
- `python scripts/scrape.py --source <name>`  → pull raw posts
- `python scripts/score.py`                   → rank candidates
- Generate brief: read top candidates, write to output/reports/<id>.md
