# Supply-chain attestations (trusted publishing, signed commits, build provenance) do not actually prove the artifact you install was built from the source you reviewed, and teams have no way to verify that chain end-to-end or to cover self-hosted CI at all.

**Score:** 41.5/100  |  **Domain:** appsec  |  **Sources:** 2  |  **Evidence:** 6

## Why it's strong
- Breadth: 2 independent sources, 6 evidence items
- Signal mix: unmet ×4, wtp ×1, frustration ×1

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| lobsters | 2026-08-12 | https://lobste.rs/s/lbaw4d | unmet | Android hardware attestation bypassed from the analyst chair |
| lobsters | 2026-07-07 | https://lobste.rs/s/8d9pgd | unmet | Attestations guarantee different things than users assume; self-hosted CI unsupported |
| lobsters | 2026-07-07 | https://lobste.rs/s/qlw9wg | unmet | Git hash chains are malleable, so commit identity proves less than assumed |
| discourse | 2026-06-24 | https://community.grafana.com/t/action-required-signed-commits-mandatory-for-all-grafana-repositories/163404 | wtp | Vendor forces signed commits on all repositories; contributors must retool |
| lobsters | 2026-05-11 | https://lobste.rs/s/pu6cxi | unmet | Practitioner built own attested-build tool for verifiable provenance |
| lobsters | 2026-05-10 | https://lobste.rs/s/j7wksg | frustration | Attestation framed as monopoly enabler rather than a trust guarantee |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
