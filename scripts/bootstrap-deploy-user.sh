#!/usr/bin/env bash
set -euo pipefail

# Bootstrap minimal à exécuter UNE FOIS sur le VPS (en root ou via sudo).
# Usage: sudo ./bootstrap-deploy-user.sh "ssh-ed25519 AAAA... commentaire"

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

usermod -aG sudo "$DEPLOY_USER"
echo "$DEPLOY_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-"$DEPLOY_USER"
chmod 440 /etc/sudoers.d/90-"$DEPLOY_USER"

install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
echo "$PUBKEY" >> "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"

SSHD="/etc/ssh/sshd_config"
cp -a "$SSHD" "$SSHD.bak.$(date +%Y%m%d%H%M%S)"

grep -q '^PasswordAuthentication' "$SSHD" && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD" || echo 'PasswordAuthentication no' >> "$SSHD"
grep -q '^PermitRootLogin' "$SSHD" && sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD" || echo 'PermitRootLogin no' >> "$SSHD"
grep -q '^PubkeyAuthentication' "$SSHD" && sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD" || echo 'PubkeyAuthentication yes' >> "$SSHD"

systemctl restart ssh || systemctl restart sshd

echo "OK: user '$DEPLOY_USER' prêt, root ssh désactivé, password auth off."
