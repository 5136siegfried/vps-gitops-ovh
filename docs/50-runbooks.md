# 50 — Runbooks

## RB-01 : Accès SSH cassé

**Symptôme** : connexion SSH refusée, timeout, ou erreur de clé.

**Causes fréquentes** :
- IP bannie par fail2ban
- Port SSH changé et UFW pas mis à jour
- Clé SSH incorrecte
- `AllowUsers` trop restrictif

**Procédure** :

```bash
# 1. Tenter depuis une autre IP
ssh -p 2222 deploy@VPS_IP

# 2. Vérifier si c'est fail2ban
# → Ouvrir la console KVM OVH
fail2ban-client banned
fail2ban-client set sshd unbanip <TON_IP>

# 3. Vérifier UFW
ufw status numbered

# 4. Vérifier sshd_config
sshd -t
cat /etc/ssh/sshd_config | grep -E "Port|AllowUsers|PasswordAuth"

# 5. Redémarrer SSH
systemctl restart sshd
```

**Si accès totalement perdu** → Console KVM OVH → accès root console → corriger et relancer.

---

## RB-02 : Déploiement GitHub Actions cassé

**Symptôme** : workflow CD en échec.

**Procédure** :

```bash
# 1. Lire les logs du workflow GitHub Actions

# 2. Tester la connexion SSH manuellement
ssh -p 2222 -i ~/.ssh/id_ed25519 deploy@VPS_IP

# 3. Tester le playbook en local avec --check
ansible-playbook -i ansible/inventory/production.ini ansible/playbook.yml --check

# 4. Vérifier que les secrets GitHub sont corrects
# Settings → Secrets → VPS_HOST, VPS_USER, VPS_SSH_KEY

# 5. Relancer le workflow manuellement
# Actions → Deploy VPS → Re-run jobs
```

---

## RB-03 : Rollback via snapshot OVH

**Quand l'utiliser** : déploiement catastrophique, OS irrécupérable, corruption.

**Procédure** :
1. Espace client OVH → `VPS → Backup → Snapshot`
2. Cliquer `Restaurer`
3. Attendre ~10-15 minutes
4. Vérifier l'accès SSH
5. Identifier ce qui a merdé avant de redéployer

⚠️ La restauration écrase l'état actuel sans confirmation supplémentaire.

---

## RB-04 : Container Docker down

**Symptôme** : service inaccessible, nginx retourne 502.

```bash
# 1. Identifier le container
docker ps -a
# STATUS : Exited (1) → crash

# 2. Lire les logs
docker logs <container> --tail 50

# 3. Inspecter
docker inspect <container> | jq '.[0].State'

# 4. Redémarrer
docker compose -f /opt/<service>/docker-compose.yml up -d

# 5. Si ça crashe en boucle : vérifier les variables d'env
docker compose -f /opt/<service>/docker-compose.yml config
cat /opt/<service>/.env
```

---

## RB-05 : Certificat TLS expiré

**Symptôme** : ERR_CERT_DATE_INVALID dans le navigateur.

```bash
# Vérifier l'expiration
certbot certificates

# Renouveler manuellement
certbot renew --nginx

# Si ça échoue (port 80 bloqué ?)
ufw allow 80/tcp
certbot renew --nginx
ufw delete allow 80/tcp  # si tu veux re-bloquer le 80 direct

# Recharger nginx
systemctl reload nginx
```

---

## RB-06 : Score audit < seuil d'alerte

**Symptôme** : alerte webhook reçue, score < 70.

```bash
# 1. Lire le rapport détaillé
cat /var/log/security-reports/latest.json | jq '.'

# 2. Voir les checks en échec
cat /var/log/security-reports/latest.json | jq '.checks[] | select(.status == "fail")'

# 3. Corriger les points identifiés

# 4. Relancer un audit manuel
vps-audit

# 5. Si c'est un faux positif, ajuster le threshold dans group_vars
# audit_score_threshold: 65
```

---

## RB-07 : Disque plein

**Symptôme** : erreurs "No space left on device", containers qui crashent.

```bash
# 1. Identifier
df -h
du -sh /var/lib/docker/* | sort -rh | head -10
du -sh /var/log/* | sort -rh | head -10

# 2. Nettoyage Docker (premier réflexe)
docker system prune -f
docker volume prune -f

# 3. Logs
find /var/log -name "*.gz" -mtime +30 -delete
journalctl --vacuum-size=200M

# 4. Si insuffisant : snapshots, backups anciens
find /var/log/security-reports -mtime +30 -delete
```

---

## RB-08 : fail2ban banne trop large (VPN/IP changeante)

**Symptôme** : tu te retrouves banni toi-même.

```bash
# Depuis la console KVM OVH
fail2ban-client set sshd unbanip <TON_IP>

# Ajouter ton IP en whitelist permanente
# Dans /etc/fail2ban/jail.local :
# [DEFAULT]
# ignoreip = 127.0.0.1/8 ::1 <TON_IP_OU_RANGE>
systemctl restart fail2ban
```
