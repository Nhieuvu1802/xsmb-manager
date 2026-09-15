<?php  
/*
Plugin Name: QT Kentha Widgets
Plugin URI: http://www.qantumthemes.xyz
Description: Adds custom widgets to Kentha
Version: 1.0.7
Author: QantumThemes
Author URI: http://www.qantumthemes.xyz
Text Domain: kentha-widgets
Domain Path: /languages
*/

/**
 *
 *	The plugin textdomain
 * 	=============================================
 */
if(!function_exists('kentha_widgets_load_plugin_textdomain')){
function kentha_widgets_load_plugin_textdomain() {
	load_plugin_textdomain( 'kentha-widgets', FALSE, plugin_dir_path( __FILE__ ) . 'languages' );
}}
add_action( 'plugins_loaded', 'kentha_widgets_load_plugin_textdomain' );

/**
 * 	includes
 * 	=============================================
 */
include ( plugin_dir_path( __FILE__ ) . 'widgets/widget-contacts.php');
include ( plugin_dir_path( __FILE__ ) . 'widgets/widget-archives-list.php');
