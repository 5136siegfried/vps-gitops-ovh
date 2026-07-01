# vps-gitops-ovh

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](scripts/bootstrap-deploy-user.sh)
[![Ansible](https://img.shields.io/badge/Ansible-IaC-EE0000?style=flat-square&logo=ansible&logoColor=white)](ansible/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat-square&logo=docker&logoColor=white)](ansible/roles/docker)
[![Nginx](https://img.shields.io/badge/Nginx-reverse%20proxy-009639?style=flat-square&logo=nginx&logoColor=white)](ansible/roles/reverse_proxy)
[![CI](https://img.shields.io/github/actions/workflow/status/5136siegfried/vps-gitops-ovh/ci.yml?style=flat-square&label=CI&logo=github-actions)](https://github.com/5136siegfried/vps-gitops-ovh/actions/workflows/ci.yml)
[![CD](https://img.shields.io/github/actions/workflow/status/5136siegfried/vps-gitops-ovh/deploy.yml?style=flat-square&label=CD&logo=github-actions)](https://github.com/5136siegfried/vps-gitops-ovh/actions/workflows/deploy.yml)
[![OVH](https://img.shields.io/badge/OVH-VPS-123F6D?style=flat-square&logo=ovh&logoColor=white)](https://www.ovhcloud.com)

Provisioning Ansible pour VPS OVH — du bootstrap initial au déploiement continu.

Stack : Ansible · GitHub Actions · Docker · Nginx · Let's Encrypt · Prometheus · Node Exporter · cAdvisor · fail2ban · UFW · auditd

---

## Structure

```
vps-gitops-ovh/
├── ansible/
│   ├── playbook.yml                  ← point d'entrée
│   ├── ansible.cfg
│   ├── group_vars/vps.yml            ← variables globales
│   ├── inventory/
│   │   └── production.ini.example
│   └── roles/
│       ├── common/                   ← SSH, UFW, fail2ban, sysctl, deploy user
│       ├── docker/                   ← Docker CE, Compose v2, daemon hardening
│       ├── reverse_proxy/            ← Nginx, Certbot, TLS 1.3, security headers
│       ├── monitoring/               ← Node Exporter, cAdvisor, metrics endpoint
│       └── security/                 ← vps-security-toolkit, auditd, rkhunter
├── scripts/
│   └── bootstrap-deploy-user.sh     ← à exécuter UNE FOIS sur le VPS en root
├── examples/
│   └── services.compose.yml         ← exemple de service Docker derrière nginx
├── docs/
│   ├── 00-overview.md
│   ├── 10-architecture.md
│   ├── 20-security.md
│   ├── 30-ci-cd.md
│   ├── 40-operations.md
│   └── 50-runbooks.md
└── .github/workflows/
    ├── ci.yml                        ← lint + syntax check
    └── deploy.yml                    ← deploy sur push main
```

---

## Quickstart

### 1. Bootstrap initial (une seule fois, en root)

```bash
# Sur le VPS, en root
curl -fsSL https://raw.githubusercontent.com/5136siegfried/vps-gitops-ovh/main/scripts/bootstrap-deploy-user.sh \
  | bash -s -- "ssh-ed25519 AAAA... toi@machine"
```

### 2. Configurer l'inventory

```bash
cp ansible/inventory/production.ini.example ansible/inventory/production.ini
# Éditer avec l'IP du VPS
```

### 3. Configurer les secrets GitHub Actions

| Secret | Valeur |
|--------|--------|
| `VPS_HOST` | IP ou hostname du VPS |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | Contenu de ta clé privée ed25519 |

### 4. Lancer

```bash
# Dry run local
ansible-playbook ansible/playbook.yml --check

# Déploiement
ansible-playbook ansible/playbook.yml
```

Push sur `main` → GitHub Actions déploie automatiquement.

---

## Rôles

| Rôle | Ce qu'il fait |
|------|--------------|
| `common` | SSH hardening (port custom, no root, no password), UFW, fail2ban, sysctl, deploy user |
| `docker` | Docker CE, Compose v2, daemon hardening (log rotation, no-new-privileges), prune cron |
| `reverse_proxy` | Nginx, Certbot Let's Encrypt, TLS 1.2/1.3, HSTS, security headers, rate limiting |
| `monitoring` | Node Exporter (systemd), cAdvisor (Docker), metrics endpoint sécurisé par IP |
| `security` | vps-security-toolkit (audit /100), auditd, rkhunter, PAM password policy |

---

## ⚠️ Avant le premier run Ansible

1. Le bootstrap SSH doit avoir été exécuté (`deploy` user + clé en place)
2. Vérifier `deploy_ssh_public_key` dans `group_vars/vps.yml`
3. Vérifier `prometheus_server_ip` si le rôle monitoring est activé
4. Avoir la console KVM OVH ouverte en cas de lockout SSH
5. Tester avec `--check` avant tout `--diff` ou run réel

---

## Projets liés

- [vps-security-toolkit](https://github.com/5136siegfried/vps-security-toolkit) — audit DevSecOps /100
- [vps-monitoring-toolkit](https://github.com/5136siegfried/vps-monitoring-toolkit) — stack Prometheus + Grafana + Loki côté monitoring VPS