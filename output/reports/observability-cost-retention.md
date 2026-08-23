# Teams running open-source observability stacks (Loki/Prometheus/Elasticsearch) cannot keep log, metric, and trace volume within storage budgets; dropping data, cutting retention, or paying SaaS ingestion all hurt.

**Score:** 42.9/100  |  **Domain:** monitoring  |  **Sources:** 3  |  **Evidence:** 6

## Why it's strong
- Breadth: 3 independent sources, 6 evidence items
- Signal mix: wtp ×1, unmet ×3, frustration ×2

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| hackernews | 2026-06-16 | https://news.ycombinator.com/item?id=48560279 | wtp | Observability tax: piping all OTLP to Datadog/Splunk gets expensive fast |
| stackexchange | 2026-04-20 | https://devops.stackexchange.com/questions/21692/recommendations-for-complex-log-parsing-and-search | unmet | 200GB/month logs, most noise we cannot afford to store |
| github | 2022-08-10 | https://github.com/grafana/loki/issues/6876 | unmet | Loki fills disk and crashes; no auto-retention threshold |
| github | 2022-03-11 | https://github.com/grafana/loki/issues/5605 | frustration | Too many small S3 chunks; cannot control cost without memory blowup |
| stackexchange | 2018-11-26 | https://devops.stackexchange.com/questions/5541/how-fast-does-prometheus-data-grow | frustration | When will TSDB hit 1TB at this growth rate? |
| github | 2016-02-10 | https://github.com/prometheus/prometheus/issues/1381 | unmet | Want long-term aggregate retention without keeping raw data |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
