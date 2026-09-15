<?php  
/*
Package: kentha
Description: Captions and small captions
Version: 0.0.0
Author: QantumThemes
Author URI: http://qantumthemes.com
*/


/**
 * 
 * Caption medium
 * =============================================
 */

if(!function_exists('kentha_caption_med')){
	function kentha_caption_med ($atts){
		extract( shortcode_atts( array(
			'title' => '',
			'class' => '',
		), $atts ) );
		ob_start();
		?>
			<h3 class="qt-sectiontitle <?php echo esc_attr($class); ?>"><?php echo esc_attr($title); ?></h3>
		<?php
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("qt-caption-med","kentha_caption_med");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_caption_med' );
if(!function_exists('kentha_vc_caption_med')){
function kentha_vc_caption_med() {
  vc_map( array(
     "name" => esc_html__( "Caption", "kentha" ),
     "base" => "qt-caption-med",
     "icon" => get_template_directory_uri(). '/img/caption-vc-shortcode.png',
     "description" => esc_html__( "Section caption", "kentha" ),
     "category" => esc_html__( "Theme shortcodes", "kentha"),
     "params" => array(
        array(
           "type" => "textfield",
           "heading" => esc_html__( "Text", "kentha" ),
           "param_name" => "title",
           'value' => ''
        )
        ,array(
           "type" => "textfield",
           "heading" => esc_html__( "Class", "kentha" ),
           "param_name" => "class",
           'value' => '',
           'description' => 'add an extra class for styling with CSS'
        )
     )
  ) );
}}

/**
 * 
 * Caption small
 * =============================================
 */
if(!function_exists('kentha_caption_small')){
	function kentha_caption_small ($atts){
		extract( shortcode_atts( array(
			'class' => '',
			'title' => ''
		), $atts ) );
		ob_start();
		?>
			<h4 class="qt-caption-small qt-capfont <?php echo esc_attr($class); ?>"><?php echo esc_attr($title); ?></h4>
		<?php
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("qt-caption-small","kentha_caption_small");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_kentha_caption_small' );
if(!function_exists('kentha_vc_kentha_caption_small')){
function kentha_vc_kentha_caption_small() {
  vc_map( array(
     "name" => esc_html__( "Caption small", "kentha" ),
     "base" => "qt-caption-small",
     "icon" => get_template_directory_uri(). '/img/small-caption-vc-shortcode.png',
     "description" => esc_html__( "Section caption small", "kentha" ),
     "category" => esc_html__( "Theme shortcodes", "kentha"),
     "params" => array(

        array(
           "type" => "textfield",
           "heading" => esc_html__( "Text", "kentha" ),
           "param_name" => "title",
           'value' => ''
        )
        ,array(
           "type" => "textfield",
           "heading" => esc_html__( "Class", "kentha" ),
           "param_name" => "class",
           'value' => '',
           'description' => 'add an extra class for styling with CSS'
        )
     )
  ) );
}}


/**
 * 
 * Spacer
 * =============================================
 */
if(!function_exists('kentha_spacer')){
	function kentha_spacer ($atts){
		extract( shortcode_atts( array(
			'size' => 's',
		), $atts ) );
		if($size !== 's' && $size !== 'm' && $size !== 'l') {
			$size = 's';
		}
		ob_start();
		?>
			<hr class="qt-spacer-<?php echo esc_attr($size); ?>">
		<?php
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("qt-spacer","kentha_spacer");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_spacer' );
if(!function_exists('kentha_vc_spacer')){
function kentha_vc_spacer() {
  vc_map( array(
     "name" => esc_html__( "Spacer", "kentha" ),
     "base" => "qt-spacer",
     "icon" => get_template_directory_uri(). '/img/spacer-vc-shortcode.png',
     "description" => esc_html__( "Spacer", "kentha" ),
     "category" => esc_html__( "Theme shortcodes", "kentha"),
     "params" => array(
      	array(
           "type" => "dropdown",
           "heading" => esc_html__( "Size", "kentha" ),
           "param_name" => "size",
           'value' => array("s", "m", "l"),
           "description" => esc_html__( "Empty spacer separator", "kentha" )
        )
     )
  ) );
}}