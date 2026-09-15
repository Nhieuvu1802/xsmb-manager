<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0
 * @version  2.0
 * @author QantumThemes 2019 Oct 08
 * 
 * Add body class to product single track
 * 
 */
/**
 * Add filter to body class
 */
if(!function_exists('kentha_singletrack_product_bodyclass')){
	add_filter( 'body_class', 'kentha_singletrack_product_bodyclass' );
	function kentha_singletrack_product_bodyclass( $classes ){
	  	if( is_singular( 'product' ) ){
			if ( '1' == get_post_meta( get_the_ID(), 'kentha_singletrack', true ) ){
				$classes[] = 'qt-kentha-productpage-singletrack';
			}
			if ( '1' == get_post_meta( get_the_ID(), 'kentha_hideinfo', true ) ){
				$classes[] = 'qt-kentha-productpage-hideinfo';
			}
			
	  	}
	  	return $classes;
	}
}
	


/**
 * Add filter to loop class
 */
if(!function_exists('kentha_product_css_class_singletrack')){
	add_filter( 'post_class', 'kentha_product_css_class_singletrack', 10,3 );
	function kentha_product_css_class_singletrack( $classes, $class, $post_id ) {
		if('product' == get_post_type( $post_id) ){
			if('1' == get_post_meta($post_id, 'kentha_singletrack', true)){
				$classes[] = 'qt-kentha-product-singletrack';
			}
		}
	    return $classes;
	}
}