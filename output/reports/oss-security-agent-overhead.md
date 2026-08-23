# Self-hosted open-source detection agents (Falco, CrowdSec, Wazuh) are resource-heavy and crash-prone, eroding trust and burdening the small teams that run them.

**Score:** 46.0/100  |  **Domain:** monitoring  |  **Sources:** 1  |  **Evidence:** 4

## Why it's strong
- Breadth: 1 independent sources, 4 evidence items
- Signal mix: frustration ×3, unmet ×1

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| github | 2026-05-12 | https://github.com/crowdsecurity/crowdsec/issues/4464 | frustration | CrowdSec update doubled-to-tripled server CPU with nothing in logs. |
| github | 2025-11-06 | https://github.com/wazuh/wazuh/issues/33038 | frustration | Wazuh manager process crashes every 1-2 days after upgrade. |
| github | 2025-07-09 | https://github.com/falcosecurity/falco/issues/3637 | frustration | Falco triggers kernel soft lockups / CPU stalls in production. |
| github | 2025-06-18 | https://github.com/wazuh/wazuh/issues/30476 | unmet | Wazuh vulnerability indexer balloons disk usage after upgrade. |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
