#!/usr/bin/env bash
# ============================================================
# init.sh — Bootstrap local du repo vps-gitops-ovh
# À exécuter UNE FOIS après avoir cloné le repo
# ============================================================
set -euo pipefail

echo "==> vps-gitops-ovh — init local"

# 1. Vérifier les dépendances
echo "[1/4] Vérification des dépendances..."

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "  ✗ $1 manquant"
    MISSING=1
  else
    echo "  ✓ $1 ($(command -v "$1"))"
  fi
}

MISSING=0
check_cmd ansible
check_cmd ansible-playbook
check_cmd ansible-lint
check_cmd yamllint
check_cmd ssh
check_cmd git

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo "Installe les dépendances manquantes :"
  echo "  pip install ansible ansible-lint"
  echo "  pip install yamllint"
  exit 1
fi

# 2. Copier l'inventory exemple
echo "[2/4] Inventory..."
if [ ! -f ansible/inventory/production.ini ]; then
  cp ansible/inventory/production.ini.example ansible/inventory/production.ini
  echo "  → ansible/inventory/production.ini créé"
  echo "  ⚠️  Édite-le avec l'IP de ton VPS avant de continuer"
else
  echo "  → ansible/inventory/production.ini existe déjà, skip"
fi

# 3. Vérifier la clé SSH
echo "[3/4] Clé SSH deploy..."
KEY_FOUND=0
for keyfile in ~/.ssh/id_ed25519 ~/.ssh/id_rsa ~/.ssh/deploy; do
  if [ -f "$keyfile" ]; then
    echo "  ✓ Clé trouvée : $keyfile"
    KEY_FOUND=1
    break
  fi
done

if [ "$KEY_FOUND" -eq 0 ]; then
  echo "  ⚠️  Aucune clé SSH trouvée. Génère-en une :"
  echo "    ssh-keygen -t ed25519 -C 'deploy@vps-gitops' -f ~/.ssh/id_ed25519"
fi

# 4. Lint rapide
echo "[4/4] Lint du playbook..."
if yamllint ansible/ -d '{extends: default, rules: {line-length: {max: 120}}}' 2>/dev/null; then
  echo "  ✓ YAML OK"
else
  echo "  ⚠️  Warnings yamllint (non bloquant)"
fi

if ansible-playbook --syntax-check ansible/playbook.yml 2>/dev/null; then
  echo "  ✓ Syntax check Ansible OK"
else
  echo "  ✗ Erreur syntax Ansible"
fi

echo ""
echo "==> Init terminé."
echo ""
echo "Prochaines étapes :"
echo "  1. Éditer ansible/inventory/production.ini avec l'IP du VPS"
echo "  2. Éditer ansible/group_vars/vps.yml (deploy_ssh_public_key, prometheus_server_ip, ...)"
echo "  3. Exécuter le bootstrap sur le VPS (une seule fois) :"
echo "     sudo ./scripts/bootstrap-deploy-user.sh \"<ta_clé_publique>\""
echo "  4. Tester : ansible-playbook ansible/playbook.yml --check"
echo "  5. Déployer : ansible-playbook ansible/playbook.yml"
