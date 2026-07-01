# 30 — CI/CD

## Vue d'ensemble

```
Push / PR
   │
   ├─ CI (ci.yml) ──────────────────────────────────────────────
   │   ├─ yamllint          ← syntaxe YAML stricte
   │   ├─ ansible-lint      ← best practices Ansible
   │   └─ ansible --syntax-check   ← playbook parseable
   │
   └─ CD (deploy.yml) ─ sur push main uniquement ──────────────
       ├─ Setup SSH key (depuis secret)
       ├─ Inventory dynamique (VPS_HOST + VPS_USER)
       └─ ansible-playbook playbook.yml
```

## Workflows

### CI — `.github/workflows/ci.yml`

Déclenché sur : tous les push + pull requests

```yaml
jobs:
  lint:     yamllint + ansible-lint
  check:    ansible --syntax-check
```

Le lint bloque les PR mal formées avant qu'elles n'atterrissent sur main.

### CD — `.github/workflows/deploy.yml`

Déclenché sur : push sur `main` uniquement

```yaml
jobs:
  deploy:
    - checkout
    - install ansible
    - setup SSH key depuis secret
    - ssh-keyscan (known_hosts)
    - ansible-playbook
```

## Secrets à configurer

Aller dans `Settings → Secrets and variables → Actions` :

| Secret | Description |
|--------|-------------|
| `VPS_HOST` | IP ou hostname du VPS |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | Contenu complet de `~/.ssh/id_ed25519` (clé privée) |

## Bonnes pratiques

**Environnements multiples** : créer un environment GitHub `production` avec une règle de protection (review requise avant deploy).

**Rollback** : le CD ne fait pas de rollback automatique. En cas de problème → snapshot OVH (voir runbooks).

**Dry run avant merge** : ajouter un job `check` dans la CI qui lance `ansible-playbook --check` contre le VPS de staging si disponible.

**Tags Ansible** : pour déployer un seul rôle sans tout rejouer :

```bash
ansible-playbook ansible/playbook.yml --tags docker
ansible-playbook ansible/playbook.yml --tags reverse_proxy,monitoring
```

## Lancer manuellement

```bash
cd ansible

# Check complet
ansible-playbook -i inventory/production.ini playbook.yml --check --diff

# Deploy
ansible-playbook -i inventory/production.ini playbook.yml

# Rôle spécifique
ansible-playbook -i inventory/production.ini playbook.yml --tags security

# Verbose
ansible-playbook -i inventory/production.ini playbook.yml -vvv
```

## yamllint config recommandée

Créer `.yamllint.yml` à la racine :

```yaml
extends: default
rules:
  line-length:
    max: 120
  truthy:
    allowed-values: ['true', 'false']
```
