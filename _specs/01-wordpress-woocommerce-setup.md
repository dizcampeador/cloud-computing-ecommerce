# Spec 01 — EC2 + WordPress + WooCommerce funcionando

Depende de: sesión activa del AWS Academy Lab. Base de todas las demás specs.

**Estado**: puntos 1 y 2 completados (ver `_plans/STATE.md` para detalle de recursos creados, comandos reales ejecutados y gotchas). Pendiente: confirmar `wp core install` en navegador, y puntos 3-4 (WooCommerce + productos).

## Objetivo
Tener WordPress instalado en EC2, con base de datos en RDS, WooCommerce activo y camisetas cargadas como productos, accesible por URL pública.

## Pasos

### 1. Lanzar EC2 — ✅ hecho
- AMI Amazon Linux 2023, t2.micro/t3.micro, key pair `vockey` (archivo `labsuser.pem`).
- Security Group: SSH (22) → My IP (actualizar si cambias de red), HTTP (80) y HTTPS (443) → 0.0.0.0/0.
- Elastic IP asociada: `32.198.153.43`.

### 2. Provisionar stack — ✅ hecho (con RDS, no DB local)
Decisión tomada durante la ejecución: usar **RDS MySQL** en vez de MariaDB local, para tener una arquitectura más rica de cara al informe Well-Architected (ver spec 05). Comandos reales (ver `_plans/STATE.md` para el detalle completo y los gotchas encontrados — memory_limit de PHP CLI insuficiente, conflicto de server block default en Nginx):

```bash
sudo dnf update -y
sudo dnf install -y nginx php php-fpm php-mysqlnd php-gd php-mbstring php-xml php-curl php-zip wget unzip
sudo systemctl enable --now nginx
sudo systemctl enable --now php-fpm
```

RDS creada aparte en consola (MySQL, free tier, `Public access = No`, SG restringido al SG de la EC2 en puerto 3306). Endpoint y credenciales en `_plans/STATE.md`.

Nginx configurado en `/etc/nginx/conf.d/wordpress.conf` sirviendo `/var/www/wordpress` (contenido exacto en `_plans/STATE.md`) — **importante**: hubo que eliminar el server block default de `/etc/nginx/nginx.conf` porque chocaba (`server_name _;` duplicado) y ganaba él, sirviendo la página de bienvenida de Nginx en vez de WordPress.

WP-CLI instalado en `/usr/local/bin/wp`. `php.ini` con `memory_limit = 256M` (el default 128M no basta para `wp core download`).

Ejecutado como usuario `nginx` (no root) desde el principio:
```bash
sudo -u nginx wp core download --path=/var/www/wordpress --allow-root
sudo -u nginx wp config create --dbname=wordpress --dbuser=wpadmin --dbpass='...' \
  --dbhost=wordpress-db.ck5gx4oroibf.us-east-1.rds.amazonaws.com \
  --path=/var/www/wordpress --allow-root
sudo -u nginx wp db check --path=/var/www/wordpress --allow-root   # Success
sudo -u nginx wp core install --path=/var/www/wordpress \
  --url="http://32.198.153.43" --title="Camisetas Store" \
  --admin_user="..." --admin_password="..." --admin_email="..." --allow-root
```

**Pendiente al retomar**: verificar en navegador que `http://32.198.153.43` carga el sitio y `http://32.198.153.43/wp-admin` permite login.

### 3. Instalar y activar WooCommerce — pendiente
```bash
sudo -u nginx wp plugin install woocommerce --activate --path=/var/www/wordpress --allow-root
```
- Correr el wizard de configuración (vía navegador, en `/wp-admin`): moneda EUR, país España, tipo de producto físico.
- Alternativa por WP-CLI si el wizard da problemas: `wp option update woocommerce_currency EUR --path=/var/www/wordpress --allow-root`, etc.

### 4. Cargar productos "camiseta" — pendiente
- Crear atributo global "Talla" (S/M/L/XL) desde WooCommerce → Productos → Atributos (vía panel, más simple que WP-CLI para esto).
- Crear 6-8 productos camiseta, cada uno como producto variable con variaciones por talla y stock por variación.
- Imágenes de producto (placeholder libres de derechos).

### 5. Verificación
- `http://32.198.153.43` muestra WordPress activo.
- `/tienda` (o `/shop`) lista los productos con mosaico por defecto de WooCommerce.
- Panel de administración accesible con usuario admin no genérico y contraseña fuerte.

## Entregables
- `infra/setup.sh` (a escribir al final, consolidando todos los comandos reales de este documento y de `_plans/STATE.md` en un script idempotente — pendiente).
- Capturas: instancia EC2 corriendo, RDS "Available", `wp core install` exitoso, sitio en navegador, WooCommerce activo, listado de productos.
