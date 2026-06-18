# Short-lived TLS/SSL certificate mandates force teams to automate renewal across sprawling infra, and many still rotate manually.

**Score:** 43.8/100  |  **Domain:** network  |  **Sources:** 1  |  **Evidence:** 1

## Why it's strong
- Breadth: 1 independent sources, 1 evidence items
- Signal mix: frustration ×1, unmet_need ×1

## Entrepreneurial fit
- **TAM signal:** the CA/Browser Forum is collapsing TLS lifetimes toward **47-day certs by 2029** (Apple/Google pushing). Every org with public services must automate renewal across heterogeneous infra (LBs, appliances, internal PKI, IoT/device certs). ACME/Let's Encrypt solved the easy web case; the **long tail ACME doesn't cover** (non-ACME appliances, internal PKI, workload/device identity) is still manual.
- **Who would buy:** platform/infra/security teams at mid-large enterprises; regulated industries with heavy internal PKI.
- **Why now:** the 47-day mandate timeline forces action; rise of short-lived workload identity (SPIFFE) and Non-Human Identity makes cert lifecycle a board-level operational risk.

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| hackernews | 2024-10-15 | https://news.ycombinator.com/item?id=41853733 | frustration,unmet_need | Sysadmins rage over Apple's 'nightmarish' SSL/TLS cert lifespan cuts |

## Risks / why it might NOT be solvable
- **Entrenched incumbents own enterprise CLM:** Venafi (now CyberArk), DigiCert, Keyfactor, AppViewX — the category exists and is **consolidating** (CyberArk acquired Venafi).
- **ACME + Let's Encrypt are free** for the common web case, capping willingness to pay there.
- A new entrant needs a **sharp wedge** (the non-ACME device long tail, or developer-first short-lived workload certs) rather than head-on CLM.
- *Why it persists:* it's an operational grind more than an unsolved problem — the opportunity is automation reach + ease, not a missing primitive.
