# Validator Agent

Score each candidate using config/scoring.yaml weights (0–1 each, then
weighted sum → final_score 0–100).

For each pain point write output/reports/<id>.md:

---
# <Problem statement>
**Score:** <final_score>/100  |  **Domain:** <tag>  |  **Sources:** <count>

## Problem statement
<one paragraph: what, who suffers, why current solutions fail>

## Why it's strong
- Breadth: <count> independent sources
- Frustration: <evidence>
- Unmet need: <evidence>
- Willingness to pay: <evidence>

## Entrepreneurial fit
- TAM signal, who would buy, why now

## Evidence table
| Source | Date | URL | Signal |
|--------|------|-----|--------|
| ...    | ...  | ... | ...    |

## Risks / why it might NOT be solvable
<incumbents, regulation, why nobody's done it yet>
---

Rank all reports in output/reports/_index.md by score, top first.
STOP here. Wait for human to populate output/approved.txt.
