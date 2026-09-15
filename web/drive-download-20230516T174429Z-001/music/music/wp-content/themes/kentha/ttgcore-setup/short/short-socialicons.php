<?php  
/*
Package: Kentha
*/

if(!function_exists('kentha_socialicons_shortcode')){
	function kentha_socialicons_shortcode ($atts){
		extract( shortcode_atts( array(
			'text' => '',
			'link' => '#',
			'size' => 'qt-btn-s',
			'target' => '',
			'style' => 'qt-btn-default',
			'alignment' => '',
			'icon' => '',
			'class' => ''
		), $atts ) );

		if(!function_exists('vc_param_group_parse_atts') ){
			return;
		}
		if($size === 'qt-btn-xxl') {
			$class = $class.' qt-big-icons';
			$size = 'qt-btn-xl';
		}
		ob_start();
		?>
			<?php if ( $alignment == 'aligncenter' ) { ?><p class="aligncenter"> <?php } ?>
					<a href="<?php echo esc_attr($link); ?>" <?php if($target == "_blank"){ ?> target="_blank" <?php } ?> class="qt-btn qt-short-socialicon qw-disableembedding qw_social <?php  echo esc_attr($size.' '.$class.' '.$style.' '.$alignment); ?>"><i class="qt-socicon-<?php echo esc_attr($icon); ?> qt-socialicon"></i><?php if($text) { echo ' '.esc_html($text); } ?></a>
			<?php if ( $alignment == 'aligncenter' ) { ?></p><?php } ?>
		<?php
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-short-socicon","kentha_socialicons_shortcode");
}





/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_socialicons_shortcode_vc' );
if(!function_exists('kentha_socialicons_shortcode_vc')){
function kentha_socialicons_shortcode_vc() {
  vc_map( array(
	"name" 			=> esc_html__( "Social icon button", "kentha" ),
	"base" 			=> "kentha-short-socicon",
	"icon" 			=> get_template_directory_uri(). '/img/button-vc-shortcode.png',
	"description" 	=> esc_html__( "Add a social link", "kentha" ),
	"category" 		=> esc_html__( "Theme shortcodes", "kentha"),
	"params" 		=> array(
			array(
				'type' 		=> 'textfield',
				'value' 	=> '',
				'heading' 	=> 'Text',
				'param_name'=> 'text',
			),
			array(
				'type' 		=> 'textfield',
				'value' 	=> '',
				'heading'	=> 'Link',
				'param_name'=> 'link',
			),
			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Link target", "kentha" ),
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
						"Extra large" 	=> 'qt-btn-xl',
						"XXL" 	=> 'qt-btn-xxl'
					),
				"description" => esc_html__( "Button size", "kentha" )
			),

			array(
				"type" 		=> "dropdown",
				"heading" 	=> esc_html__( "Icon", "kentha" ),
				"param_name"=> "icon",
				'value' 	=>  array_flip(kentha_qt_socicons_array() ),
				"description" => esc_html__( "Choose social icon", "kentha" )
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
