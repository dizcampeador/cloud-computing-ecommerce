# Estado actual — retomar aquí tras /clear

Última actualización: 2026-07-12. Este archivo es la fuente de verdad de "dónde estamos" — léelo primero en cualquier conversación nueva antes de tocar nada.

## Decisión de arquitectura confirmada
RDS **sí está disponible** en el lab (se creó sin problema con rol `voclabs`). Se descarta la "Ruta B" (DB local) como plan principal — la spec `05-aws-arquitectura-escalado.md` usa RDS como confirmado, no como hipótesis. Sigue pendiente verificar ALB/Auto Scaling Group/EFS/CloudWatch (aún no probados).

## Recursos AWS ya creados
- **EC2**: Amazon Linux 2023, t2.micro/t3.micro, key pair `vockey` (archivo local `labsuser.pem`, **no** `vockey.pem` — así es como AWS Academy nombra el descargable).
- **Elastic IP asociada**: `32.198.153.43`
- **Security Group EC2**: SSH(22)→My IP (⚠️ hay que reactualizar el source cada vez que cambies de red, o cambiar a 0.0.0.0/0 temporalmente durante desarrollo y restringir antes de entregar), HTTP(80) y HTTPS(443)→0.0.0.0/0.
- **RDS MySQL**: identifier `wordpress-db`, endpoint `wordpress-db.ck5gx4oroibf.us-east-1.rds.amazonaws.com`, usuario master `wpadmin`, Public access = No, conecta solo desde el SG de la EC2 (puerto 3306). Base de datos `wordpress` ya creada dentro.

## Software instalado en la EC2 (real, difiere ligeramente de lo planeado originalmente)
```bash
sudo dnf update -y
sudo dnf install -y nginx php php-fpm php-mysqlnd php-gd php-mbstring php-xml php-curl php-zip wget unzip
# NO se instaló mariadb-server (la DB vive en RDS). El cliente `mysql`/`mariadb` ya venía disponible.
sudo systemctl enable --now nginx
sudo systemctl enable --now php-fpm
```
- WP-CLI instalado en `/usr/local/bin/wp` (vía `wp-cli.phar` desde GitHub releases).
- `php.ini` con `memory_limit` subido a `256M` (el default 128M no llega para `wp core download`, revienta con "Allowed memory size exhausted"). **Aplicar esto también en `infra/setup.sh` cuando se escriba el script final**, si no el despliegue reproducible fallará igual.

## Nginx — gotcha importante
El `nginx.conf` de fábrica de Amazon Linux 2023 trae un server block default (`server_name _; root /usr/share/nginx/html;`) que choca con nuestro `conf.d/wordpress.conf` (también `server_name _;`) y gana él, sirviendo la página "Welcome to nginx" en vez de WordPress. **Hubo que borrar ese bloque default de `/etc/nginx/nginx.conf`** para que `wordpress.conf` tomara efecto. Recordar documentar esto en `infra/setup.sh` (o usar `server_name` específico en vez de `_` para evitar el choque desde el principio la próxima vez).

`wordpress.conf` final en `/etc/nginx/conf.d/wordpress.conf`:
```nginx
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
```

## WordPress — progreso
- `wp core download --path=/var/www/wordpress` → hecho (WordPress 7.0.1), ejecutado como `sudo -u nginx` (no root) para que el propietario de los archivos sea `nginx` desde el principio.
- `wp config create` con `--dbhost=wordpress-db.ck5gx4oroibf.us-east-1.rds.amazonaws.com` → hecho.
- `wp db check` → "Success: Database checks passed."
- `wp core install` → **completado, vía wizard web** (no CLI) el 2026-07-12. Sitio carga en `http://32.198.153.43` y login en `/wp-admin` funciona.

- WooCommerce instalado y activado vía CLI (`wp plugin install woocommerce --activate`), versión 10.9.4. Config básica hecha por CLI (no wizard web): país ES, moneda EUR, separadores decimales estilo español (`,` decimal, `.` miles).

- Atributo global "Talla" (S/M/L/XL) creado y 6-8 productos camiseta variables cargados con imágenes, vía panel `/wp-admin`.
- **Gotcha encontrado**: subida de imágenes fallaba ("The uploaded file could not be moved to wp-content/uploads/...") porque PHP-FPM corría como usuario `apache` (default de `/etc/php-fpm.d/www.conf`) mientras los archivos de WordPress son propiedad de `nginx` (todo se ejecutó `sudo -u nginx` desde el principio). Fix: cambiar `user = nginx` / `group = nginx` en `/etc/php-fpm.d/www.conf` y `systemctl restart php-fpm`. **Aplicar esto también en `infra/setup.sh`** cuando se escriba, junto al resto de gotchas de nginx/php ya documentados.

- **Spec 01 completada**: WordPress + WooCommerce + 6-8 camisetas cargadas, verificado en `/tienda`.

## Spec 02 (tema custom) — completada
- Child theme `camisetas-theme` sobre **Storefront** (tema padre, instalado vía `wp theme install storefront`). Archivos en el repo local: `theme/camisetas-theme/` (`style.css`, `functions.php`, `front-page.php`).
- Estética reinterpretada de `/Users/javierdizperez/Documents/CarlaGritte_Web/carlagritte` (ver su `DESIGN.md` para el design system original): paleta oscura (`#0d0d0d` bg, `#f0ead6` parchment, acento dorado `#b8975a` recalculado, `#5c1a1a` burgundy), botones "ink-fill" con hover de relleno, hero + sección destacados en home.
- **Fuentes NO copiadas** (las de CarlaGritte son custom `.ttf`/`.otf` con derechos) — sustituidas por Google Fonts libres equivalentes: Playfair Display (heading) + Work Sans (body).
- Decisión de diseño: **no se sobreescriben `header.php`/`footer.php`** de Storefront (para no romper hooks de WooCommerce) — navbar/footer se restylean solo vía CSS, mismo resultado visual con menos riesgo.
- Deploy manual: `scp -r theme/camisetas-theme` a `/tmp/` en la EC2 → `mv` a `wp-content/themes/` → `chown nginx:nginx` → `wp theme activate camisetas-theme`.
- Verificado: `wp theme list` muestra `camisetas-theme` activo, home se ve con la nueva paleta.

## Spec 02 — verificación visual completada (2026-07-12)
- `/shop` y ficha de producto (ej. `/product/mechanical-extinction/`) heredan bien la paleta/tipografía del tema custom.
- **Nota de slug**: la tienda vive en `/shop/`, no `/tienda` (WooCommerce usa el slug en inglés por defecto). Decisión: **se deja `/shop`**, no se cambia el slug. Usar `/shop` en toda la documentación/specs a partir de ahora.
- Solo 3 productos cargados (no 6-8 como se apuntó antes) — **es intencional**, no bug.

## Acceso SSH — gotcha resuelto (2026-07-12)
`~/Downloads/labsuser.pem` estaba desactualizado (AWS Academy rotó la key en algún reinicio de lab). La key que **sí funciona** con la EC2 ya creada: `/Users/javierdizperez/Documents/Curso Cloud Computing/Actividades/Caso Practico 2/labsuser.pem`. Usar esa ruta para SSH/SCP (`ssh -i "<esa ruta>" ec2-user@32.198.153.43`). wp-cli se ejecuta como `sudo -u nginx wp --path=/var/www/wordpress ...` (archivos son propiedad de `nginx`).

## Spec 03 (checkout sin pago + cuentas) — completada (2026-07-12)
- Único método de pago activo: **Cheque** renombrado a "Pedido sin pago online — confirmación manual", con descripción/instrucciones explicando que no hay cobro real. BACS, COD y PayPal quedan desactivados explícitamente.
- Cuentas: registro habilitado en Mi cuenta, **checkout de invitado desactivado** (`woocommerce_enable_guest_checkout=no`) — cuenta obligatoria para que el historial de pedidos tenga sentido, como recomendaba la spec.
- **Gotcha encontrado y corregido**: el sitio estaba en modo **"Coming Soon"** de WooCommerce (`woocommerce_coming_soon`), invisible para visitantes no logueados — cualquier verificación end-to-end anónima fallaba. Se desactivó (`option update woocommerce_coming_soon no`). Confirmar que siga desactivado antes de la entrega final.
- Verificación end-to-end hecha con cuenta de prueba (`testuser-e2e@example.com`): registro → añadir camiseta al carrito → checkout con datos de envío → pedido confirmado sin pago. Pedido **#29** queda en estado `on-hold`, total 30,00€, visible en "Mi cuenta → Pedidos" y confirmado en la tabla `wp_wc_orders` (WooCommerce usa HPOS — pedidos NO están en `wp_posts`, están en `wp_wc_orders`/`wp_wc_orders_meta`).
- **Nota aparte**: el producto "Mechanical Extinction" (y aparentemente los otros 2) es un producto **simple**, no variable — no muestra selector de Talla, aunque STATE.md anotaba antes que había productos variables con atributo Talla. Pendiente de revisar si es intencional o se perdió la config de variaciones.

## Próximo paso inmediato al retomar
Seguir con spec 04 (git/CI-CD) → 05 (arquitectura final: verificar ALB/ASG/EFS/CloudWatch) → 06 (load test) → 07 (informe PDF).

## Credenciales (no van en git, apuntadas aquí solo como recordatorio de que existen)
- Password root MySQL local: N/A (no se usa, DB es RDS).
- Password RDS `wpadmin`: la que pusiste al crear la RDS — guárdala en un gestor de contraseñas, no en el repo.
- Usuario/password admin de WordPress: los que pusiste en `wp core install` — igual, no en el repo.
- Guardar todas estas en un `.env` local o gestor de secretos, nunca commitear.
