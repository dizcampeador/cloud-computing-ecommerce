# Spec 04 — Repo git, ramas main/develop, GitHub Actions

Depende de: `01`, `02` (tema ya existe para poder desplegarlo).

## Ramas
- `main`: protegida (regla en GitHub: PR obligatorio, 1 check en verde mínimo antes de merge).
- `develop`: integración.
- `feature/*`: una por tarea, PR contra `develop`.

## Qué se versiona
- `theme/camisetas-theme/` (código del tema).
- `infra/` (scripts de provisión, `user-data.sh`, IaC si se añade Terraform/CloudFormation mínimo).
- `.github/workflows/`.
- Secrets (DB password, claves WP, IP/host del servidor, clave SSH de despliegue) van a GitHub Secrets, nunca al repo.

## `.github/workflows/ci.yml`
- Trigger: push y PR a cualquier rama.
- Job: lint básico de PHP del tema (`phpcs` con reglas de WordPress Coding Standards, o al menos `php -l` por archivo) + validación de sintaxis de los scripts bash (`bash -n`).

## `.github/workflows/cd-staging.yml`
- Trigger: push a `develop`.
- Pasos: `rsync`/`scp` del contenido de `theme/camisetas-theme/` a la ruta de temas de WordPress en el servidor (vía SSH con clave en secrets), luego `wp theme activate camisetas-theme` y `wp cache flush` remotos vía SSH/WP-CLI.
- Si solo hay una instancia disponible en el lab, desplegar a un entorno "staging" simulado (subdirectorio o sitio secundario) — documentar la limitación.

## `.github/workflows/cd-prod.yml`
- Trigger: push a `main`.
- Mismo mecanismo de despliegue que staging, apuntando al host de producción.
- `environment: production` en GitHub con regla de aprobación manual antes de correr el job.

## Verificación
- Un cambio en `theme/camisetas-theme/style.css` en una PR contra `develop`, al mergear, se refleja automáticamente en el sitio de staging sin tocar el servidor a mano.
- `ci.yml` falla si se introduce un error de sintaxis PHP deliberado (probar una vez para confirmar que el gate funciona).
