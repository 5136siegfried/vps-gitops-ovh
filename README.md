# vps-gitops-ovh

Template public “portfolio-grade” pour gérer un VPS OVH comme une petite prod :
- Configuration idempotente via Ansible
- CI (lint + check) et CD (deploy) via GitHub Actions
- Sécurité de base (SSH hardening, UFW, fail2ban, unattended-upgrades)
- Docker + reverse proxy + monitoring (roles séparés)
- Docs + runbooks

## Quickstart
1. Fork / clone
2. Copie `ansible/inventory/production.ini.example` → `ansible/inventory/production.ini` (ce fichier est gitignored)
3. Ajoute les secrets GitHub Actions : `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`
4. Push sur `main` → déploiement

## Ce que ce repo démontre
- IaC et automatisation (Ansible roles)
- CI/CD sérieux (lint, check-mode, déploiement)
- Sécurité + ops mindset (docs, runbooks, rollback via snapshot)
