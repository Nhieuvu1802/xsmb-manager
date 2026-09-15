<?php  
/*
Plugin Name: QT Kentha Ajax Pageload
Plugin URI: http://qantumthemes.com
Description: Adds page load with ajax to keep music playing across pages
Version: 1.3.3
Author: QantumThemes
Author URI: http://qantumthemes.com
*/

function qt_ajax_pageload_is_active(){
	return true;
}



/**
 * 	Enqueue scripts
 * 	=============================================
 */
if(!function_exists('qt_ajax_pageload_enqueue_scripts')){
function qt_ajax_pageload_enqueue_scripts(){
	if(is_user_logged_in()){
		if(current_user_can('edit_pages' )){
			return;
		}
	}
	// css already in the theme styles
	// wp_enqueue_style('qt_ajax_pageload_style', plugin_dir_url(__FILE__).'qt-apl-style.css' );
	
	if(get_theme_mod("kentha_enable_debug", 0)){
		wp_enqueue_script('qt_ajax_pageload_script', plugin_dir_url(__FILE__).'js/qt-kentha-ajax-pageload.js', array('jquery', 'kentha-qt-main-script'), '1.0', true );
	} else {
		wp_enqueue_script('qt_ajax_pageload_script', plugin_dir_url(__FILE__).'js/min/qt-kentha-ajax-pageload-min.js', array('jquery', 'kentha-qt-main-script'), '1.0', true );
	}
	
}}
add_action( 'wp_enqueue_scripts', 'qt_ajax_pageload_enqueue_scripts' );

/**
 * 	Skip ajax pageload custom field
 * 	=============================================
 */

if(!function_exists("qtapl_add_special_fields")){
	add_action('init', 'qtapl_add_special_fields',0,999);  
	function qtapl_add_special_fields() {
	    $qtapl_settings = array (
	    	array (
				'label' => esc_attr__('Disable ajax loading',"qt-ajax-pageload"),
				'desc' 	=> esc_attr__('Load this page without ajax (music stops, fix plugins compatibility issues)',"qt-ajax-pageload"),
				'id' 	=> 'qtapl_skip',
				'type' 	=> 'checkbox'
			)        
	    );
	    if(post_type_exists('page')){
	        if(function_exists('custom_meta_box_field')){
	            $main_box = new custom_add_meta_box('qtapl_settings', 'Ajax loading settings', $qtapl_settings, 'page', true );
	        }
	    }
	}
}



/* Add user agent to body for css classes fix
=============================================*/
if ( ! function_exists( 'qtapl_class_names' ) ) {
	add_filter( 'body_class','qtapl_class_names' );
	function qtapl_class_names( $classes ) {
		if( is_singular() || is_page() ) {
			if( get_post_meta( get_the_ID(), 'qtapl_skip', true ) ){
				$classes[] = "qtapl-skip";
			}
		} 
		return $classes;
	}
}

/* Pass WooCommerce endpoint URLs to javascript
=============================================*/
require plugin_dir_path( __FILE__ ) . '/_woocommerce-support.php';

