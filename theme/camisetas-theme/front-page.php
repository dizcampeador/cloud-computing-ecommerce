<?php
/**
 * Front page template — hero + destacados + CTA a la tienda
 */

get_header(); ?>

<main id="main" class="site-main camisetas-front">

    <section class="camisetas-hero">
        <h1><?php bloginfo( 'name' ); ?></h1>
        <?php $tagline = get_bloginfo( 'description' ); ?>
        <p><?php echo esc_html( $tagline ? $tagline : __( 'Camisetas con carácter, hechas para durar.', 'camisetas-theme' ) ); ?></p>
        <a class="button" href="<?php echo esc_url( get_permalink( wc_get_page_id( 'shop' ) ) ); ?>">
            <?php esc_html_e( 'Ver la tienda', 'camisetas-theme' ); ?>
        </a>
    </section>

    <section class="camisetas-featured">
        <h2><?php esc_html_e( 'Destacadas', 'camisetas-theme' ); ?></h2>
        <?php echo do_shortcode( '[products limit="4" columns="4" orderby="date" order="DESC"]' ); ?>
    </section>

</main>

<?php get_footer(); ?>
