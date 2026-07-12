#!/usr/bin/env bash
# Despliegue local del child theme: usado por el runner self-hosted que vive
# en la propia EC2 (unica instancia del lab, ver STATE.md). Sustituye al
# despliegue via SSH remoto (infra/deploy-theme.sh) porque no hace falta
# saltar de host: el runner de GitHub Actions ya corre sobre el servidor.
set -euo pipefail

WP_PATH="${WP_PATH:-/var/www/wordpress}"
THEME_DIR="theme/camisetas-theme"

sudo rsync -a --delete "${THEME_DIR}/" "${WP_PATH}/wp-content/themes/camisetas-theme/"
sudo chown -R nginx:nginx "${WP_PATH}/wp-content/themes/camisetas-theme"
sudo -u nginx wp theme activate camisetas-theme --path="${WP_PATH}"
sudo -u nginx wp cache flush --path="${WP_PATH}"

echo "Deploy local completado."
