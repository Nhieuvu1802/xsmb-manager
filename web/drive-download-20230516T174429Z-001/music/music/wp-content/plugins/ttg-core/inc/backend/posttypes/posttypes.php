<?php  
/**
 *
 *	Posttypes.php
 *	Author: Igor Nardo (Themes2Go - Qantumthemes)
 *	This component is a wrapper for custom types and taxonomies,
 *	so the themes can customize those aspetcs without editing the engine of the backend
 *	and adding maintainability to the software.
 * 
 */


if(!function_exists('ttg_custom_post_type')) {
	function ttg_custom_post_type( $id = '', $args = array() ) {
		register_post_type($id, $args);
	}
}



if(!function_exists('ttg_custom_taxonomy')) {
	function ttg_custom_taxonomy( $taxonomy = '', $object_type = '' , $args = '') {
		register_taxonomy( $taxonomy, $object_type, $args );
	}
}
