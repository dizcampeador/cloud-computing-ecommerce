# Plan: Ecommerce camisetas con WordPress + WooCommerce en AWS

Fecha: 2026-07-11 (revisado, unificado en un único proyecto)
Estado: aprobado, en ejecución

## 1. Qué es WordPress y por qué encaja aquí

WordPress no es solo "el frontal": es un CMS completo con tres piezas—
- **Backend/servidor**: PHP + base de datos MySQL/MariaDB, gestiona todo el estado (productos, pedidos, usuarios).
- **Tema**: la capa visual (HTML/CSS/PHP templates) — aquí se hace la landing inspirada en CarlaGritte.
- **Plugins**: lógica de negocio. **WooCommerce** es el plugin de ecommerce: da de serie mosaico de tienda, ficha de producto con variantes (tallas), carrito, checkout, cuentas de usuario (login/registro) e historial de pedidos. No hace falta programar nada de eso a mano.

Por tanto: no hay React ni FastAPI ni Postgres. Un único proyecto real, que además es exactamente lo que pide el enunciado (`cloud_computing_cprac2.docx`): desplegar WordPress en AWS siguiendo el AWS Well-Architected Framework.

## 2. Alcance funcional (todo vía WordPress + WooCommerce)

- Landing page (tema custom, inspirado en la estética de `CarlaGritte_Web/carlagritte`: hero, sección destacados, CTA a tienda — sin las vistas de portfolio/about/booking, solo home + tienda).
- Tienda en mosaico de camisetas (página de tienda de WooCommerce, tema propio).
- Ficha de producto: detalle, selección de talla (atributo/variación de WooCommerce), añadir al carrito.
- Carrito: añadir/quitar/modificar cantidades (nativo de WooCommerce).
- Checkout: datos de envío (nombre, dirección, etc.), **sin pasarela de pago** — método de pago "Contra reembolso" / "Transferencia manual" configurado para que el pedido quede en estado `pending`/`on-hold` sin cobrar nada online.
- Confirmación de pedido tras checkout (nativo de WooCommerce).
- Cuenta de usuario: login, registro, "Mis pedidos" con historial (nativo de WooCommerce/My Account).

## 3. Arquitectura AWS

**Estado de ejecución y detalle día a día: ver `_plans/STATE.md` (léelo primero al retomar tras un /clear).**

- EC2 (Amazon Linux 2023, t3.micro/t2.micro) con Nginx + PHP-FPM + WordPress. ✅ desplegado.
- Base de datos: **RDS MySQL confirmado disponible en el lab y ya en uso** (no hizo falta fallback a DB local). ✅ creada y conectada.
- Elastic IP para URL estable durante la sesión. ✅ asociada (`32.198.153.43`).
- Security Group mínimo: 22 (SSH restringido a IP propia), 80/443 abiertos.
- Auto Scaling Group + ALB para el pico de carga (spec de escalado): esto requiere que WordPress sea "stateless" entre instancias — sesiones/carrito en DB compartida (RDS) y `wp-content/uploads` en almacenamiento compartido (EFS) o, si el lab no da EFS, aceptar single-instance con auto-recovery como fallback documentado.
- CloudWatch: métricas de CPU/requests, alarmas, logs.
- Backups: snapshot EBS/RDS.

## 4. Pilares Well-Architected — cómo se cubre cada uno

1. **Excelencia operativa**: todo el setup vía scripts (`infra/setup.sh`, user-data), versionado en git, cambios de tema/plugins vía CI/CD (no a mano en producción tras el setup inicial).
2. **Seguridad**: SG mínimo privilegio, `wp-config.php` con claves únicas y secrets fuera de git, usuario admin no genérico, plugin de seguridad (Wordfence), HTTPS si hay dominio/cert disponible en el lab, permisos de archivos WP endurecidos.
3. **Fiabilidad**: RDS (o snapshots EBS si no hay RDS), Multi-AZ si el lab lo permite, Auto Scaling Group para tolerar fallo de instancia.
4. **Eficiencia de rendimiento**: plugin de caché (WP Super Cache/W3TC), CDN opcional (CloudFront) para estáticos, dimensionado mínimo viable con capacidad de escalar bajo demanda.
5. **Optimización de costes**: free tier/créditos del lab, apagar recursos fuera de sesión, Auto Scaling con min bajo (1) y max acotado (3-4).
6. **Sostenibilidad**: instancias mínimas necesarias, escalado solo bajo demanda real (no sobreaprovisionar).

## 5. Ramas y CI/CD (aplican al código versionable: tema, plugins custom si los hay, scripts de infra)

- `main`: protegida, refleja producción.
- `develop`: integración.
- `feature/*`: trabajo puntual, PR contra `develop`.
- GitHub Actions:
  - `ci.yml`: valida el tema (PHP lint / phpcs si se añade), valida sintaxis de scripts de infra, en push/PR.
  - `cd-staging.yml`: en merge a `develop`, despliega tema/config a una instancia de staging (o a la misma instancia en un directorio de staging si el lab solo da recursos para una).
  - `cd-prod.yml`: en merge a `main`, despliega a producción (rsync/scp del tema + activación de plugins vía WP-CLI por SSH), con aprobación manual.

No hay "build" de imágenes Docker aquí (WordPress no lo necesita para este alcance) — el pipeline despliega archivos de tema/config a la instancia EC2 vía WP-CLI/SSH, no contenedores. Si más adelante se quiere containerizar WordPress (imagen `wordpress:php8.2-fpm` + Nginx), es una mejora futura, no parte de este plan.

## 6. Prueba de carga (lanzamiento flash de camiseta exclusiva)

- Herramienta: k6 (gratis, open source).
- Escenario: pico de cientos de usuarios virtuales golpeando la ficha de producto exclusivo + flujo de compra completo en pocos minutos.
- Validar que el Auto Scaling Group lanza instancias adicionales y que el ALB reparte carga; capturar métricas en CloudWatch antes/durante/después.
- Documentar resultado: si escaló a tiempo, tasa de error durante el pico, si hubo overselling de stock (limitación conocida de WooCommerce bajo alta concurrencia sin locks adicionales — documentar como hallazgo, no bug a resolver en esta práctica).

## 7. Estructura de repo

```
infra/
  setup.sh                # provisión inicial EC2 (LAMP/LEMP + WP + WP-CLI)
  user-data.sh             # para Auto Scaling Group / Launch Template
  aws-lab-capabilities.md  # checklist de servicios confirmados en el lab
  architecture-diagram.png
theme/
  camisetas-theme/          # tema (o child theme) para landing + tienda
.github/workflows/
  ci.yml
  cd-staging.yml
  cd-prod.yml
load-test/
  flash-sale.js
  results/
docs/
  informe.md                # fuente del PDF final de la práctica
  screenshots/
```

## 8. Orden de ejecución

1. `01-wordpress-woocommerce-setup.md` — EC2 + WordPress + WooCommerce funcionando, productos camisetas cargados.
2. `02-tema-landing-tienda.md` — tema custom (landing inspirada en CarlaGritte + estilos de tienda).
3. `03-checkout-cuentas-pedidos.md` — configurar checkout sin pago, cuentas de usuario, historial.
4. `04-infra-branching-cicd.md` — repo git, ramas, GitHub Actions de despliegue.
5. `05-aws-arquitectura-escalado.md` — RDS/EFS/ALB/ASG/CloudWatch, aplicar los 6 pilares.
6. `06-load-testing-flash-sale.md` — prueba de carga y documentación de resultados.
7. `07-documentacion-entrega.md` — diagrama final, capturas, informe PDF (Calibri 12, interlineado 1.5).

## 9. Riesgos / verificar con el lab abierto

- Qué servicios están realmente disponibles en "AWS Academy Lab Project - Microservices and CI/CD Pipeline Builder" (RDS, ALB, Auto Scaling, EFS, CloudWatch, permisos IAM para crear roles/SG).
- Duración de sesión del lab (se resetea) → todo debe ser reproducible rápido desde `infra/setup.sh`/`user-data.sh`.
- Sin dominio propio fiable y gratis → usar IP pública/DNS del ALB, HTTPS solo si el lab permite ACM.
