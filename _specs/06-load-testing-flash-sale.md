# Spec 06 — Prueba de carga: lanzamiento flash de camiseta exclusiva

Depende de: `05-aws-arquitectura-escalado.md` (entorno final desplegado).

## Objetivo
Simular el pico de tráfico de un "drop" de camiseta exclusiva por tiempo limitado y documentar cómo responde la arquitectura (escale o no, según la ruta A/B de la spec 05).

## Herramienta
k6 (open source, gratis).

## Escenario (`load-test/flash-sale.js`)
- Calentamiento: 10 VUs, 30s, navegación normal por la tienda.
- Pico: rampa a 200-500 VUs en 1 minuto (ajustar al límite razonable del lab), todos accediendo a la ficha del producto exclusivo y completando checkout.
- Sostenimiento: 2-3 minutos en el pico.
- Bajada: rampa a 0 en 1 minuto.
- Métricas: latencia p95/p99, tasa de error, throughput.

## Producto de prueba
- Camiseta "exclusiva" con stock limitado (ej. 50 unidades) para observar también si WooCommerce controla bien la concurrencia de stock bajo carga (overselling es un hallazgo válido a documentar, no algo que haya que arreglar en esta práctica).

## Ejecución
- Correr k6 contra la URL pública final (ALB o EC2).
- Capturar en paralelo, en CloudWatch: nº de instancias activas antes/durante/después (si ruta A), CPU, latencia.
- Guardar resultados en `load-test/results/`.

## Documento de resultados (`load-test/informe.md`)
- Escenario y parámetros usados.
- Capturas de CloudWatch mostrando el comportamiento durante el pico.
- Métricas de k6.
- Conclusión: ¿escaló a tiempo (si ruta A)?, errores 5xx durante el pico, overselling detectado o no, qué se mejoraría con más presupuesto/tiempo (ej. cuenta AWS completa en vez de lab).

## Verificación
- Reporte k6 generado sin errores de script.
- Al menos una captura de CloudWatch correlacionando el pico de tráfico con el comportamiento del sistema.
