#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="."

#if [ -d "$REPO_NAME" ]; then
 # echo "Le dossier '$REPO_NAME' existe déjà. Stop."
  #exit 1
#fi

mkdir -p "$REPO_NAME"/{ansible/{inventory,roles/{common,docker,reverse_proxy,monitoring}},.github/workflows,docs,scripts,examples}

# .gitignore
cat > "$REPO_NAME/.gitignore" <<'EOF'
# Inventory réel (ne pas commiter)
ansible/inventory/*.ini
!ansible/inventory/*.example

# Secrets / keys
.env
*.key
id_ed25519*
*.pem

# Ansible artifacts
*.retry
EOF

# README.md
cat > "$REPO_NAME/README.md" <<'EOF'
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
EOF

# LICENSE (MIT)
cat > "$REPO_NAME/LICENSE" <<'EOF'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# SECURITY.md
cat > "$REPO_NAME/SECURITY.md" <<'EOF'
# Security Policy

## Supported Versions
Ce repo est un template. Adapte et maintiens selon ton contexte.

## Reporting a Vulnerability
Si tu détectes un problème de sécurité dans ce template :
- ouvre une issue "Security" avec un minimum de détails exploitables
- ou contacte le mainteneur via un canal privé (à configurer)
EOF

# Docs placeholders
cat > "$REPO_NAME/docs/00-overview.md" <<'EOF'
# Overview
Objectif : gérer un VPS OVH via GitHub Actions + Ansible, de manière reproductible et publiable (sans secrets).
EOF

cat > "$REPO_NAME/docs/10-architecture.md" <<'EOF'
# Architecture
Décris le flux : GitHub → Actions → SSH → Ansible → VPS
EOF

cat > "$REPO_NAME/docs/20-security.md" <<'EOF'
# Security
SSH hardening, UFW, fail2ban, unattended-upgrades, gestion des secrets.
EOF

cat > "$REPO_NAME/docs/30-ci-cd.md" <<'EOF'
# CI/CD
- CI: lint + check
- CD: deploy sur main (et/ou environnements)
EOF

cat > "$REPO_NAME/docs/40-operations.md" <<'EOF'
# Operations
Backups, snapshots OVH, rotation logs, upgrade OS, procédures de maintenance.
EOF

cat > "$REPO_NAME/docs/50-runbooks.md" <<'EOF'
# Runbooks
Exemples :
- Accès SSH cassé
- Déploiement cassé
- Rollback snapshot
- Docker service down
EOF

# Ansible inventory example
cat > "$REPO_NAME/ansible/inventory/production.ini.example" <<'EOF'
[vps]
# Remplace par l'IP ou hostname
your.vps.ip.or.host ansible_user=deploy ansible_port=22
EOF

# Ansible playbook
cat > "$REPO_NAME/ansible/playbook.yml" <<'EOF'
- name: Configure OVH VPS
  hosts: vps
  become: true
  vars:
    # Exemple : active/désactive des rôles facilement
    enable_docker: true
    enable_reverse_proxy: true
    enable_monitoring: true
  roles:
    - role: common
    - role: docker
      when: enable_docker
    - role: reverse_proxy
      when: enable_reverse_proxy
    - role: monitoring
      when: enable_monitoring
EOF

# Role skeletons
for role in common docker reverse_proxy monitoring; do
  mkdir -p "$REPO_NAME/ansible/roles/$role"/{tasks,defaults,handlers,templates,files}
  cat > "$REPO_NAME/ansible/roles/$role/tasks/main.yml" <<EOF
---
# tasks for role: $role
EOF
  cat > "$REPO_NAME/ansible/roles/$role/defaults/main.yml" <<EOF
---
# defaults for role: $role
EOF
done

# Example compose
cat > "$REPO_NAME/examples/services.compose.yml" <<'EOF'
services:
  whoami:
    image: traefik/whoami
    container_name: whoami
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
EOF

# Bootstrap script (sur le VPS)
cat > "$REPO_NAME/scripts/bootstrap-deploy-user.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Bootstrap minimal à exécuter UNE FOIS sur le VPS (en root ou via sudo).
# - crée l'utilisateur deploy
# - ajoute une clé SSH
# - durcit un minimum sshd
#
# Usage:
#   sudo ./bootstrap-deploy-user.sh "ssh-ed25519 AAAA... ton_commentaire"

PUBKEY="${1:-}"

if [ -z "$PUBKEY" ]; then
  echo "Erreur: fournis une clé publique SSH en argument."
  echo 'Ex: sudo ./bootstrap-deploy-user.sh "ssh-ed25519 AAAA... user@host"'
  exit 1
fi

DEPLOY_USER="deploy"

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi

# sudo sans mot de passe
usermod -aG sudo "$DEPLOY_USER"
echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-"$DEPLOY_USER"
chmod 440 /etc/sudoers.d/90-"$DEPLOY_USER"

# SSH key
install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
echo "$PUBKEY" >> "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"

# sshd hardening minimal (sans casser l'accès)
SSHD="/etc/ssh/sshd_config"
cp -a "$SSHD" "$SSHD.bak.$(date +%Y%m%d%H%M%S)"

# applique/force quelques directives
grep -q '^PasswordAuthentication' "$SSHD" && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD" || echo 'PasswordAuthentication no' >> "$SSHD"
grep -q '^PermitRootLogin' "$SSHD" && sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD" || echo 'PermitRootLogin no' >> "$SSHD"
grep -q '^PubkeyAuthentication' "$SSHD" && sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD" || echo 'PubkeyAuthentication yes' >> "$SSHD"

systemctl restart ssh || systemctl restart sshd

echo "OK: user '$DEPLOY_USER' prêt, root ssh désactivé, password auth off."
EOF
chmod +x "$REPO_NAME/scripts/bootstrap-deploy-user.sh"

# GitHub Actions workflows
cat > "$REPO_NAME/.github/workflows/ci.yml" <<'EOF'
name: CI (lint + check)

on:
  pull_request:
  push:
    branches: [ "main" ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install tooling
        run: |
          sudo apt-get update
          sudo apt-get install -y ansible yamllint
          python3 -m pip install --user ansible-lint

      - name: Yamllint
        run: |
          yamllint .

      - name: Ansible-lint
        run: |
          ~/.local/bin/ansible-lint ansible

  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Ansible
        run: |
          sudo apt-get update
          sudo apt-get install -y ansible

      - name: Ansible syntax check
        run: |
          ansible-playbook --syntax-check ansible/playbook.yml
EOF

cat > "$REPO_NAME/.github/workflows/deploy.yml" <<'EOF'
name: Deploy VPS (Ansible)

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Ansible
        run: |
          sudo apt-get update
          sudo apt-get install -y ansible

      - name: Setup SSH key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.VPS_SSH_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -H "${{ secrets.VPS_HOST }}" >> ~/.ssh/known_hosts

      - name: Run Ansible
        env:
          VPS_HOST: ${{ secrets.VPS_HOST }}
          VPS_USER: ${{ secrets.VPS_USER }}
        run: |
          cd ansible
          # Option A: tu renseignes production.ini localement (gitignored)
          # ansible-playbook -i inventory/production.ini playbook.yml

          # Option B: inventory dynamique simple (sans fichier)
          echo "[vps]" > /tmp/inventory.ini
          echo "${VPS_HOST} ansible_user=${VPS_USER} ansible_port=22" >> /tmp/inventory.ini
          ansible-playbook -i /tmp/inventory.ini playbook.yml
EOF

# Init git
(
  cd "$REPO_NAME"
  git init
  git add .
  git commit -m "chore: init vps-gitops-ovh template"
)

echo "OK: repo créé dans ./$REPO_NAME"
echo "Prochaines étapes:"
echo "  cd $REPO_NAME"
echo "  (optionnel) gh repo create --public"
echo "  Configure les secrets GitHub: VPS_HOST, VPS_USER, VPS_SSH_KEY"
