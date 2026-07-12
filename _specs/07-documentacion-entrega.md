# Spec 07 — Documentación final de entrega

Depende de: todas las anteriores (se hace al final, o incrementalmente recogiendo capturas durante cada spec).

## Objetivo
Producir el entregable formal pedido por el enunciado: PDF (Calibri 12, interlineado 1.5) con diagrama, capturas, documentación de pasos y problemas encontrados, y URL de la instancia si quedan créditos.

## Contenido del informe (`docs/informe.md` → exportar a PDF)
1. Introducción y objetivos.
2. Diagrama de arquitectura final (`infra/architecture-diagram.png`, reflejando ruta A o B de la spec 05).
3. Pasos seguidos, en orden, con las capturas de cada spec (01 a 06) referenciadas.
4. Problemas encontrados y cómo se resolvieron (incluyendo limitaciones del lab si aplica: sin RDS/ASG/EFS, sin dominio/HTTPS, etc.).
5. Checklist de los 6 pilares del AWS Well-Architected Framework con la justificación de cada uno (copiar de spec 05).
6. Resultados de la prueba de carga (resumen de spec 06).
7. Conclusiones y qué se haría diferente con una cuenta AWS completa.
8. URL de la instancia/ALB (mientras dure la sesión del lab).

## Formato
- Convertir `docs/informe.md` a PDF respetando Calibri 12 pt, interlineado 1.5 (usar Word/LibreOffice o un conversor Markdown→PDF con esa plantilla de estilos).

## Verificación
- PDF final generado, revisar que todas las capturas referenciadas están incluidas y legibles.
- Word count mínimo por sección cumplido según lo indicado en el enunciado (revisar `cloud_computing_cprac2.docx` para el mínimo exacto de palabras por sección si el documento lo detalla más allá de lo ya extraído).
