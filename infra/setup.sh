#!/usr/bin/env bash
# Provisioning script para EC2 Amazon Linux 2023 - WordPress + WooCommerce + nginx + php-fpm
# Reproduce el setup manual documentado en _plans/STATE.md, incluyendo los gotchas encontrados.
set -euo pipefail

DB_HOST="${DB_HOST:?Falta DB_HOST (endpoint RDS)}"
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:?Falta DB_USER}"
DB_PASSWORD="${DB_PASSWORD:?Falta DB_PASSWORD}"
WP_PATH="/var/www/wordpress"

sudo dnf update -y
sudo dnf install -y nginx php php-fpm php-mysqlnd php-gd php-mbstring php-xml php-curl php-zip wget unzip

# php.ini: memory_limit default (128M) no llega para `wp core download`
sudo sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php.ini

# php-fpm debe correr como nginx, no como el `apache` de fabrica, porque los
# ficheros de WordPress son propiedad de nginx (wp-cli se ejecuta `sudo -u nginx`).
# Si no se hace este cambio, la subida de media falla ("could not be moved to wp-content/uploads").
sudo sed -i 's/^user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = apache/group = nginx/' /etc/php-fpm.d/www.conf

sudo systemctl enable --now nginx
sudo systemctl enable --now php-fpm

# El server block default de nginx.conf de fabrica (server_name _; root /usr/share/nginx/html;)
# choca con conf.d/wordpress.conf (tambien server_name _;) y gana el, sirviendo "Welcome to nginx".
# Hay que borrarlo para que wordpress.conf tome efecto.
sudo python3 - <<'PYEOF'
import re
path = "/etc/nginx/nginx.conf"
with open(path) as f:
    content = f.read()
# elimina el primer bloque "server { ... }" de nivel http (el default de fabrica)
content = re.sub(r"\n\s*server\s*\{.*?\n\s*\}\n", "\n", content, count=1, flags=re.DOTALL)
with open(path, "w") as f:
    f.write(content)
PYEOF

sudo tee /etc/nginx/conf.d/wordpress.conf > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

sudo systemctl restart php-fpm
sudo systemctl restart nginx

# WP-CLI
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi

sudo mkdir -p "$WP_PATH"
sudo chown nginx:nginx "$WP_PATH"

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    sudo -u nginx wp core download --path="$WP_PATH"
    sudo -u nginx wp config create --path="$WP_PATH" \
        --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST"
fi

sudo -u nginx wp db check --path="$WP_PATH"

echo "Setup completado. Falta wp core install (via CLI o wizard web) si es una instalacion nueva."
