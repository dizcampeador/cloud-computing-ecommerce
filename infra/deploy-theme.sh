#!/usr/bin/env bash
# Despliegue del child theme via SSH: usado por cd-staging.yml y cd-prod.yml.
# Variables esperadas: SSH_HOST, SSH_KEY (ruta a fichero pem), WP_PATH (default /var/www/wordpress)
set -euo pipefail

SSH_HOST="${SSH_HOST:?Falta SSH_HOST}"
SSH_KEY="${SSH_KEY:?Falta SSH_KEY}"
SSH_USER="${SSH_USER:-ec2-user}"
WP_PATH="${WP_PATH:-/var/www/wordpress}"
THEME_DIR="theme/camisetas-theme"

rsync -az --delete -e "ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no" \
    "${THEME_DIR}/" "${SSH_USER}@${SSH_HOST}:/tmp/camisetas-theme/"

ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}" bash -s <<EOF
set -euo pipefail
sudo rsync -a --delete /tmp/camisetas-theme/ ${WP_PATH}/wp-content/themes/camisetas-theme/
sudo chown -R nginx:nginx ${WP_PATH}/wp-content/themes/camisetas-theme
sudo -u nginx wp theme activate camisetas-theme --path=${WP_PATH}
sudo -u nginx wp cache flush --path=${WP_PATH}
EOF

echo "Deploy completado en ${SSH_HOST}."
