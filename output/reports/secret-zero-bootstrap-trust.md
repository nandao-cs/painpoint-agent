# Every secrets and encryption system depends on a foundational 'secret zero' that unlocks all others, and teams have no satisfying, auditable place to store it without recreating the problem.

**Score:** 27.5/100  |  **Domain:** secrets  |  **Sources:** 2  |  **Evidence:** 5

## Why it's strong
- Breadth: 2 independent sources, 5 evidence items
- Signal mix: unmet ×3, frustration ×2

## Entrepreneurial fit
_[Validator: TAM signal, who would buy, why now]_

## Evidence table

| Source | Date | URL | Signal | Quote |
|--------|------|-----|--------|-------|
| stackexchange | 2024-07-27 | https://security.stackexchange.com/questions/278018/do-credential-stores-have-added-value-for-api-key-protection-on-unsupervised-sys | unmet | Do credential stores help on unsupervised servers with no HSM? |
| stackexchange | 2022-01-28 | https://security.stackexchange.com/questions/259185/how-vault-agent-solves-secret-zero-challenge-in-kubernetes | unmet | There must be a secret zero somewhere; what protects it? |
| github | 2019-01-15 | https://github.com/hashicorp/vault/issues/6046 | frustration | Vault auto-unseal breaks if the single KMS key is lost |
| stackexchange | 2013-02-05 | https://serverfault.com/questions/475441/encrypted-offsite-backups-where-to-store-the-encryption-key | frustration | Storing the backup key with the tapes defeats encryption |
| stackexchange | 2012-03-01 | https://security.stackexchange.com/questions/12332/where-to-store-a-server-side-encryption-key | unmet | Where to safely store a server-side encryption key |

## Risks / why it might NOT be solvable
_[Validator: incumbents, regulation, why nobody's done it yet]_
