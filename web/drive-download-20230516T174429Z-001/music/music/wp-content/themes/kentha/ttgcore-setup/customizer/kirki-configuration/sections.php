<?php  
/**
 * Create sections using the WordPress Customizer API.
 * @package Kirki
 */
if(!function_exists('qantumthemes_kirki_sections')){
function qantumthemes_kirki_sections( $wp_customize ) {

	$wp_customize->add_section( 'kentha_global_settings', array(
		'title'       => esc_html__( 'Global settings', "kentha" ),
		'priority'    => 0
	));
	$wp_customize->add_section( 'kentha_header_section', array(
		'title'       => esc_html__( 'Header and menu style', "kentha" ),
		'priority'    => 40
	));
	$wp_customize->add_section( 'kentha_website_bg_section', array(
		'title'       => esc_html__( 'Website background', "kentha" ),
		'priority'    => 40
	));
	$wp_customize->add_section( 'kentha_bottomlayer_section', array(
		'title'       => esc_html__( 'Second layer', "kentha" ),
		'priority'    => 40
	));
	$wp_customize->add_section( 'kentha_colors_section', array(
		'title'       => esc_html__( 'Colors customization', "kentha" ),
		'priority'    => 50,
		'description' => esc_html__( 'Colors of your website', "kentha" ),
	));
	





	/**
	 * Player settings with sub panel ============================================================
	 */
	$wp_customize->add_panel( 'kentha_player_panel', array(
		'title'       => esc_html__( 'Player settings', "kentha" ),
		'priority'    => 60
	));
		$wp_customize->add_section( 'kentha_player_products', array(
		  	'title'       => __( 'Products settings', 'kentha' ),
		   'description' => __( 'Manage products in player', 'kentha' ),
		   'panel'          => 'kentha_player_panel', // Not typically needed.
		   'priority'       => 0,
		));
		$wp_customize->add_section( 'kentha_player_albums', array(
		  	'title'       => __( 'Album settings', 'kentha' ),
		   'description' => __( 'Manage albums in player', 'kentha' ),
		   'panel'          => 'kentha_player_panel', // Not typically needed.
		   'priority'       => 0,
		));
		$wp_customize->add_section( 'kentha_player_podcasts', array(
		  	'title'       => __( 'Podcast settings', 'kentha' ),
		   'description' => __( 'Manage podcasts in player', 'kentha' ),
		   'panel'          => 'kentha_player_panel', // Not typically needed.
		   'priority'       => 0,
		));
		$wp_customize->add_section( 'kentha_player_playlist', array(
		  	'title'       => __( 'Custom playlist', 'kentha' ),
		   'description' => __( 'Create a custom playlist or the player', 'kentha' ),
		   'panel'          => 'kentha_player_panel', // Not typically needed.
		   'priority'       => 0,
		));



	$wp_customize->add_section( 'kentha_typography', array(
		'title'       => esc_html__( 'Typography', "kentha" ),
		'priority'    => 100,
		'description' => esc_html__( 'Customize font settings', "kentha" ),
	));
	$wp_customize->add_section( 'kentha_social_section', array(
		'title'       => esc_html__( 'Social networks', "kentha" ),
		'priority'    => 101,
		'description' => esc_html__( 'Social network profiles', "kentha" ),
	));
	$wp_customize->add_section( 'kentha_footer_section', array(
		'title'       => esc_html__( 'Footer Customization', "kentha" ),
		'priority'    => 102,
		'description' => esc_html__( 'Footer text and functions', "kentha" ),
	));
	
	$wp_customize->add_section( 'kentha_woocommerce', array(
		'title'       => esc_html__( 'WooCommerce Design', "kentha" ),
		'priority'    => 199,
		'description' => esc_html__( 'WooCommerce design settings', "kentha" ),
	));

	
}}
add_action( 'customize_register', 'qantumthemes_kirki_sections' );
