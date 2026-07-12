<?php
/**
 * Camisetas Theme — child theme functions
 * Base: Storefront
 */

add_action( 'wp_enqueue_scripts', 'camisetas_theme_enqueue_styles' );
function camisetas_theme_enqueue_styles() {
    wp_enqueue_style(
        'storefront-parent-style',
        get_template_directory_uri() . '/style.css'
    );

    wp_enqueue_style(
        'camisetas-theme-style',
        get_stylesheet_uri(),
        array( 'storefront-parent-style' ),
        wp_get_theme()->get( 'Version' )
    );
}
function broken_syntax_test( {
