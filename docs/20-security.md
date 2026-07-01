# 20 — Security

## Modèle de menace

Ce VPS expose des services publics sur Internet. Les menaces principales :

- **Brute force SSH** → fail2ban + clé uniquement + port non standard
- **Exploitation de services exposés** → nginx devant tout, headers stricts, rate limiting
- **Élévation de privilèges** → no-new-privileges Docker, auditd, sysctl
- **Compromission de dépendances** → unattended-upgrades, rkhunter hebdomadaire
- **Fuite de secrets** → `.gitignore` strict, pas de secrets dans les vars Ansible claires (→ vault)

## Ce que fait chaque rôle

### `common`
- SSH port 2222, no root, password auth off, `AllowUsers deploy`
- UFW : deny in / allow out, whitelist explicite des ports
- fail2ban : SSH + nginx-http-auth + nginx-botsearch, ban via UFW
- sysctl : anti-spoofing, SYN cookies, ICMP redirects off, log martians
- unattended-upgrades : patchs de sécurité automatiques

### `docker`
- `no-new-privileges: true` dans daemon.json → les containers ne peuvent pas élever leurs privilèges
- `live-restore: true` → restart du daemon sans couper les containers
- `userland-proxy: false` → moins de surface d'attaque réseau
- Log rotation : 10MB × 3 fichiers max par container

### `reverse_proxy`
- TLS 1.2/1.3 uniquement, ciphers modernes
- HSTS : `max-age=63072000; includeSubDomains; preload`
- OCSP stapling
- Security headers : X-Frame-Options, X-Content-Type-Options, CSP prêt à configurer
- Rate limiting par zone (10r/s général, 30r/s API)
- Blocage extensions PHP/ASP/JSP, dotfiles

### `monitoring`
- Node Exporter bind sur 127.0.0.1 uniquement
- cAdvisor bind sur 127.0.0.1 uniquement
- Port 9090 (agrégateur nginx) ouvert uniquement depuis l'IP du VPS monitoring

### `security`
- **vps-security-toolkit** : audit /100 quotidien à 2h, alerte webhook si score < 70
- **auditd** : surveillance `/etc/passwd`, `/etc/shadow`, sudoers, SSH config, cron, Docker, modules kernel
- **rkhunter** : scan hebdomadaire, baseline à l'install
- **PAM** : password min 14 chars, majuscule + minuscule + chiffre + spécial

## Secrets management

### Ce qui ne doit JAMAIS être dans le repo

```
ansible/inventory/production.ini   ← gitignored
group_vars/all/vault.yml            ← à créer avec ansible-vault
*.key, *.pem, id_ed25519*           ← gitignored
.env                                ← gitignored
```

### Ansible Vault (recommandé)

```bash
# Créer un vault pour les secrets
ansible-vault create ansible/group_vars/all/vault.yml

# Contenu type :
# vault_deploy_ssh_public_key: "ssh-ed25519 AAAA..."
# vault_audit_alert_webhook: "https://hooks.slack.com/..."
# vault_certbot_email: "admin@5136.fr"

# Utiliser dans les plays
ansible-playbook ansible/playbook.yml --ask-vault-pass
```

### GitHub Actions Secrets

| Secret | Usage |
|--------|-------|
| `VPS_HOST` | IP du VPS prod |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | Clé privée ed25519 (contenu complet) |
| `VAULT_PASSWORD` | Mot de passe ansible-vault (si utilisé) |

## Checklist avant mise en prod

- [ ] Bootstrap exécuté, connexion deploy OK
- [ ] `ansible-playbook --check` passe sans erreur
- [ ] Snapshot OVH pris avant le premier run réel
- [ ] Console KVM accessible
- [ ] fail2ban actif et configuré
- [ ] `ufw status` montre les bonnes règles
- [ ] Audit initial passé > 70/100
- [ ] Webhook d'alerte configuré
