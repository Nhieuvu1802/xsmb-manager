<?php
/**
 *
 *	@package QT Places
 *  Frontend functions
 * 
 */

include '_custom-styles.php'; 
include '_shortcodes.php'; 

/*
*	Scripts and styles Frontend
*	============================================================= */

/* important: wordpress is adding #038 to the api key breaking the script. this is the fix. */
add_filter('clean_url', 'so_handle_038', 99, 3);
if(!function_exists('so_handle_038')) {
function so_handle_038($url, $original_url, $_context) {
    if (strstr($url, "googleapis.com") !== false) {
        $url = str_replace("&#038;", "&", $url); // or $url = $original_url
    }
    return $url;
}}


function qt_maps_loader(){
	$jsdependency = array();
	if(!get_option('qtmap_disable_googlemaps', false )) {
		$mapsurl = 'https://maps.googleapis.com/maps/api/js';
		$key = get_option("qtGoogleMapsApiKey", false);
		if($key) {
			$mapsurl = add_query_arg("key", esc_attr(trim($key)), $mapsurl);
		}
		wp_enqueue_script('qt-google-maps',$mapsurl, false, false, true);
		$jsdependency[] = 'qt-google-maps';
		
	} else {
		// echo '<!-- Google Maps Script disabled -->';
	}

	if(!get_option('qtmap_disable_googlemapsjs', false )) {
		wp_enqueue_script('google-jsapi','https://www.google.com/jsapi',$jsdependency); // not needed
		$jsdependency[] = 'google-jsapi';
		
	}

  	wp_enqueue_script( 'jquery');
	wp_enqueue_script( 'qtPlacesScript',plugins_url( '/assets/min/script-min.js' , __FILE__ ), $deps = array("jquery",'google-jsapi','qt-google-maps'), $ver = false, $in_footer = true );
	wp_enqueue_style( 'qtPlacesStyle',plugins_url( '/assets/styles.css' , __FILE__ ),false);
	wp_enqueue_style( 'font-awesome','https://maxcdn.bootstrapcdn.com/font-awesome/4.6.0/css/font-awesome.min.css',false);
}
add_action("wp_enqueue_scripts",'qt_maps_loader');


/**
 * Update from version 1.6:
 * we can link any post to an existing Place
 */




if(!function_exists('qt_places_hooked_place')){
	add_filter( 'get_post_metadata', 'qt_places_hooked_place', 100, 4 );
	function qt_places_hooked_place($metadata, $object_id, $meta_key, $single){


		if($meta_key == 'qt_places_associated_place')return; // do not remove or server collapses due to recurring function

		// 1: check if this post has associated place
		$associated_place = get_post_meta( $object_id, 'qt_places_associated_place', true );
		$associated_place_id = false;
		if(is_array($associated_place)){
			if(array_key_exists(0, $associated_place)){
				if(is_numeric($associated_place[0])) {
					$associated_place_id = $associated_place[0];
				}
			}
		}

		if($associated_place_id && (
			$meta_key == 'qt_location'
			|| $meta_key == 'qt_address'
			|| $meta_key == 'qt_city'
			|| $meta_key == 'qt_country'
			|| $meta_key == 'qt_coord'
			|| $meta_key == 'qt_link'
			|| $meta_key == 'qt_phone'
			|| $meta_key == 'qt_email'
			|| $meta_key == 'qt_placeicon'
			|| $meta_key == 'qt_placeicondesign'
			|| $meta_key == 'qt_placeiconcolor'
		)) {

			remove_filter( 'get_post_metadata', 'qt_places_hooked_place', 100 );
	        $current_meta = get_post_meta( $associated_place_id, $meta_key, $single );
	        add_filter('get_post_metadata', 'qt_places_hooked_place', 100, 4);
	        return $current_meta;
		}

		return $metadata;

	}
}

