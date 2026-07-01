# 00 — Overview

## Objectif

Gérer un VPS OVH comme une petite prod : reproductible, versionné, auditable, déployable en une commande.

Ce repo est à la fois un outil opérationnel et un projet portfolio — il démontre une pratique DevOps/SRE réelle sur infrastructure personnelle.

## Philosophie

- **Idempotent** — on peut relancer le playbook autant de fois qu'on veut sans casse
- **Gitops** — tout changement passe par un commit, tout déploiement passe par GitHub Actions
- **Principe du moindre privilège** — le deploy user n'a que ce dont il a besoin, les ports ne sont ouverts que pour les IPs légitimes
- **Fail safe** — snapshot OVH avant tout changement majeur, console KVM accessible en cas de lockout

## Périmètre

| Couvert | Hors périmètre |
|---------|---------------|
| Hardening VPS initial | Gestion DNS |
| Docker + reverse proxy | Kubernetes |
| TLS automatique | Multi-cloud |
| Monitoring agents | Stack de logs complète (→ vps-monitoring-toolkit) |
| Audit sécurité automatisé | WAF applicatif |

## Prérequis

- VPS OVH Ubuntu 22.04+ (VPS Value ou supérieur)
- Accès root initial (console KVM ou SSH root temporaire)
- Un compte GitHub avec Actions activé
- `ansible >= 2.14` en local pour les runs manuels
- Une paire de clés SSH ed25519 dédiée au deploy

## Flux général

```
Dev local → git push main → GitHub Actions CI (lint + check) → CD (ansible-playbook) → VPS
                                                                      ↑
                                                         Secrets: VPS_HOST, VPS_USER, VPS_SSH_KEY
```
