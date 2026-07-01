# 10 — Architecture

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────┐
│                     Internet                            │
└────────────────────────┬────────────────────────────────┘
                         │ :80 / :443
┌────────────────────────▼────────────────────────────────┐
│                   VPS PROD (5136.fr)                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Nginx (reverse proxy)                          │   │
│  │  TLS Certbot · security headers · rate limiting │   │
│  └──────────┬──────────────────────────────────────┘   │
│             │ proxy_pass                                │
│  ┌──────────▼──────────────────────────────────────┐   │
│  │  Docker containers                              │   │
│  │  jobtracker · hestia · timer · webdav · ...    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Agents monitoring (bind 127.0.0.1)             │   │
│  │  Node Exporter :9100 · cAdvisor :8080           │   │
│  └──────────────────────┬──────────────────────────┘   │
│                         │ scrape (IP whitelist UFW)     │
└─────────────────────────┼───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│              VPS MONITORING (séparé)                    │
│  Prometheus · Grafana · Loki · Alertmanager             │
│  → voir vps-monitoring-toolkit                          │
└─────────────────────────────────────────────────────────┘
```

## Couches réseau

| Couche | Ports ouverts | Accessible depuis |
|--------|--------------|-------------------|
| SSH | 2222/tcp | Partout (fail2ban actif) |
| HTTP | 80/tcp | Partout (redirect HTTPS) |
| HTTPS | 443/tcp | Partout |
| Metrics | 9090/tcp | VPS monitoring uniquement (UFW) |
| Node Exporter | 9100/tcp | Loopback + VPS monitoring |
| cAdvisor | 8080/tcp | Loopback + VPS monitoring |

## Roles Ansible et ordre d'exécution

```
common          ← base système, sans ça rien ne tourne
  └─ docker     ← nécessite un OS propre et à jour
      └─ reverse_proxy  ← nécessite Docker (certbot peut tourner en Docker)
          └─ monitoring ← nécessite Docker (cAdvisor) et nginx (metrics vhost)
              └─ security ← peut tourner seul mais profite du reste
```

## Fichiers sensibles et leur emplacement

| Fichier | Emplacement VPS | Géré par |
|---------|----------------|----------|
| Clé privée SSH deploy | `~/.ssh/` local uniquement | Manuel |
| Certs TLS | `/etc/letsencrypt/live/` | Certbot (rôle reverse_proxy) |
| Secrets applicatifs | `.env` dans `/opt/<service>/` | À toi |
| Rapport audit | `/var/log/security-reports/` | Rôle security |
| Logs auditd | `/var/log/audit/` | auditd |
