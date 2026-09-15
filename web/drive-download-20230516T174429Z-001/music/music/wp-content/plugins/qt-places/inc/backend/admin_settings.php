<?php


include plugin_dir_path( __FILE__ ) .'_utils.php'; 
include plugin_dir_path( __FILE__ ) .'_create_form.php'; 
include plugin_dir_path( __FILE__ ) .'_options_page.php'; 
include plugin_dir_path( __FILE__ ) .'qt_tinymce_extensions/qt-tinymce-buttons.php'; 

/*
*	Scripts and styles Backend
*	=============================================================
*/
if(!function_exists('qt_mapsAdmin')){
function qt_mapsAdmin(){
	wp_enqueue_style( 'qtMaps_css_admin', plugins_url( '/assets/style-admin.css', __FILE__));
	wp_enqueue_style( 'wp-color-picker' );
}}
add_action('admin_head', 'qt_mapsAdmin');

if(!function_exists('qt_maps_loader_backend')){
function qt_maps_loader_backend(){

	$jsdependency= array("jquery", 'farbtastic','wp-color-picker');



	if(!get_option('qtmap_disable_googlemaps', false )) {
		$mapsurl = 'https://maps.googleapis.com/maps/api/js';
		$key = get_option("qtGoogleMapsApiKey", false);
		if($key) {
			$mapsurl = add_query_arg("key", esc_attr(trim($key)), $mapsurl);
		}
		wp_enqueue_script('qt-google-maps',$mapsurl, false, false, true);
		$jsdependency[] = 'qt-google-maps';
		
	}

	if(!get_option('qtmap_disable_googlemapsjs', false )) {
		wp_enqueue_script('google-jsapi','https://www.google.com/jsapi',$jsdependency); // not needed
		$jsdependency[] = 'google-jsapi';
		
	}

	wp_enqueue_script( 'qqtMaps_Admin',plugins_url( '/assets/qtmaps-admin.js' , __FILE__ ), $jsdependency , $ver = false, $in_footer = true );
}}
add_action("admin_enqueue_scripts",'qt_maps_loader_backend');


