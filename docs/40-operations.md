# 40 — Operations

## Routine de maintenance

### Quotidien (automatique)
- Audit sécurité vps-security-toolkit à 2h → rapport dans `/var/log/security-reports/`
- Unattended-upgrades : patchs de sécurité OS

### Hebdomadaire (automatique)
- rkhunter scan (lundi 3h30)
- Docker system prune (dimanche 3h)
- Renouvellement Certbot si < 30j (tous les 15j à 3h)
- logwatch rapport

### Mensuel (manuel)
- Vérifier les rapports d'audit accumulés
- Vérifier l'espace disque
- Vérifier les logs fail2ban
- Snapshot OVH

## Commandes courantes

### Statut général

```bash
# Services actifs
systemctl status nginx docker node_exporter fail2ban auditd

# Docker
docker ps -a
docker stats --no-stream

# Disque
df -h
du -sh /var/lib/docker

# Mémoire
free -h

# Connexions actives
ss -tlnp
```

### Nginx

```bash
# Vérifier la config
nginx -t

# Reload sans downtime
systemctl reload nginx

# Logs en direct
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Docker

```bash
# Logs d'un container
docker logs <container> -f --tail 100

# Entrer dans un container
docker exec -it <container> bash

# Redémarrer un service
docker compose -f /opt/<service>/docker-compose.yml restart

# Nettoyage manuel
docker system prune -f
```

### Fail2ban

```bash
# Statut
fail2ban-client status
fail2ban-client status sshd

# Débannir une IP
fail2ban-client set sshd unbanip <IP>

# Voir les IPs bannies
fail2ban-client banned
```

### Certbot

```bash
# Vérifier les certificats
certbot certificates

# Renouvellement forcé
certbot renew --force-renewal --nginx

# Test de renouvellement (dry run)
certbot renew --dry-run
```

### Monitoring

```bash
# Vérifier Node Exporter
curl -s http://127.0.0.1:9100/metrics | head -20

# Vérifier cAdvisor
curl -s http://127.0.0.1:8080/metrics | head -20

# Lancer un audit manuel
vps-audit
cat /var/log/security-reports/latest.json | jq '.score'
```

## Gestion des mises à jour

### OS (manuel ponctuel)

```bash
apt update && apt list --upgradable
apt upgrade
# Reboot si kernel mis à jour
reboot
```

### Docker images

```bash
# Lister les images obsolètes
docker images

# Mettre à jour un service
cd /opt/<service>
docker compose pull
docker compose up -d
```

## Espace disque

```bash
# Identifier les gros consommateurs
du -sh /var/lib/docker
du -sh /var/log
du -sh /etc/letsencrypt

# Rotation manuelle des logs si nécessaire
logrotate -f /etc/logrotate.conf

# Nettoyer les vieilles archives apt
apt autoremove --purge
apt clean
```

## Snapshots OVH

Prendre un snapshot **avant** :
- Premier run Ansible
- Mise à jour majeure d'OS
- Changement de config SSH
- Migration de service

Via l'espace client OVH : `VPS → Backup → Snapshot → Créer un snapshot`

Un snapshot est conservé jusqu'au suivant. Limité à 1 snapshot gratuit par VPS.
