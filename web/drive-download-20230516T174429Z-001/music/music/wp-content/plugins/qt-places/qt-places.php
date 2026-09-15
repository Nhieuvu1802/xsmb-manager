<?php
/*
Plugin Name: QT Places
Plugin URI: http://www.qantumthemes.com/
Description: Create dynamic maps of events, stores or any other content
Author: QantumThemes
Version: 1.8.2
Text Domain: qt-places
Domain Path: /languages
*/

/**
 *
 *	The plugin textdomain
 * 
 */


if(!function_exists('qtplaces_load_textdomain')){
function qtplaces_load_textdomain() {
  load_plugin_textdomain( 'qt-places', FALSE, basename( dirname( __FILE__ ) ) . '/languages' );
}}
add_action( 'plugins_loaded', 'qtplaces_load_textdomain' );


/**
 *
 *	Files inclusion
 * 
 */
$active_plugins = (array) get_option( 'active_plugins', array() );
if ( ! empty( $active_plugins ) && in_array( 'ttg-core/ttg-core.php', $active_plugins ) ) {
    // do nothing here
} else {

	if(!function_exists('custom_meta_box_field') ){
		require	plugin_dir_path( __FILE__ ) . '/inc/backend/metaboxes/meta_box.php';
	}
}



require plugin_dir_path( __FILE__ ) . '/inc/backend/custom-types/qt-places/places.php';
require plugin_dir_path( __FILE__ ) . '/inc/backend/admin_settings.php';
require plugin_dir_path( __FILE__ ) . '/inc/frontend/frontend.php';