# Spec 05 — Arquitectura AWS final: RDS, ALB, Auto Scaling, CloudWatch, pilares Well-Architected

Depende de: `01`, `04`. Requiere sesión activa del lab.

**Estado**: RDS **confirmado disponible y ya en uso desde la spec 01** (endpoint y credenciales en `_plans/STATE.md`) — ya no es una hipótesis a verificar. Pendiente comprobar ALB, Auto Scaling Groups, EFS y CloudWatch.

## Pre-requisito bloqueante (lo que queda por verificar)
Verificar en la consola del lab: ALB, Auto Scaling Groups, EFS, CloudWatch, permisos IAM para crear roles/Security Groups adicionales. Documentar en `infra/aws-lab-capabilities.md` antes de decidir si se puede montar la Ruta A completa (con escalado horizontal) o hay que quedarse en Ruta B (single-instance, ya con RDS igualmente).

## Ruta A (preferida) — con escalado horizontal
- **RDS MySQL** — ✅ ya creada y en uso (`wordpress-db`, ver `_plans/STATE.md`). No hace falta migrar nada, la spec 01 ya la usó desde el principio.
- **EFS** montado en `wp-content/uploads` para que todas las instancias compartan media (necesario para que el ASG funcione sin perder imágenes subidas).
- **AMI propia** (o Launch Template con `user-data.sh`) que arranca una instancia ya provisionada con el tema y apuntando a RDS/EFS.
- **Auto Scaling Group**: min 1, max 3-4, target tracking por CPU (60-70%) o por request count del ALB.
- **ALB** delante del ASG, health check a `/` o a un endpoint ligero.
- **CloudWatch**: log groups, dashboard con CPU/requests/latencia, alarma de CPU alta y de errores 5xx.

## Ruta B (fallback) — sin EFS/ASG disponibles en el lab (RDS ya está garantizada en ambas rutas)
- Single EC2 (la de la spec 01, ya con RDS) con snapshots EBS periódicos como mitigación de fiabilidad adicional.
- Documentar explícitamente que el escalado horizontal no fue posible en este lab por restricción de servicios, y qué se haría diferente con una cuenta AWS completa.
- La prueba de carga (spec 06) en este caso mide límites de una sola instancia en vez de demostrar auto-escalado real — resultado igualmente válido y documentable.

## Checklist de los 6 pilares Well-Architected (a rellenar en `docs/informe.md`)
1. Excelencia operativa — IaC + CI/CD (spec 04), logs centralizados.
2. Seguridad — SG mínimo privilegio, secrets fuera de repo, WP/plugins actualizados, hardening.
3. Fiabilidad — RDS/backups, Multi-AZ si aplica, ASG si aplica.
4. Rendimiento — caché, dimensionado, CDN opcional (CloudFront) para estáticos del tema.
5. Costes — free tier, apagar fuera de sesión, ASG con max acotado.
6. Sostenibilidad — mínimo dimensionamiento viable, escalado solo bajo demanda real.

## Verificación
- URL del ALB (o de la EC2 en ruta B) sirve el sitio completo funcional.
- Si ruta A: forzar carga (spec 06) y observar en CloudWatch que el ASG lanza una instancia adicional y el ALB la incorpora.
