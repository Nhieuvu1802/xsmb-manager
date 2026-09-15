<?php  
/*
Package: Kentha
*/

if(!function_exists('kentha_buttons_addtocart_shortcode')){
	function kentha_buttons_addtocart_shortcode ($atts){
		extract( shortcode_atts( array(
			'text' => 'click',
			'id' => false,
			'size' => 'qt-btn-s',
			'target' => '',
			'style' => 'qt-btn-default',
			'alignment' => '',
			'class' => ''
		), $atts ) );

		if(!function_exists('vc_param_group_parse_atts') ){
			return;
		}
		if(!$id){
			return;
		}
		ob_start();


		$prodid = $id;
		global $wp;
		$current_url = '#';
		if (is_object($wp)){
			$current_url = home_url( add_query_arg( array(), $wp->request ) );
		}
		$link = add_query_arg("add-to-cart" ,   $prodid,  $current_url );
		if ( $alignment == 'aligncenter' ) { ?><p class="aligncenter"> <?php } ?>
					<a href="<?php echo esc_attr($link); ?>" <?php if($target == "_blank"){ ?> target="_blank" <?php } ?> data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>"  class="qt-btn product_type_simple add_to_cart_button ajax_add_to_cart <?php  echo esc_attr($size.' '.$class.' '.$style.' '.$alignment); ?>"><?php echo esc_html($text); ?></a>
		<?php 
		if ( $alignment == 'aligncenter' ) { ?></p><?php } 
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-button-addtocart","kentha_buttons_addtocart_shortcode");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_buttons_addtocart_shortcode_vc' );
if(!function_exists('kentha_buttons_addtocart_shortcode_vc')){
function kentha_buttons_addtocart_shortcode_vc() {
  vc_map( array(
	"name" 			=> esc_html__( "WooCommerce Buy Button", "kentha" ),
	"base" 			=> "kentha-button-addtocart",
	"icon" 			=> get_template_directory_uri(). '/img/button-vc-shortcode.png',
	"description" 	=> esc_html__( "WooCommerce Ajax Add To Cart button", "kentha" ),
	"category" 		=> esc_html__( "Theme shortcodes", "kentha"),
	"params" 		=> array(
			array(
				'type' 		=> 'textfield',
				'value' 	=> '',
				'heading' 	=> 'Text',
				'param_name'=> 'text',
			),
			array(
				'type' 			=> 'autocomplete',
				'heading' 		=> esc_html__( 'Product ID (Search By Name)', 'kentha' ),
				'param_name' 	=> 'id',
				'settings'		=> array( 'values' => kentha_get_type_posts_data('product') ),
			),
			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Link target (if ajax is not available)", "kentha" ),
				"param_name"=> "target",
				'value' 	=> array( 
					esc_html__("Same window","kentha") 	=> "",
					esc_html__("New window","kentha") 	=> "_blank",
					)			
				),
			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Size", "kentha" ),
				"param_name"=> "size",
				'value' 	=> array(
						"Small" 		=> "qt-btn-s",
						"Medium" 		=> "qt-btn-m",
						"Large" 		=> "qt-btn-l", 
						"Extra large" 	=> 'qt-btn-xl'
					),
				"description" => esc_html__( "Button size", "kentha" )
			),

			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Button style", "kentha" ),
				"param_name"=> "style",
				'value' 	=> array( 
					esc_html__("Default","kentha") 	=> "qt-btn-default",
					esc_html__("Primary","kentha") 	=> "qt-btn-primary",
					esc_html__("Secondary","kentha") => "qt-btn-secondary",
					esc_html__("Ghost","kentha") 	=> "qt-btn-ghost",
					)			
				),
			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Alignment", "kentha" ),
				"param_name"=> "alignment",
				'value' 	=> array( 
								esc_html__("Default","kentha") 	=> "",
								esc_html__("Left","kentha") 		=> "alignleft",
								esc_html__("Right","kentha") 	=> "alignright",
								esc_html__("Center","kentha") 	=> "aligncenter",
								),
				"description" => esc_html__( "Button style", "kentha" )
			),
			array(
				"type" 			=> "textfield",
				"heading" 		=> esc_html__( "Class", "kentha" ),
				"param_name" 	=> "class",
				'value' 		=> '',
				'description' 	=> 'add an extra class for styling with CSS'
			)
		)
  	));
}}
