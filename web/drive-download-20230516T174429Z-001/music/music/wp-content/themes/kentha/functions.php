<?php
/**
 *	@package    kentha
 *	@author 	QantumThemes
 */


/**==========================================================================================
 *
 *
 *	QantumThemes Warranty Notice:
 * 	Theme's support doesn't cover any code customizations. You are free to edit any theme's code at your own risk.
 *  For any customization please use the provided child theme instead of editing core files.
 *  https://codex.wordpress.org/Child_Themes
 *
 *
 * 	IMPORTANT: JAVASCRIPT LIBRARIES INFO
 * 	This theme optionally loads by default a minified javascript containing all the theme libraries, 
 * 	for a massive performance improvement. 
 * 	If you want to use the separate non minified files, enable "debugger" in Appearance > Customize.
 * 	You find the list of scripts in the readme.txt
 * 	
 * 
 ==========================================================================================*/


/* Theme version definition to prevent caching of old files
============================================= */
update_option('kentha_product_id','21048750');
update_option('kentha_ack_21048750','AXlKd1kyOWtaU0k2SWpFd01tVTNNbU16TFdVeE5HTXROREptTXkxaFpHWTBMV0V6T0RCaE9HVTFNbVZsT1NJc0luVnliQ0k2SW14dlkyRnNhRzl6ZENJc0luQnliMlJwWkNJNk1qRXhORGc0TlRDOQ==');


if(!function_exists('kentha_theme_version')){
	function kentha_theme_version(){
		$style_parent_theme = wp_get_theme(get_template());
		return $style_parent_theme->get( 'Version' );
	}
}

/* Global function to get terms
============================================= */
if(!function_exists('kentha_get_terms_array')) {
function kentha_get_terms_array( ) {
	$cats = get_terms(array(
		'hide_empty'=>false,
	));
	$result = array();
	if(is_wp_error( $cats ) || 0 === $cats){
		$result = array();
	}
	$current_taxonomy = '';
	foreach ( $cats as $cat )	{
		if( $cat->taxonomy == 'nav_menu'){
			continue;
		}
		$result[] = array(
			'value' => $cat->taxonomy.':'.$cat->slug,
			'label' => '['. str_replace('_', ' ', $cat->taxonomy) .'] <strong>'.$cat->name.'</strong>',
		);
	}
	return $result;
}}

// TGM Plugins Activation
locate_template( '/inc/tgm-plugin-activation/kentha-plugins-activation.php', true, true );

// One Click Installer
locate_template( '/inc/ocdi/ocdi-setup.php', true, true );


/* WooCommerce helpers functions
============================================= */
if ( class_exists( 'WooCommerce' ) ) {
	require_once get_template_directory() . '/woocommerce-helpers/woocommerce-helpers.php';
	require_once get_template_directory() . '/woocommerce-helpers/custom-product-fields.php';
	require_once get_template_directory() . '/woocommerce-helpers/kentha-woocommerce-software-icon.php';
	require_once get_template_directory() . '/woocommerce-helpers/kentha-woocommerce-trackdata.php';
	require_once get_template_directory() . '/woocommerce-helpers/kentha-woocommerce-productplay.php';
	require_once get_template_directory() . '/woocommerce-helpers/kentha-woocommerce-moreinfo.php';
	require_once get_template_directory() . '/woocommerce-helpers/kentha-woocommerce-bodyclass.php';
}

/* Content Width
============================================= */
if (!isset( $content_width ) ) { 
	$content_width = 1170; 
}

/* QT Socicons list [This is a configuration list used by Theme Core plugin]
=============================================*/
if(!function_exists('kentha_qt_socicons_array')){
function kentha_qt_socicons_array(){
	return array(
		'android' 			=> 'Android',
		'amazon' 			=> 'Amazon',
		'beatport' 			=> 'Beatport',

		'blogger' 			=> 'Blogger',


		'facebook' 			=> 'Facebook',
		'flickr' 			=> 'Flickr',
		// 'googleplus' 		=> 'Googleplus', // dead
		'instagram' 		=> 'Instagram',
		'itunes' 			=> 'Itunes',
		'juno' 				=> 'Juno',
		'kuvo' 				=> 'Kuvo',

		'linkedin' 				=> 'Linkedin',


		'trackitdown' 		=> 'Trackitdown',
		'spotify' 			=> 'Spotify',
		'soundcloud' 		=> 'Soundcloud',
		'snapchat' 			=> 'Snapchat',

		'skype' 			=> 'Skype',


		'reverbnation' 		=> 'Reverbnation',
		'residentadvisor' 	=> 'Resident Advisor',
		'pinterest' 		=> 'Pinterest',
		'myspace' 			=> 'Myspace',
		'mixcloud' 			=> 'Mixcloud',

		'rss' 			=> 'RSS',


		'twitter' 			=> 'Twitter',
		'vimeo' 			=> 'Vimeo',
		'vk' 				=> 'VK.com',
		'youtube' 			=> 'YouTube',

		'whatsapp' 			=> 'Whatsapp',


	);
}}


/* TGM Plugins Activation
============================================= */
// require_once get_template_directory() . '/tgm-plugin-activation/kentha-plugins-activation.php';
// require_once get_template_directory() . '/t2g-connector-client/kentha-t2gconnectorclient-config.php';


/**
 *
 *	TTG Theme Core setup
 * 	For custom types fields and appearance customizer
 * 	@function ttg_core_active: check if the plugin is active to add post types and fields
 *  =============================================
 */
if(function_exists('ttg_core_active') && class_exists('Custom_Add_Meta_Box')){
	/* Custom post types */
	require_once get_template_directory().'/ttgcore-setup/custom-types/artist/artist-type.php';
	require_once get_template_directory().'/ttgcore-setup/custom-types/events/events-type.php';
	require_once get_template_directory().'/ttgcore-setup/custom-types/podcast/podcast-type.php';
	require_once get_template_directory().'/ttgcore-setup/custom-types/release/release-type.php';
	require_once get_template_directory().'/ttgcore-setup/custom-types/pages-special/pages-special.php';
	/* Shortcode settings */
	require_once get_template_directory()."/ttgcore-setup/short/short-carousel.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-slider-post.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-list.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-cards.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-card-grid.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-blog.php";
	// Special shortcodes
	require_once get_template_directory()."/ttgcore-setup/short/short-perspectivecard.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-releases-small.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-releases-large.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-cover-carousel.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-events.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-event-featured.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-button-release.php";
	// Since 1.3
	require_once get_template_directory()."/ttgcore-setup/short/short-playlist.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-playlist-custom.php";
	// Design Extensions
	require_once get_template_directory()."/ttgcore-setup/short/short-tabs.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-accordion.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-gallery.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-gallery-flexbin.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-gallery-multimedia.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-captions.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-imageslider.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-buttons.php";
	// Since 1.3.0
	if ( class_exists( 'WooCommerce' ) ) {
		require_once get_template_directory()."/ttgcore-setup/short/short-buttons-addtocart.php";
		require_once get_template_directory()."/ttgcore-setup/short/short-products-carousel.php";

		// Slider always after carousel
		require_once get_template_directory()."/ttgcore-setup/short/short-products-slider.php";
		require_once get_template_directory()."/ttgcore-setup/short/short-productsearch.php";

		if( get_theme_mod('kentha_woocommerce_singletrack_enable') ){
			require_once get_template_directory()."/ttgcore-setup/short/short-products-singletracks.php";
			require_once get_template_directory()."/ttgcore-setup/short/short-products-singletracks-cards.php";

		}
	}
	require_once get_template_directory()."/ttgcore-setup/short/short-socialicons.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-image.php";
	require_once get_template_directory()."/ttgcore-setup/short/short-textfx.php";



	/* Customizer */
	// Early exit if Kirki is not installed
	if ( class_exists( 'Kirki' ) ) {
		require_once   get_template_directory().'/ttgcore-setup/customizer/kirki-configuration/sections.php';
		require_once   get_template_directory().'/ttgcore-setup/customizer/kirki-configuration/fields.php';
		require_once   get_template_directory().'/ttgcore-setup/customizer/kirki-configuration/configuration.php'; 
		require_once   get_template_directory().'/phpincludes/customizations.php'; 
	}
}

/* Setup 
=============================================*/
if ( ! function_exists( 'kentha_setup' ) ) {
function kentha_setup() {
	load_theme_textdomain( "kentha", get_template_directory() . '/languages' );
	add_theme_support( 'automatic-feed-links' );
	add_theme_support( 'post-thumbnails' );
	add_theme_support( 'title-tag' );
	add_theme_support( 'editor_style');
	add_theme_support( 'html5', array( 'comment-list', 'comment-form', 'search-form', 'script', 'style' ) );
	
	/* = We have to add the required images sizes */
	set_post_thumbnail_size( 170, 170, true );
	add_image_size( 'kentha-squared', 670, 670, true );

	/* = Register the menu after_menu_locations_table */
	register_nav_menus( array(
		'kentha_menu_primary' => esc_html__( 'Primary Menu', "kentha" ),
	));
	register_nav_menus( array(
		'kentha_menu_footer' => esc_html__( 'Footer Menu', "kentha" ),
	));
	register_nav_menus( array(
		'kentha_menu_offcanvas' => esc_html__( 'Offcanvas Menu', "kentha" ),
	));
}}
add_action( 'after_setup_theme', 'kentha_setup' );

/* Change default thumbnails sizes 
=============================================*/
add_action('after_switch_theme', 'kentha_setup_options');
function kentha_setup_options () {
	update_option( 'medium_size_w', 756 );
	update_option( 'medium_size_h', 756 );
	update_option( 'large_size_w', 1600 );
	update_option( 'large_size_h', 1600 );
}

/* Register sidebars
=============================================*/
if(!function_exists('kentha_widgets_init')){
function kentha_widgets_init() {
	$accordion = get_theme_mod( 'kentha_widget_accordion' );
	$icon = '';
	$before_title  = '<h5 class="qt-widget-title"><span>';
	$after_title   = '</span></h5>';
	$after_widget  = '</li>';
	register_sidebar( array(
		'name'          => esc_html__( 'Right Sidebar', "kentha" ),
		'id'            => 'kentha-right-sidebar',
		'before_widget' => '<li id="%1$s" class="qt-ms-item qt-widget col s12 m12 l12">',
		'before_title'  => $before_title,
		'after_title'   => $after_title,
		'after_widget'  => $after_widget
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Artist Sidebar', "kentha" ),
		'id'            => 'kentha-artist-sidebar',
		'before_widget' => '<li id="%1$s" class="qt-ms-item qt-widget col s12 m12 l12">',
		'before_title'  => $before_title,
		'after_title'   => $after_title,
		'after_widget'  => $after_widget
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Release Sidebar', "kentha" ),
		'id'            => 'kentha-release-sidebar',
		'before_widget' => '<li id="%1$s" class="qt-ms-item qt-widget col s12 m12 l12">',
		'before_title'  => $before_title,
		'after_title'   => $after_title,
		'after_widget'  => $after_widget
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Podcast Sidebar', "kentha" ),
		'id'            => 'kentha-podcast-sidebar',
		'before_widget' => '<li id="%1$s" class="qt-ms-item qt-widget col s12 m12 l12">',
		'before_title'  => $before_title,
		'after_title'   => $after_title,
		'after_widget'  => $after_widget
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Event Sidebar', "kentha" ),
		'id'            => 'kentha-event-sidebar',
		'before_widget' => '<li id="%1$s" class="qt-ms-item qt-widget col s12 m12 l12">',
		'before_title'  => $before_title,
		'after_title'   => $after_title,
		'after_widget'  => $after_widget
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Bottom layer sidebar', "kentha" ),
		'id'            => 'kentha-bottom-sidebar',
		'before_widget' => '<div id="%1$s" class="qt-widget">',
		'before_title'  => '<h3 class="qt-sectiontitle">',
		'after_title'   => '</h3>',
		'after_widget'  => '</div>'
	));
	register_sidebar( array(
		'name'          => esc_html__( 'Footer Sidebar', "kentha" ),
		'id'            => 'kentha-footer-sidebar',
		'before_widget' => '<aside id="%1$s" class="qt-widget col s12 m6 l3 qt-ms-item %2$s">',
		'before_title'  => '<h5 class="qt-widget-title"><span>',
		'after_title'   => '</span></h5>',
		'after_widget'  => '</aside>'
	));

	
}}
add_action( 'widgets_init', 'kentha_widgets_init' );

/* if no title then add widget content wrapper to before widget
=============================================*/
add_filter( 'dynamic_sidebar_params', 'kentha_check_sidebar_params' );
function kentha_check_sidebar_params( $params ) {
	global $wp_registered_widgets;
	$settings_getter = $wp_registered_widgets[ $params[0]['widget_id'] ]['callback'][0];
	$settings = $settings_getter->get_settings();
	$settings = $settings[ $params[1]['number'] ];
	if ( $params[0][ 'after_widget' ] == '</div></li>' && isset( $settings[ 'title' ] ) && empty( $settings[ 'title' ] ) )
		$params[0][ 'before_widget' ] .= '<div class="qt-widget-tags collapsible-body">';
	return $params;
}

/* Register fonts
=============================================*/
if(!function_exists('kentha_fonts_url')){
function kentha_fonts_url() {
	$font_url = '';
	/*
	Translators: If there are characters in your language that are not supported
	by chosen font(s), translate this to 'off'. Do not translate into your own language.
	 */
	if ( 'off' !== _x( 'on', 'Google font: on or off', 'kentha' ) ) {
		$font_url = add_query_arg( 'family', urlencode( 'Montserrat:700,400,200|Open+Sans:300,400,700' ), "//fonts.googleapis.com/css" );
	}
	return $font_url;
}}


/* CSS and Js loading
=============================================*/
if(!function_exists('kentha_files_inclusion')){
function kentha_files_inclusion() {
	
	/**
	 *
	 * CSS
	 * 
	 */
	// if the ajax plugin is active we load MediaElement
	if(function_exists('qt_ajax_pageload_is_active')){
		wp_enqueue_style( 'wp-mediaelement' );
	}
	// External CSS libraries
	wp_enqueue_style( "qt-socicon", 			get_template_directory_uri().'/fonts/qt-socicon/qt-socicon.css', false, kentha_theme_version(), "all" ); // Social icons custom library by QantumThemes
	wp_enqueue_style( "material-icons", 				get_template_directory_uri().'/fonts/google-icons/material-icons.css', false, kentha_theme_version(), "all" ); // Material Design Library

	// Main theme CSS
	wp_enqueue_style( "kentha-qt-main-min", 		get_template_directory_uri().'/css/qt-main-min.css', false, kentha_theme_version(), "all" );
	
	// Desktop styles are loaded only > 1201px
	wp_enqueue_style( "kentha-qt-desktop-min", 		get_template_directory_uri().'/css/qt-desktop-min.css',  array('kentha-qt-main-min'), kentha_theme_version(), "only screen and (min-width: 1201px)" );
	
	// if no customizer is active, load default colors and fonts
	if( !function_exists( 'ttg_core_active' ) ){
		wp_enqueue_style( "kentha-qt-colors-min", 	get_template_directory_uri().'/css/qt-colors-min.css', false, kentha_theme_version(), "all" );
		wp_enqueue_style( 'kentha-fonts', 			kentha_fonts_url(), array(), '1.0.0' );
		wp_enqueue_style( "kentha-qt-typography", 	get_template_directory_uri().'/css/qt-typography.css', false, kentha_theme_version(), "all" );
	}

	// Default theme's style.css
	wp_enqueue_style( 'kentha-style', get_stylesheet_uri(), false, kentha_theme_version() );


	/**
	 *
	 * Javascript
	 * 
	 */
	// js libraries

	$deps = array("jquery", "masonry", 'jquery-migrate' );

	// if the ajax plugin is active we load MediaElement.js
	if(function_exists( 'qt_ajax_pageload_is_active' )){
		$deps[] =  'wp-mediaelement';
		$deps[] =  'wp-playlist';
	}

	// We use official waypoint not from Page Composer as this is loaded correctly
	wp_register_script( 'waypoints', get_template_directory_uri().'/components/waypoints/waypoints.min.js', $deps, kentha_theme_version(), true );
	wp_enqueue_script( 'waypoints' );  $deps[] = 'waypoints';
	
	wp_enqueue_script( 'skrollr', get_template_directory_uri().'/components/skrollr/skrollr.min.js', $deps, kentha_theme_version(), true ); $deps[] = 'skrollr';


	/**
	 * Enqueue Visual Composer styles in every page for ajax compatibility
	 */
	if(defined( 'WPB_VC_VERSION' )){
		if(function_exists('vc_asset_url')){
			// The following scripts are not to be forcefully loaded anymore
			// Replaced with getScript in jquery.youtubebackground.js
			// ====================================================================================
			// wp_register_script( 'vc_youtube_iframe_api_js', 'https://www.youtube.com/iframe_api', array(), WPB_VC_VERSION, true );
			// wp_enqueue_script( 'vc_youtube_iframe_api_js' );$deps[] =  'vc_youtube_iframe_api_js';
			wp_register_style( 'vc_tta_style', vc_asset_url( 'css/js_composer_tta.min.css' ), false, WPB_VC_VERSION );
			wp_enqueue_style( 'vc_tta_style' );
			wp_register_script( 'vc_accordion_script', vc_asset_url( 'lib/vc_accordion/vc-accordion.min.js' ), array( 'jquery' ), WPB_VC_VERSION, true );
			wp_register_script( 'vc_tta_autoplay_script', vc_asset_url( 'lib/vc-tta-autoplay/vc-tta-autoplay.min.js' ), array( 'vc_accordion_script' ), WPB_VC_VERSION, true );
			wp_enqueue_script( 'vc_accordion_script' );
			if ( ! vc_is_page_editable() ) {
				wp_enqueue_script( 'vc_tta_autoplay_script' );
			}
			wp_register_script( 'vc_jquery_skrollr_js', vc_asset_url( 'lib/bower/skrollr/dist/skrollr.min.js' ), array( 'jquery' ), WPB_VC_VERSION, true );
			wp_dequeue_script( 'vc_jquery_skrollr_js' ); //$deps[] = 'vc_jquery_skrollr_js'; // If Visual Composer is enabled, it will load Skrollr using a WRONG ID (it should be skrollr but they use vc_jquery_skrollr_js)
			
		}
		wp_enqueue_script( 'wpb_composer_front_js' );$deps[] = 'wpb_composer_front_js' ;

		// CSS for ajax page composer
		wp_enqueue_style( 'js_composer_front' );
		wp_enqueue_style( 'js_composer_custom_css' );
		wp_enqueue_style( 'animate-css' ); // visual composer animation styles
		
	} 



	/**
	 * If debug is active in customizer we load separated unminified js, otherwise load only
	 * min/qt-main-script.js
	 */
	

	if(get_theme_mod("kentha_enable_debug", 0) == "1"){
		/**
		 * If the debugger is ENABLED and you experience js conflicts OR need to add your own customizations
		 * this loads a unminified list of JS files as per Envato quality requirements.
		 * To apply your js customizations, enable Debug in customizer.
		 */
		// Performance: Modernizr removed for performance hogging. Only loaded for explorer browser
		global $is_IE; // Yes, using global, as per Codex requirements, we are reading default globals https://codex.wordpress.org/Global_Variables
		if($is_IE){
			wp_enqueue_script( 'modernizr', get_template_directory_uri().'/components/modernizr/modernizr-custom.js', $deps, '3.5.0', true ); $deps[] = 'modernizr';
		} 
		// Materialize framework (Custom minimal version with only required libraries)
		wp_enqueue_script( 'materialize', get_template_directory_uri().'/js/min/qt-materialize-custom-min.js', $deps, kentha_theme_version(), true ); $deps[] = 'materialize';
		// Other libraries
		wp_enqueue_script( 'slick', get_template_directory_uri().'/components/slick/slick.min.js', $deps, kentha_theme_version(), true ); $deps[] = 'slick';
		wp_enqueue_script( 'popup', get_template_directory_uri().'/components/popup/popup.js', $deps, kentha_theme_version(), true ); $deps[] = 'popup';
		wp_enqueue_script( 'raphael', get_template_directory_uri().'/components/raphael/raphael.min.js', $deps, kentha_theme_version(), true ); $deps[] = 'raphael';
		wp_enqueue_script( 'youtubebackground-kentha', get_template_directory_uri().'/components/ytbg/src/jquery.youtubebackground.js', $deps, kentha_theme_version(), true ); $deps[] = 'youtubebackground-kentha';
		// main theme script
		wp_enqueue_script( 'kentha-qt-main-script', get_template_directory_uri().'/js/qt-main-script.js', $deps, kentha_theme_version(), true ); $deps[] = 'kentha-qt-main-script';
	} else {
		wp_enqueue_script( 'kentha-qt-main-script', get_template_directory_uri().'/js/min/qt-main-script.js', $deps, kentha_theme_version(), true ); $deps[] = 'kentha-qt-main-script';
	}

	if ( is_singular() && comments_open() && get_option( 'thread_comments' ) ) {
		wp_enqueue_script( 'comment-reply' );
	}
}}
add_action( 'wp_enqueue_scripts', 'kentha_files_inclusion', 999999 );









/* ADMIN CSS and Js loading
=============================================*/
if(!function_exists('kentha_admin_files_inclusion')){
function kentha_admin_files_inclusion() {
	wp_enqueue_style( 'kentha-fonts', kentha_fonts_url(), array(), '1.0.0' );
	wp_enqueue_style( "kentha_admin", get_template_directory_uri().'/css/qt-admin.css', false, kentha_theme_version(), "all" );
}}
add_action( 'admin_enqueue_scripts', 'kentha_admin_files_inclusion', 999999 );

/* Editor style
============================================= */
if(!function_exists('kentha_add_editor_styles')){
function kentha_add_editor_styles() {
	add_editor_style(  get_template_directory_uri().'/css/editor.css' );
}}
add_action( 'init', 'kentha_add_editor_styles' );

/* Icon by post format
=============================================*/
if ( ! function_exists( 'kentha_format_icon_class' ) ) {
function kentha_format_icon_class ( $id = false) {
	if ( false === $id ) {
		return;
	} else {
		$format = get_post_format( $id );
		if ( false === $format ) {
			$format = 'post';
		}
		switch ($format){
			case "video":
				echo 'ondemand_video';
				break;
			case "audio":
				echo 'audiotrack';
				break;
			case "gallery":
				echo 'photo_library';
				break;
			case "image":
				echo 'photo_camera';
				break;
			case "link":
				echo 'link';
				break;
			case "chat":
				echo 'chat';
				break;
			case "quote":
				echo 'format_quote';
				break;
			case "post": 
			case "aside":
			
			default:
				echo 'format_align_left';
			break;
		}
	}
}}

/* Create the proper date formatted text
=============================================*/
if(!function_exists('kentha_international_date')) {
function kentha_international_date(){
	the_time( get_option( "date_format", "d M Y" ), '', '', true );
}}

/* Get universal page id
============================================= */
if ( ! function_exists( 'kentha_universal_page_id' ) ) {
function kentha_universal_page_id() {
	$pageid = get_the_ID();
	if(function_exists('is_shop') && function_exists('is_checkout') && function_exists('is_account_page') && function_exists('is_wc_endpoint_url')){
		if(is_shop()){
			$pageid = get_option( 'woocommerce_shop_page_id' ); 
		} elseif (is_cart()){
			$pageid = get_option( 'woocommerce_cart_page_id' ); 
		}elseif (is_checkout()){
			$pageid = get_option( 'woocommerce_checkout_page_id' ); 
		}elseif (is_account_page()){
			$pageid = get_option( 'woocommerce_myaccount_page_id' ); 
		}elseif (is_wc_endpoint_url( 'order-pay' )){
			$pageid = get_option( 'woocommerce_pay_page_id' ); 
		}elseif (is_wc_endpoint_url( 'order-received' )){
			$pageid = get_option( 'woocommerce_thanks_page_id' ); 
		}elseif (is_wc_endpoint_url( 'view-order' ) ){
			$pageid = get_option( 'woocommerce_view_order_page_id' ); 
		}elseif (is_wc_endpoint_url( 'edit-account' ) ){
			$pageid = get_option( 'woocommerce_myaccount_page_id' ); 
		}elseif (is_wc_endpoint_url( 'edit-address' )){
			$pageid = get_option( 'woocommerce_edit_address_page_id' ); 
		}elseif (is_wc_endpoint_url( 'lost-password' )){
			$pageid = get_option( 'woocommerce_checkout_page_id' ); 
		}elseif (is_wc_endpoint_url( 'customer-logout' )){
			$pageid = get_option( 'woocommerce_checkout_page_id' ); 
		}elseif (is_wc_endpoint_url( 'add-payment-method' )){
			$pageid = get_option( 'woocommerce_shop_page_id' ); 
		}
	}
	return $pageid;
}}

/* Get current page. 
 * Role: Fix for using archives as home page
============================================= */
if(!function_exists('kentha_get_paged')){
function kentha_get_paged() {
	if ( get_query_var('paged') ) {
		$paged = get_query_var('paged');
	} elseif ( get_query_var('page') ) {
		$paged = get_query_var('page');
	} else {  $paged = 1; }
	return intval($paged);
}}

/* Excerpt length
============================================= */
add_filter( 'excerpt_length', 'kentha_excerpt_length', 999 );
if(!function_exists('kentha_excerpt_length')){
function kentha_excerpt_length( $length ) {
	return 50;
}}
if(!function_exists('kentha_excerpt_length_20')){
function kentha_excerpt_length_20( $length ) {
	return 20;
}}

/* Extract header image
============================================= */
if(!function_exists('kentha_header_image_url')){
function kentha_header_image_url($id = null, $print = true) {
	$image_url = false;
	if( (is_singular() || is_home() || is_page() || is_front_page()) && has_post_thumbnail()){
		if(!isset($id)){
			$id = kentha_universal_page_id();
		}
		$image_url = get_the_post_thumbnail_url($id, 'full' );
	} else {
		$image_url = get_theme_mod( 'kentha_header_backgroundimage', '' );
	}
	if($image_url){
		if($print){
			echo esc_url($image_url);
		} else {
			return esc_url($image_url);
		}
	}
	return false;
}}

/* Gets the taxonomy associated with any post type for other queries
=============================================*/
if(!function_exists('kentha_get_type_taxonomy')){
function kentha_get_type_taxonomy($posttype){
	if($posttype != ''){
		switch($posttype){
			case "product":
				$taxonomy = 'product_cat';
				break;
			case "kentha_serie":
				$taxonomy = 'kentha_seriescategory';
				break;
			case "event":
				$taxonomy = 'eventtype';
				break;
			case "podcast":
				$taxonomy = 'podcastfilter';
				break;
			case "release":
				$taxonomy = 'genre';
				break;
			case "artist":
				$taxonomy = 'artistgenre';
				break;
			case "shows":
				$taxonomy = 'showgenre';
				break;
			case "chart":
				$taxonomy = 'chartcategory';
				break;
			case "members":
				$taxonomy = 'membertype';
				break;
			default:
				$taxonomy = 'category';
		}
	}
	return $taxonomy;
}}

/* Add classes to body
=============================================*/
if ( ! function_exists( 'kentha_class_names' ) ) {
function kentha_class_names($classes) {
	$classes[] = "qt-body";

	if(wp_is_mobile()) $classes[] = 'mobile';

	if(strpos($_SERVER['HTTP_USER_AGENT'], 'iPhone') !== false) $classes[] = 'is_iphone';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'iPad') !== false) $classes[] = 'is_ipad';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'Android') !== false) $classes[] = 'is_android';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'Kindle') !== false) $classes[] = 'is_kindle';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'BlackBerry') !== false) $classes[] = 'is_blackberry';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'Opera Mini') !== false) $classes[] = 'is_opera-mini';
	else if(strpos($_SERVER['HTTP_USER_AGENT'], 'Opera Mobi') !== false) $classes[] = 'is_opera-mobi';


	if ( stristr( $_SERVER['HTTP_USER_AGENT'],'mac') ) $classes[] = 'is_osx';
	else if ( stristr( $_SERVER['HTTP_USER_AGENT'],'linux') ) $classes[] = 'is_linux';
	else if ( stristr( $_SERVER['HTTP_USER_AGENT'],'windows') ) $classes[] = 'is_windows';


	if(strpos($_SERVER['HTTP_USER_AGENT'], 'Safari') !== false) $classes[] = 'is_safari';
	if(strpos($_SERVER['HTTP_USER_AGENT'], 'Trident/7.0') !== false) $classes[] = 'is_explorer';

	if(get_theme_mod('kentha_mod_lazyload')){
		$classes[] = 'qt-lazyload';
	}
	if(get_theme_mod('kentha_mod_parallax')){
		$classes[] = 'qt-parallax-on';
	}
	if(is_singular()) {
		$classes[] = "qt-template-".esc_attr ( str_replace('.php', '', get_page_template_slug ( get_the_ID() ) ) );
	} else {
		$classes[] =  "qt-template-archive";
	}
	if(get_theme_mod("kentha_enable_debug", 0)){
		$classes[] = 'qt-debug';
	}	
	if(get_theme_mod("kentha_hq_parallax", 0)){
		$classes[] = 'qt-hq-parallax';
	}	



	if( get_theme_mod('kentha_enable_autoplay', false ) ){
		$classes[] = 'qt-video-autoplay';
	}
	if(is_admin_bar_showing()){
		$classes[] = 'qt-user-logged';
	}	
	if (get_theme_mod( 'kentha_menu_style', '0' ) == '1' && has_nav_menu( 'kentha_menu_primary' )) {
		$classes[] = 'qt-body-menu-center';
	}
	if (get_theme_mod( 'kentha_introfx', '0' ) == '1' ) {
		$classes[] = 'qt-intro';
	}
	return $classes;
}}
add_filter('body_class','kentha_class_names');

/* Template for comments and pingbacks.
 * Used as a callback by wp_list_comments() for displaying the comments.
============================================= */
if ( ! function_exists( 'kentha_s_comment' ) ) :
function kentha_s_comment( $comment, $args, $depth ) {
	if ( 'pingback' == $comment->comment_type || 'trackback' == $comment->comment_type ) : ?>
	<li id="comment-<?php comment_ID(); ?>" <?php comment_class("comment qt-comment-item"); ?>>
		<article class="comment-body">
			<p class="qw-commentheader qw-small qw-caps">
				<?php esc_attr_e( 'Pingback:', "kentha" ); ?> <?php edit_comment_link( "<i class='material-icons'>mode_edit</i>".esc_html__("Edit pingback","kentha"), '<span class="edit-link">', '</span>' ); ?>
			</p>
			<div class="comment-text">
				<?php comment_author_link(); ?> 
			</div>
		</article>
	<?php else : ?>
	<li id="comment-<?php comment_ID(); ?>" <?php comment_class( empty( $args['has_children'] ) ? 'comment qt-comment-item' : 'comment qt-comment-item parent' ); ?>>
		<article id="div-comment-<?php comment_ID(); ?>" class="comment-body ">
			<div class="comment-content">
				<div class="qt-comment-image">
					<?php 
						$avatar = get_avatar( $comment, $args['avatar_size'] );
						if ( 0 != $args['avatar_size'] && $avatar != '' ){
							echo get_avatar( $comment, $args['avatar_size'] );
						}else{
							?><i class="fa fa-user"></i><?php
						}
					?>
				</div>
				<div class="qt-comment-text">
					<div class="comment-content">
						<h5 class="qt-commentheader qt-capfont"><?php printf( esc_html__( '%s', "kentha" ), sprintf( '%s', get_comment_author_link() ) ); ?></h5>
						<p class="qt-small qt-commentdetails"><a href="<?php echo esc_url( get_comment_link( $comment->comment_ID ) ); ?>"><?php printf( _x( '%1$s at %2$s', '1: date, 2: time', "kentha" ), get_comment_date(), get_comment_time() ); ?></a> <?php edit_comment_link( " | <i class='material-icons'>mode_edit</i> ".esc_html__("Edit comment","kentha"), '<span class="edit-link">', '</span>' ); ?></p>
						<?php if ( '0' == $comment->comment_approved ) : ?>
						<p class="comment-awaiting-moderation"><?php esc_html_e( 'Your comment is awaiting moderation.', "kentha" ); ?></p>
						<?php endif; ?>
						<div class="qt-the-content">
							<?php comment_text(); ?>							
						</div>
						<?php
						comment_reply_link( array_merge( $args, array(
							'add_below' => 'div-comment',
							'depth'     => $depth,
							'max_depth' => $args['max_depth'],
							'before'    => '<div class="reply">',
							'after'     => '</div>',
						) ) );
						?>					
					</div><!-- .comment-content -->
				</div>
			</div>			
		</article><!-- .comment-body -->
	<?php
	/* Yes, the LI is open and is correct in this way. */
	endif;
}
endif; // ends check for kentha_s_comment()

/* This is to add our own classes to the comment reply link in comments section
=============================================*/
add_filter('comment_reply_link', 'kentha_replace_reply_link_class');
if(!function_exists('kentha_replace_reply_link_class')){
function kentha_replace_reply_link_class($class){
	$class = str_replace("class='comment-reply-link", "class='comment-reply-link qt-btn qt-btn qt-btn-secondary", $class);
	return $class;
}}

/* Visual composer extension settings
=============================================*/
if(defined( 'WPB_VC_VERSION' )){
	add_action( 'vc_after_init', 'kentha_vc_after_init_actions' );
	function kentha_vc_after_init_actions() {


		/**
		 * [kentha_file_picker_settings_field add file picker type to visual compsoer]
		 */
		function kentha_file_picker_settings_field( $settings, $value ) {
		  $output = '';
		  $select_file_class = '';
		  $remove_file_class = ' hidden';
		  $attachment_url = wp_get_attachment_url( $value );
		  if ( $attachment_url ) {
		    $select_file_class = ' hidden';
		    $remove_file_class = '';
		  }
		  $output .= '<div class="file_picker_block">
		                <div class="' . esc_attr( $settings['type'] ) . '_display">' .
		                  $attachment_url .
		                '</div>
		                <input type="hidden" name="' . esc_attr( $settings['param_name'] ) . '" class="wpb_vc_param_value wpb-textinput ' .
		                 esc_attr( $settings['param_name'] ) . ' ' .
		                 esc_attr( $settings['type'] ) . '_field" value="' . esc_attr( $value ) . '" />
		                <button class="button file-picker-button' . $select_file_class . '">Select File</button>
		                <button class="button file-remover-button' . $remove_file_class . '">Remove File</button>
		              </div>
		              ';
		  return $output;
		}
		vc_add_shortcode_param( 'file_picker', 'kentha_file_picker_settings_field', get_template_directory_uri() . '/vc_extend/file_picker.js' );


		if(defined( 'WPB_VC_VERSION' )){
			wp_enqueue_script( 'wpb_composer_front_js' );
			wp_enqueue_style( 'js_composer_front' );
		}
		// Remove VC Elements
		if( function_exists('vc_remove_element') ){
			vc_remove_element( 'vc_media_grid' );
			vc_remove_element( 'vc_masonry_grid' );
			vc_remove_element( 'vc_masonry_media_grid' );
			vc_remove_element( 'vc_basic_grid' );
			vc_remove_element( 'vc_line_chart' );
			vc_remove_element( 'vc_round_chart' );
			vc_remove_element( 'vc_pie' );
			vc_remove_element( 'vc_progress_bar' );
			vc_remove_element( 'vc_flickr' );
			vc_remove_element( 'vc_posts_slider' );
			vc_remove_element( 'vc_images_carousel' );
			vc_remove_element( 'vc_tta_pageable' );
			vc_remove_element( 'vc_gallery' );
			// vc_remove_element( 'vc_single_image' );
			vc_remove_element( 'vc_tta_accordion' );
			vc_remove_element( 'vc_tta_tabs' );
			vc_remove_element( 'vc_tta_tour' );
		}
		
		/**
		 * Remove the CSS animation from any shortcode because is incompatible with ajax loading
		 */
		if( function_exists('vc_remove_param') ){
			$all_shortcodes = array("vc_row","vc_row_inner","vc_column","vc_column_inner","vc_column_text","vc_section","vc_icon","vc_separator","vc_zigzag","vc_text_separator","vc_message","vc_facebook","vc_tweetmeme","vc_googleplus","vc_pinterest","vc_toggle","vc_tta_section","vc_custom_heading","vc_btn","vc_cta","vc_widget_sidebar","vc_video","vc_gmaps","vc_raw_html","vc_raw_js","vc_wp_search","vc_wp_meta","vc_wp_recentcomments","vc_wp_calendar","vc_wp_pages","vc_wp_tagcloud","vc_wp_custommenu","vc_wp_text","vc_wp_posts","vc_wp_links","vc_wp_categories","vc_wp_archives","vc_wp_rss","vc_empty_space","vc_tabs","vc_tour","vc_tab","vc_accordion","vc_accordion_tab","vc_posts_grid","vc_carousel","vc_button","vc_button2","vc_cta_button","vc_cta_button2");
			foreach ($all_shortcodes as $s){
				vc_remove_param( $s, 'css_animation' ); 
			}
		}
		
		/**
		 * Adding theme custom parameters
		 */
		if( function_exists('vc_add_param') ){ 
			// vc_remove_param( "vc_row", "parallax_speed_bg" );
			vc_add_param(
				"vc_row", 
				array(
					'type' => 'checkbox',
					'weight' => 1,
					'heading' => esc_html__( 'Add container', "kentha" ),
					'param_name' => 'qt_container',
					'description' => esc_html__( "Add a container box to the content to limit width", "kentha" )
				)
			);
			vc_add_param(
				"vc_row", 
				array(
					'type' => 'checkbox',
					'weight' => 1,
					'heading' => esc_html__( 'Negative colors', "kentha" ),
					'param_name' => 'qt_negative',
					'description' => esc_html__( "Force white texts", "kentha" )
				)
			);
			vc_add_param(
				"vc_row_inner", 
				array(
					'type' => 'checkbox',
					'weight' => 1,
					'heading' => esc_html__( 'Add container', "kentha" ),
					'param_name' => 'qt_container',
					'description' => esc_html__( "Add a container box to the content to limit width", "kentha" )
				)
			);
			vc_add_param(
				"vc_row_inner", 
				array(
					'type' => 'checkbox',
					'weight' => 1,
					'heading' => esc_html__( 'Negative colors', "kentha" ),
					'param_name' => 'qt_negative',
					'description' => esc_html__( "Force white texts", "kentha" )
				)
			);
		}
	}
}

/* Customize number of posts depending on the archive post type
============================================= */
if(!function_exists('kentha_custom_number_of_posts')){
function kentha_custom_number_of_posts( $query ) {
	if($query->is_main_query() && !is_admin()){
		if ( $query->is_post_type_archive( 'podcast' ) 
			|| $query->is_post_type_archive('artist')
			|| $query->is_post_type_archive('release')
			|| $query->is_post_type_archive('event')
			|| $query->is_tax('filter')
			|| $query->is_tax('genre')
			|| $query->is_tax('eventtype')
			|| $query->is_tax('artistgenre')

			// qt-kentharadio plugin 
			|| $query->is_post_type_archive('chart')
			|| $query->is_post_type_archive('shows')
			|| $query->is_post_type_archive('members')
			|| $query->is_tax('membertype')
			|| $query->is_tax('podcastfilter')
			|| $query->is_tax('chartcategory')
		) {
			$query->set( 'posts_per_page','9' );
			if ( $query->is_post_type_archive( 'artist' ) || $query->is_tax('artistgenre')){
				$query->set( 'posts_per_page','9' );
			}
			if ( $query->is_post_type_archive( 'release' ) || $query->is_tax('genre')){
				$query->set( 'posts_per_page','9' );
			}
			if ( $query->is_post_type_archive( 'podcast' ) || $query->is_tax('filter')){
				$query->set( 'posts_per_page','9' );
			}

			 // qt-kentharadio plugin 
			if ( $query->is_post_type_archive( 'shows' ) || $query->is_tax('genre')){
				$query->set( 'orderby', array ('menu_order' => 'ASC', 'date' => 'DESC'));
				$query->set( 'posts_per_page','9' );
			}
			if ( $query->is_post_type_archive( 'chart' ) || $query->is_tax('chartcategory')){
				$query->set( 'posts_per_page','9' );
				$query->set( 'orderby', 'date');
				$query->set( 'order', 'DESC');
			}


			if($query->is_post_type_archive('event') || $query->is_tax('eventtype')) {
				$query->set( 'posts_per_page','9' );
				$query->set( 'meta_key', 'eventdate' );
				$query->set( 'orderby', 'meta_value' );
				$query->set( 'order', 'ASC' );
				if ( get_theme_mod ( 'kentha_events_hideold', 0 ) == '1'){
					$query->set ( 
						'meta_query' , array (
							array (
								'key' => 'eventdate',
								'value' => date('Y-m-d'),
								'compare' => '>=',
								'type' => 'date'
							)
						)
					);
				}
			}
			return;
		}
	}
}}
add_action( 'pre_get_posts', 'kentha_custom_number_of_posts', 1, 999 );

/* Check if featured is vertical
============================================= */
if(!function_exists('kentha_vertical_check')){
function kentha_vertical_check() {
	$thumb_id   = get_post_thumbnail_id();
	$image_data = wp_get_attachment_image_src( $thumb_id , 'tp-thumbnail' );
	$width  = $image_data[1];
	$height = $image_data[2];
	if ( $width < $height ) {
		return true;
	}
	return false;
}}

/* Add class right to secondary menu items
=============================================*/
if(!function_exists('kentha_main_menu_classes')){
function kentha_main_menu_classes( $classes, $item, $args ) {
	if ( 'kentha_menu_primary' === $args->theme_location ) {
		$classes[] = 'qt-menuitem';
	}
	return $classes;
}}
add_filter( 'nav_menu_css_class', 'kentha_main_menu_classes', 10, 3 ); 

/* Creates a custom excerpt of titles
============================================= */
if(!function_exists('kentha_shorten')){
function kentha_shorten($string, $your_desired_width) {
  $parts = preg_split('/([\s\n\r]+)/', $string, null, PREG_SPLIT_DELIM_CAPTURE);
  $parts_count = count($parts);
  $length = 0;
  $last_part = 0;
  $ellipsis = '';
  for (; $last_part < $parts_count; ++$last_part) {
	$length += strlen($parts[$last_part]);
	if ($length > $your_desired_width) {   $ellipsis = '...'; break; }
  }
  return implode(array_slice($parts, 0, $last_part)).$ellipsis;;
}}

/* Check if we have the player plugin installed, otherwise false
============================================= */
if(!function_exists('kentha_has_player')){
function kentha_has_player() {
	if(function_exists('qt_musicplayer')){
		return true;
	}
	return false;
}}

/* Get artist releases by artist name
============================================= */
if(!function_exists('kentha_get_artist_releases_old')){
function kentha_get_artist_releases_old($artist_title){
	if(!$artist_title){
		return;
	}
	$args = array(
		'post_type' => 'release',
		'posts_per_page' => -1,
		'posts_status' => 'publish',
		'meta_query' => array(
			array(
				'key' => 'track_repeatable',
				'value' => $artist_title,
				'compare' => 'LIKE'
			)
		)
	);
	$wp_query = new WP_Query( $args );
	if ( !$wp_query->have_posts() ){
		return false;
	}
	ob_start();
	if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		?>
		<div class="col s6 m3 l3">
			<?php  
			get_template_part ('phpincludes/part-archive-item-release-small');
			?>
		</div>
		<?php  
	endwhile; endif;
	wp_reset_postdata();
	return ob_get_clean();
}}





/* Get artist releases by artist name
============================================= */
if(!function_exists('kentha_get_artist_releases')){
function kentha_get_artist_releases($artist_title){
	ob_start();
	// echo 'received artist title esc_sql: '.urlencode($artist_title);
	if(!$artist_title){
		return;
	}
	$args = array(
		'post_type' => 'release',
		'posts_per_page' => -1,
		'posts_status' => 'publish',
		'meta_query' => array(
			'relation' => 'OR',
			array(
				'key' => 'track_repeatable',
				'value' => ",".$artist_title." ",
				'compare' => 'LIKE'
			),
			array(
				'key' => 'track_repeatable',
				'value' => " ".$artist_title,
				'compare' => 'LIKE'
			),
			array(
				'key' => 'track_repeatable',
				'value' => $artist_title." ",
				'compare' => 'LIKE'
			),
			array(
				'key' => 'track_repeatable',
				'value' => '"'.$artist_title.'"',
				'compare' => 'LIKE'
			)
		)
	);
	$wp_query = new WP_Query( $args );
	if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );


		$have_to_add = false;
		$post_id = $wp_query->post->ID;
		$tracks = get_post_meta($post_id, 'track_repeatable');
		$tracks = $tracks[0];
		if(is_array($tracks)){

			foreach($tracks as $track){ 
				if(array_key_exists('releasetrack_artist_name',$track)){

					$track_artists = $track['releasetrack_artist_name'];
					$subject = $track_artists;
					if (strpos($subject, $artist_title) !== false) {
						$have_to_add = 1;
					}
					
				}
			}
			if( $have_to_add > 0){
				
				?>
				<div class="col s6 m3 l3">
					<?php  
					get_template_part ('phpincludes/part-archive-item-release-small');
					?>
				</div>
				<?php  
				$have_to_add = 0;
			}
		}
	endwhile; endif;
	wp_reset_postdata();
	return ob_get_clean();
}}

/* Get artist releases by artist name
============================================= */
if(!function_exists('kentha_get_artist_events')){
function kentha_get_artist_events($artist_id){
	if(!$artist_id){
		return;
	}
	$args = array(
		'post_type' => 'event',
		'posts_per_page' => -1,
		'posts_status' => 'publish',
		'meta_query' => array(
		 	array(
				'key'		=> 'event_lineup',
				'value'		=> maybe_serialize( array('0' => strval($artist_id) ) ),
				'compare'	=> 'LIKE',
		 	),
	   ),
	);
	$wp_query = new WP_Query( $args );
	if ( !$wp_query->have_posts() ){
		return false;
	}
	ob_start();
	if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		get_template_part( 'phpincludes/part-event-inline-compact' )  ;
	endwhile; endif;
	wp_reset_postdata();
	return ob_get_clean();
}}



/* Get artist releases by artist name
============================================= */
if(!function_exists('kentha_get_artist_products')){
function kentha_get_artist_products($artist_id){
	if(!$artist_id){
		return;
	}
	$args = array(
		'post_type' => 'product',
		'posts_per_page' => -1,
		'posts_status' => 'publish',
		'meta_query' => array(
		 	array(
				'key'		=> 'kentha_artist',
				'value'		=> sprintf(':"%s";', $artist_id),
				'compare'	=> 'like',
		 	),
	   ),
	);
	$wp_query = new WP_Query( $args );
	if ( !$wp_query->have_posts() ){
		return false;
	}
	ob_start();
	if ( $wp_query->have_posts() ) :
		?>
			<div class="qt-playlist-large qt-short-products-singletracks qt-woocommerce-singletrack-loop qt-paper qt-card">
				<ul class="qt-playlist qt-card">
					<?php
						while ( $wp_query->have_posts() ) : $wp_query->the_post();
							global $post;
							$post = $wp_query->post;
							setup_postdata( $post );
							get_template_part( 'phpincludes/part-archive-item-product-singletrack' )  ;
							wp_reset_postdata();
						endwhile;
					?>
				</ul>
			</div>
		<?php
	endif;
	return ob_get_clean();
}}


/* Disable SPAN wrapper for CF7
=============================================*/
add_filter('wpcf7_form_elements', function($content) {
	if(!$content) {
		return $content;
	}
	$content = preg_replace('/<(span).*?class="\s*(?:.*\s)?wpcf7-form-control-wrap(?:\s[^"]+)?\s*"[^\>]*>(.*)<\/\1>/i', '\2', $content);
	return $content;
});

/* Tags formatting
=============================================*/
if ( ! function_exists( 'kentha_custom_tag_cloud_widget' ) ) {
function kentha_custom_tag_cloud_widget($args) {
	$args['number'] = '26'; //adding a 0 will display all tags
	$args['largest'] = '11'; //largest tag
	$args['smallest'] = '11'; //smallest tag
	$args['unit'] = 'px'; //tag font unit
	return $args;
}}
add_filter( 'widget_tag_cloud_args', 'kentha_custom_tag_cloud_widget' );

/* Remove playlist if necessary
=============================================*/
if(!function_exists('kentha_remove_playlist_shortcodes')){
function kentha_remove_playlist_shortcodes($content) {  
	// wordpress function provides a regex to get any shortcode from your content
	$pattern = get_shortcode_regex(); 
	preg_match('/'.$pattern.'/s', $content, $matches);
	if ( isset($matches[2]) && is_array($matches) && $matches[2] == 'playlist') {
		
		$content = str_replace( $matches['0'], '', $content );
	}
	return $content;
}}

/* Transform string to slug
=============================================*/
if(!function_exists('kentha_slugify')){
function kentha_slugify($string, $replace = array(), $delimiter = '-') {
  // https://github.com/phalcon/incubator/blob/master/Library/Phalcon/Utils/Slug.php
  if (!extension_loaded('iconv')) {
	throw new Exception('iconv module not loaded');
  }
  // Save the old locale and set the new locale to UTF-8
  $oldLocale = setlocale(LC_ALL, '0');
  setlocale(LC_ALL, 'en_US.UTF-8');
  $clean = iconv('UTF-8', 'ASCII//TRANSLIT', $string);
  if (!empty($replace)) {
	$clean = str_replace((array) $replace, ' ', $clean);
  }
  $clean = preg_replace("/[^a-zA-Z0-9\/_|+ -]/", '', $clean);
  $clean = strtolower($clean);
  $clean = preg_replace("/[\/_|+ -]+/", $delimiter, $clean);
  $clean = trim($clean, $delimiter);
  // Revert back to the old locale
  setlocale(LC_ALL, $oldLocale);
  return $clean;
}}

/* Kentha content filter to replace default playlist with custom one
=============================================*/
if(!function_exists('kentha_content_filter')){
function kentha_content_filter($content) {
	if ( has_shortcode( $content, 'playlist' ) && kentha_has_player()) { 
		$pattern = get_shortcode_regex(); 
		preg_match('/'.$pattern.'/s', $content, $matches);
		if ( isset($matches[2]) && is_array($matches) && $matches[2] == 'playlist') {
			$content = str_replace( $matches['0'], '', $content );
		}
	}
	// otherwise returns the database content
	return $content;
}}
add_filter( 'the_content', 'kentha_content_filter' );

/* Custom number formatting, used in social counter
=============================================*/
if(!function_exists('kentha_number_format')){
function kentha_number_format($n, $precision = 3) {
	if ($n < 1000) {
		$n_format = number_format($n);
	} else if ($n < 1000000) {
		$n_format = number_format($n / 1000, $precision) . 'K';
	} else if ($n < 1000000000) {
		$n_format = number_format($n / 1000000, $precision) . 'M';
	} else {
		$n_format = number_format($n / 1000000000, $precision) . 'B';
	}
	return $n_format;
}}

/* Make header text negative if we have a background picture, even if there is a light color scheme
=============================================*/
if(!function_exists('kentha_is_negative')){
function kentha_is_negative() {
	$bg = get_theme_mod("kentha_sitebg");
	$pagebg = false;
	if(is_page() || is_singular() || is_attachment() || is_single()){
		$pagebg = get_post_meta( get_the_id(), 'kentha_image_bg', true );
	}
	if($bg || $pagebg){
		echo 'qt-negative';
	}
	return;
}}
if(!function_exists('kentha_comment_is_negative')){
function kentha_comment_is_negative() {
	$bg = get_theme_mod("kentha_sitebg");
	$pagebg = false;
	$page_fadeout = false;
	if(is_page() || is_singular() || is_attachment() || is_single()){
		$pagebg = get_post_meta( get_the_id(), 'kentha_image_bg', true );
		$page_fadeout = get_post_meta( get_the_id(), 'kentha_fadeout', true );
	}
	if($bg || $pagebg){
		if(!$page_fadeout){
			echo 'qt-negative';
		} 
	}
	return;
}}

/* Correctly encode url for sharing
=============================================*/
if(!function_exists('kentha_encodeURIComponent')){
function kentha_encodeURIComponent($str) {
	$revert = array('%21'=>'!', '%2A'=>'*', '%27'=>"'", '%28'=>'(', '%29'=>')');
	return strtr(rawurlencode($str), $revert);
}}

/* 	Instead of allowing $content we use this function for the content of external plugins such
*	as Visual Composer because it needs to be outputted like it is as may contain js and other stuff, but is already sanitarized and
*	can't be sanitized again, but with this function we are sure that we are not allowing
*	unsanitarized contents.	
=============================================*/
if(!function_exists('kentha_sanitize_content')){
function kentha_sanitize_content($c) {
	return $c;
}}


/**
 * 
 * Remove custom socials from Core plugin.
 * =============================================
 */

remove_filter('user_contactmethods', 'qantumthemes_modify_contact_methods');


/**
 * 
 * User special fields
 * =============================================
 */

/* Remove custom author social links from theme core plugin settings
=============================================*/
remove_filter('user_contactmethods', 'qantumthemes_modify_contact_methods');
function kentha_get_qt_user_social(){
	$qt_user_social = array(
		"twitter" => array(
						'label' => esc_html__( 'Twitter Url' , "kentha" ),
						'icon' => "qt-socicon-twitter" )
		,"facebook" => array(
						'label' => esc_html__( 'Facebook Url' , "kentha" ),
						'icon' => "qt-socicon-facebook" ) 
		,"google" => array(
						'label' => esc_html__( 'Google Url' , "kentha" ),
						'icon' => "qt-socicon-google" )
		,"flickr" => array(
						'label' => esc_html__( 'Flickr Url' , "kentha" ),
						'icon' => "qt-socicon-flickr" )
		,"pinterest" => array(
						'label' => esc_html__( 'Pinterest Url' , "kentha" ),
						'icon' => "qt-socicon-pinterest" )
		,"amazon" => array(
						'label' => esc_html__( 'Amazon Url' , "kentha" ),
						'icon' => "qt-socicon-amazon" )
		,"soundcloud" => array(
						'label' => esc_html__( 'Soundcloud Url' , "kentha" ),
						'icon' => "qt-socicon-cloud" )
		,"vimeo" => array(
						'label' => esc_html__( 'Vimeo Url' , "kentha" ),
						'icon' => "qt-socicon-vimeo" )
		,"tumblr" => array(
						'label' => esc_html__( 'Tumblr Url' , "kentha" ),
						'icon' => "qt-socicon-tumblr" )
		,"youtube" => array(
						'label' => esc_html__( 'Youtube Url' , "kentha" ),
						'icon' => "qt-socicon-youtube" )
		,"wordpress" => array(
						'label' => esc_html__( 'WordPress Url' , "kentha" ),
						'icon' => "qt-socicon-wordpress" )
		,"wikipedia" => array(
						'label' => esc_html__( 'Wikipedia Url' , "kentha" ),
						'icon' => "qt-socicon-wikipedia" )
		,"instagram" => array(
						'label' => esc_html__( 'Instagram Url' , "kentha" ),
						'icon' => "qt-socicon-instagram" )
	);
	return $qt_user_social;
}
$qt_user_social = kentha_get_qt_user_social();
if ( ! function_exists( 'kentha_modify_contact_methods' ) ) {
function kentha_modify_contact_methods( $profile_fields ) {
	global $qt_user_social;
	foreach ( $qt_user_social as $q => $v ){
		$profile_fields[$q] = $v['label'];
	}
	return $profile_fields;
}}
add_filter('user_contactmethods', 'kentha_modify_contact_methods');
/*
*	Saving the user meta
*/
add_action( 'personal_options_update', 'kentha_save_extra_profile_fields' );
add_action( 'edit_user_profile_update', 'kentha_save_extra_profile_fields' );
function kentha_save_extra_profile_fields( $user_id ) {
	if ( !current_user_can( 'edit_user', $user_id ) )
		return false;
	global $qt_user_social;
	foreach ( $qt_user_social as $q => $v ){
		 update_user_meta( $user_id, $q , esc_url($_POST[$q]), esc_url(get_the_author_meta( $q , $user_id )) );
	}
}
/**
 * 
 * Create user social icons
 * =============================================
 */
if(!function_exists('kentha_user_social_icons')) {
function kentha_user_social_icons($id = null){
	if(null === $id){
		return;
	}
	$qt_user_social = kentha_get_qt_user_social();
	foreach($qt_user_social as $var => $val){
		$link = get_the_author_meta( $var , $id);
		if(!empty($link)){
			?>
			<a href="<?php echo esc_url($link); ?>" class="qt-social-author qt-disableembedding" target="_blank"><i class="<?php echo esc_attr($val['icon']); ?>"></i></a>
			<?php
		}
	}
}}



/**
 * 
 * playlist by ID
 * =============================================
 */
if(!function_exists('kentha_playlist_by_id')) {
function kentha_playlist_by_id($id = null){
	if (!$id ) {
		return;
	}
	ob_start();
	$linked_release_id = $id;
	$events = get_post_meta($linked_release_id, 'track_repeatable');
	if(array_key_exists(0, $events)){
		$n = 1;
		$events = $events[0];
		$thumb = get_the_post_thumbnail_url( $linked_release_id ,'kentha-squared');
		$title = get_the_title( $linked_release_id );
		$link = get_the_permalink( $linked_release_id );
		// Classic playlist created via metadata
		foreach($events as $track){ 
			$neededEvents = array('releasetrack_track_title','releasetrack_scurl','releasetrack_buyurl','releasetrack_artist_name', 'add_shopping_cart', 'icon_type', 'price');
			foreach($neededEvents as $ne){
				if(!array_key_exists($ne,$track)){
					$track[$ne] = '';
				}
			}
			if($track['releasetrack_mp3_demo'] == ''){
					continue;
				}
			$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
			switch ($track['icon_type']){
				case "download": 
					$icon = 'file_download';
					break;
				case "cart": 
				default:
					$icon = 'add_shopping_cart';
			}
			/**
			 * [$price track price]
			 * @since kentha 1.3.5
			 * @since kentha player 1.9.0
			 */
			$price = $track['price'];
			?>
			<li class="qtmusicplayer-trackitem">
				<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($track['releasetrack_mp3_demo']); ?>" data-qtmplayer-title="<?php echo esc_attr($track['releasetrack_track_title']); ?>" data-qtmplayer-artist="<?php echo esc_attr($track['releasetrack_artist_name']); ?>" data-qtmplayer-album="<?php echo esc_attr($title); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_url($track['releasetrack_buyurl']); ?>" data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" data-qtmplayer-price="<?php echo esc_url($track['price']); ?>"  ><i class='material-icons'>play_circle_filled</i></span>
				<p>
					<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($track['releasetrack_track_title']); ?></span><br>
					<span class="qt-art">
						<?php echo esc_attr($track['releasetrack_artist_name']); ?>
					</span>
				</p>
				<?php
				if($track['releasetrack_buyurl'] !== ''){ 
					/**
					 *
					 * WooCommerce update:
					 *
					 */
					$buylink = $track['releasetrack_buyurl'];
					if(is_numeric($buylink)) {
						$prodid = $buylink;
						$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
						?>
						<a href="<?php echo esc_attr($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart">
						<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
						</a>
						<?php 
					} else {
						?>
						<a href="<?php echo esc_attr($buylink); ?>" class="qt-cart" target="_blank">
						<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
						</a>
						<?php
					}
				} 
				?>
			</li>

			<?php 
			$n = $n + 1;
		} 
	}

	/**
	 * Special playlist created from WP playlist
	 * 
	 * Extract songs from embedded playlist
	 */


	$content = get_post_field('post_content', $linked_release_id);
	if ( has_shortcode($content, 'playlist') ) { 
		$pattern = get_shortcode_regex();
		preg_match_all('/'.$pattern.'/s', $content, $matches);
		$lm_shortcode = array_keys($matches[2],'playlist'); // lista di tutti gli ID di shortcodes di tipo playlist. Se ne ho 1 torna 0
		if (count($lm_shortcode) > 0) {
			$buylink_std = '';
			$buy_links = get_post_meta($linked_release_id, 'track_repeatablebuylinks', false);
			if(array_key_exists(0, $buy_links)){
				$data = $buy_links[0];
				if(count($data)>0){
					$buylink_std = $data[0]['cbuylink_url'];
				}
			}
			foreach($lm_shortcode as $sc) {
				$string_data =  $matches[3][$sc];
				$array_param = shortcode_parse_atts($string_data);
				if(array_key_exists("ids",$array_param)){
					$ids_array = explode(',', $array_param['ids']);
					foreach($ids_array as $audio_id){
						$tracktitle = get_the_title($audio_id);
						$metadata = wp_get_attachment_metadata($audio_id);
						$artist = '';
						if(array_key_exists('artist', $metadata)){
							$artist = $metadata['artist'];
						}
						$file = wp_get_attachment_url($audio_id);
						$buyurl = false; // for now we have no buy URL for drop-in tracks (how can we? Copy buy from album?)
						$icon = '';
						$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
						?>
						<li class="qtmusicplayer-trackitem">
							<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($file); ?>" data-qtmplayer-title="<?php echo esc_attr($tracktitle); ?>" data-qtmplayer-artist="<?php echo esc_attr($artist); ?>" data-qtmplayer-album="<?php echo esc_attr($title); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_attr( $buylink_std); ?>" data-qtmplayer-icon="" ><i class='material-icons'>play_circle_filled</i></span>
							<p>
								<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($tracktitle); ?></span><br>
								<span class="qt-art">
									<?php echo esc_attr($artist); ?>
								</span>
							</p>
							<?php 
							if($buyurl){ 
								/**
								 *
								 * WooCommerce update:
								 * NO CART FOR NOW, these are drop-in track and we can't specify a single purchase link for each one,
								 * so the function is here in place but the $buyurl will be empty for now and no icon will appear.
								 * If one day we figure out how to manage this, the code is already here.
								 *
								 */
								$buylink = $buyurl;
								if(is_numeric($buylink)) {
									$prodid = $buylink;
									$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
									?>
									<a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
									<?php  
								} else {
									?>
									<a href="<?php echo esc_url($buylink); ?>" class="qt-cart" target="_blank"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
									<?php
								}
							} ?>
						</li>
						<?php 
						$n = $n + 1;
					}
				}
				$active = '';
			}
		}
	}
	return ob_get_clean();
}}



/**
 * 
 * Used by shortcodes autocomplete
 * =============================================
 */
if(!function_exists('kentha_get_type_posts_data')) {
function kentha_get_type_posts_data( $post_type = 'post' ) {
	$posts = get_posts( array(
		'posts_per_page' 	=> -1,
		'post_type'			=> $post_type,
	));
	$result = array();
	foreach ( $posts as $post )	{
		$result[] = array(
			'value' => $post->ID,
			'label' => $post->post_title,
		);
	}
	return $result;
}}





/* Get artist podcasts by artist name
============================================= */
if(!function_exists('kentha_get_artist_podcasts')){
function kentha_get_artist_podcasts($artist_title){
	ob_start();
	// echo 'received artist title esc_sql: '.urlencode($artist_title);
	if(!$artist_title){
		return;
	}
	$args = array(
		'post_type' => 'podcast',
		'posts_per_page' => -1,
		'posts_status' => 'publish',
		'meta_query' => array(
			'relation' => 'OR',
			array(
				'key' => '_podcast_artist',
				'value' => ",".$artist_title." ",
				'compare' => 'LIKE'
			),
			array(
				'key' => '_podcast_artist',
				'value' => " ".$artist_title,
				'compare' => 'LIKE'
			),
			array(
				'key' => '_podcast_artist',
				'value' => $artist_title." ",
				'compare' => 'LIKE'
			),
			array(
				'key' => '_podcast_artist',
				'value' => '"'.$artist_title.'"',
				'compare' => 'LIKE'
			)
		)
	);
	$wp_query = new WP_Query( $args );
	if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		?>
		<div class="col s6 m3 l3">
			<?php  
			get_template_part ('phpincludes/part-archive-item-podcast-small');
			?>
		</div>
		<?php  
	endwhile; endif;
	wp_reset_postdata();
	return ob_get_clean();
}}



/**
 * ======================================================
 * Post categories template output
 * ------------------------------------------------------
 * Display post categories
 * ======================================================
 */

if(!function_exists('kentha_postcategories')){
function kentha_postcategories( $quantity = 1, $tax = 'category'){
	
	if( $tax == 'category' ){
		$categories = get_the_category(); 
	} else {
		$categories =  get_the_terms( get_the_ID(), $tax );
		if ( ! $categories || is_wp_error( $categories ) ) {
	    	$categories = array();
	    }
	    // from https://core.trac.wordpress.org/browser/tags/5.2.1/src/wp-includes/category-template.php#L0
	    $categories = array_values( $categories );
	    if(function_exists('_make_cat_compat')){
		    foreach ( array_keys( $categories ) as $key ) {
				_make_cat_compat( $categories[ $key ] );
			}
		}
	}

	if( count($categories) > 0 ){
		$limit = $quantity - 1 ;
		foreach($categories as $i => $cat){
			if($i <= $limit){	
				?><a href="<?php echo get_category_link($cat->term_id ); ?>" class="kentha-catid-<?php echo esc_attr($cat->term_id ); ?>"><?php echo esc_html($cat->cat_name); ?></a><?php
			}
		}
	}
}}



/**
 * ======================================================
 * Post categories template output
 * ------------------------------------------------------
 * Display post categories WITHOUT LINK used in product data attributes for player
 * ======================================================
 */

if(!function_exists('kentha_postcategories_text')){
function kentha_postcategories_text( $quantity = 1, $tax = 'category'){
	
	if( $tax == 'category' ){
		$categories = get_the_category(); 
	} else {
		$categories =  get_the_terms( get_the_ID(), $tax );
		if ( ! $categories || is_wp_error( $categories ) ) {
	    	$categories = array();
	    }
	    // from https://core.trac.wordpress.org/browser/tags/5.2.1/src/wp-includes/category-template.php#L0
	    $categories = array_values( $categories );
	    if(function_exists('_make_cat_compat')){
		    foreach ( array_keys( $categories ) as $key ) {
				_make_cat_compat( $categories[ $key ] );
			}
		}
	}

	if( count($categories) > 0 ){
		$limit = $quantity - 1 ;
		foreach($categories as $i => $cat){
			if($i <= $limit){	
				if($i > 0 ){
					echo ', ';
				}
				echo esc_html($cat->cat_name);

			}
		}
	}
}}


// end