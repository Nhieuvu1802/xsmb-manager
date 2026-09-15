<?php  
/*
Plugin Name: QT Kentha Preloader
Plugin URI: http://qantumthemes.com
Description: Preload html and images before showing the page fot he kentha theme
Version: 1.0.0
Author: QantumThemes
Author URI: http://qantumthemes.com
*/
function qt_kentha_preloader_is_active(){
	return true;
}


/**
 * 	Enqueue scripts
 * 	=============================================
 */
if(!function_exists('qt_kentha_preloader_enqueue_scripts')){
function qt_kentha_preloader_enqueue_scripts(){
	if(is_user_logged_in()){
		if(current_user_can('edit_pages' )){
			return;
		}
	}
	if(get_theme_mod("kentha_enable_debug", 0)){
		wp_enqueue_script('qt_kentha_preloader_script', plugin_dir_url(__FILE__).'js/qt-kentha-preloader.js', array('jquery'), '1.0', true );
	} else {
		wp_enqueue_script('qt_kentha_preloader_script', plugin_dir_url(__FILE__).'js/min/qt-kentha-preloader-min.js', array('jquery'), '1.0', true );
	}
}}
add_action( 'wp_enqueue_scripts', 'qt_kentha_preloader_enqueue_scripts', 0 );



/* Add classes to body
=============================================*/
if ( ! function_exists( 'qt_kentha_preloader_class_names' ) ) {
function qt_kentha_preloader_class_names($classes) {
	if(is_user_logged_in()){
		if(current_user_can('edit_pages' )){
			return;
		}
	}
	$classes[] = "qt-body-preloading";

	return $classes;
}}
add_filter('body_class','qt_kentha_preloader_class_names');