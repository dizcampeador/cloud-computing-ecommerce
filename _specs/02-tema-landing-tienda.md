# Spec 02 — Tema custom: landing inspirada en CarlaGritte + estilos de tienda

Depende de: `01-wordpress-woocommerce-setup.md`.

## Objetivo
Landing page propia (no la del tema por defecto de WordPress) inspirada en la estética de `/Users/javierdizperez/Documents/CarlaGritte_Web/carlagritte` (paleta de color, tipografía, estructura de Navbar/Footer/Hero), pero solo con Home + Tienda — sin portfolio/about/booking. Reinterpretar el estilo, no copiar assets con derechos.

## Enfoque técnico
Child theme sobre un tema base ligero y compatible con WooCommerce (ej. Storefront o Astra, ambos gratis) para no reinventar los templates de tienda/carrito/checkout desde cero — solo se personaliza:
- `front-page.php` / plantilla de home: hero, sección de camisetas destacadas (query de productos WooCommerce), CTA a `/tienda`.
- `header.php`/`footer.php`: Navbar y Footer con la identidad visual adaptada de CarlaGritte.
- `style.css` / hoja de estilos propia: paleta de color, tipografía, espaciados.
- Ajustes mínimos de plantillas de WooCommerce (`archive-product.php`, `single-product.php`) solo si hace falta para que el mosaico y la ficha de producto encajen visualmente con el resto del sitio — usar los hooks de WooCommerce en vez de sobreescribir plantillas enteras cuando sea posible.

## Estructura
```
theme/camisetas-theme/
  style.css
  functions.php
  front-page.php
  header.php
  footer.php
  woocommerce/            # overrides puntuales de plantillas WC si son necesarios
  assets/
```

## Verificación
- Home muestra hero + destacados con la identidad visual propia, no el tema por defecto.
- Navegar Home → Tienda mantiene coherencia visual (misma Navbar/Footer).
- Ficha de producto y mosaico de tienda heredan la paleta/tipografía del tema custom.
