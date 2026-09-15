<?php
/*
Plugin Name: QT Kentha Contactform
Plugin URI: http://qantumthemes.com
Description: Adds contact form and details to a Kentha theme page. This is NOT a generic form plugin like CF7, is meant to add a quick and easy contact form on certain pages. It allows very few options. You will find a recipient and privacy field on artist pages and similar to enable it.
Version: 1.0.3
Author: QantumThemes
Author URI: http://qantumthemes.com
Text Domain: qt-kentha-contactform
Domain Path: /languages
*/


/**
 * 	language files
 * 	=============================================
 */
if(!function_exists('qt_kentha_contactform_load_text_domain')){
function qt_kentha_contactform_load_text_domain() {
	load_plugin_textdomain( "qt-kentha-contactform", false, dirname( plugin_basename( __FILE__ ) ) . '/languages/' );
}}
add_action( 'init', 'qt_kentha_contactform_load_text_domain' );


require plugin_dir_path( __FILE__ ) . '_custom_fields.php';
require plugin_dir_path( __FILE__ ) . '_form.php';
