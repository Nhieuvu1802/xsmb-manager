<?php  
/**
* Plugin Name: QT Chartvote
* Plugin URI: http://qantumthemes.com
* Description: Adds a vote button to tracks in charts
* Version: 1.2
* Author: QantumThemes
* Author URI: http://qantumthemes.com
* Text Domain: qt-chartvote
* Domain Path: /languages
* @package qt-chartvote
*/

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

/**
 *
 *	For theme to check if is active
 * 
 */
function qt_chartvote_active() {
	return true;
}


/**
* Returns current plugin version.
* @return string Plugin version
*/
if(!function_exists('qt_chartvote_plugin_get_version')){
function qt_chartvote_plugin_get_version() {
	$plugin_data = get_plugin_data( __FILE__ );
	$plugin_version = $plugin_data['Version'];
	return $plugin_version;
}}

$timebeforerevote = 120; // = 2 hours






/**
 * 	language files
 * 	=============================================
 */
if(!function_exists('qt_chartvote_load_text_domain')){
function qt_chartvote_load_text_domain() {
	load_plugin_textdomain( 'qt-chartvote', false, dirname( plugin_basename( __FILE__ ) ) . '/languages/' );
}}
add_action( 'init', 'qt_chartvote_load_text_domain' );





/**
 * 	includes
 * 	=============================================
 */
require plugin_dir_path( __FILE__ ) . '/includes/frontend/qt-chartvote-shortcode.php';
require plugin_dir_path( __FILE__ ) . '/includes/backend/qt-chartvote-functions.php';

/**
 * 	hooks
 * 	=============================================
 */
add_action('wp_ajax_nopriv_track-vote', 'qt_chartvote_track_vote');
add_action('wp_ajax_track-vote', 'qt_chartvote_track_vote');

/**
 * 	Enqueue scripts
 * 	=============================================
 */
if(!function_exists('qt_chartvote_enqueue_stuff')){
function qt_chartvote_enqueue_stuff(){
	wp_enqueue_script('jquery-cookie', plugins_url('js/jquery.cookie.js'	, __FILE__ ) , array('jquery'), qt_chartvote_plugin_get_version(), true ) ;

	wp_enqueue_style( $handle = "dripicons",  plugins_url('dripicons/webfont.css'	, __FILE__ ), false, qt_chartvote_plugin_get_version(), "all" );

	wp_enqueue_script('qt-chartvote-script', plugins_url('js/qt-chartvote-script.js'	, __FILE__ ) , array('jquery','jquery-cookie'), qt_chartvote_plugin_get_version(), true );
	
	wp_localize_script('qt-chartvote-script', 'chartvote_ajax_var', array(
	    'url' => admin_url('admin-ajax.php'),
	    'nonce' => wp_create_nonce('chartvote-nonce')
	));
}}

add_action( 'wp_enqueue_scripts', 'qt_chartvote_enqueue_stuff', -9999999999 );
