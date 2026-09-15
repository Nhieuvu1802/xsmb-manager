<?php
/*
Package: kentha
*/

if (!function_exists('kentha_short_image')){
function kentha_short_image($atts){
	extract( shortcode_atts( array(
		'title' => false,
		'subtitle' => false,
		'link' => false,
		'linktitle' => false,
		'image' => false,
		'thumbsize' => 'large',
		'align' => 'aligncenter',
		'target' => 'self'
	), $atts ) );
	ob_start();
	if($image){ 
		$image = wp_get_attachment_image_src($image, $thumbsize); 
		?>
		<div class="qt-short-image <?php echo esc_attr($align); ?>">
			<?php  
			if($link){
				?>
				<a href="<?php echo esc_url($link); ?>" class="qw-disableembedding" target="<?php echo esc_attr( $target ); ?>">
				<?php
			}
				?><img src="<?php echo esc_url($image[0]); ?>" alt="<?php echo esc_attr($title); ?>"> <?php 

			if($link){
				?></a><?php
			}
			?>
		</div>
		<?php 

	}
	return ob_get_clean();
}}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode('kentha-shortimage', 'kentha_short_image' );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_image_vc' );
if(!function_exists('kentha_short_image_vc')){
function kentha_short_image_vc() {
  vc_map( array(
	 "name" => esc_html__( "Single image", "kentha" ),
	 "base" => "kentha-shortimage",
	 "icon" => get_template_directory_uri(). '/img/single-image-vc-shortcode.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Image", "kentha" ),
		   "param_name" => "image"
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Image ALT attribute", "kentha" ),
		   "param_name" => "title"
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Link", "kentha" ),
		   "param_name" => "link"
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Image size", "kentha" ),
		   "param_name" => "thumbsize",
		   "std" => "large",
		   'value' => array(
				esc_html__("Thumbnail", "kentha")	=>"thumbnail",
				esc_html__("Medium", "kentha")		=>"medium",
				esc_html__("Large", "kentha")		=>"large",
				esc_html__("Full", "kentha")		=> "full"
			),
		   "description" => esc_html__( "Choose the size for the images", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Align", "kentha" ),
		   "param_name" => "align",
		   "std" => "aligncenter",
		   'value' => array(
				esc_html__("Left", "kentha")	=> "alignleft",
				esc_html__("Right", "kentha")		=>"alignright",
				esc_html__("Center", "kentha")		=>"aligncenter"
			),
		   "description" => esc_html__( "Choose the post template for the items", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Target", "kentha" ),
		   "param_name" => "target",
		   "std" => "large",
		   'value' => array( 
				esc_html__("Same window", "kentha")	=>"_self",
				esc_html__("New window", "kentha")		=>"_blank",
			),
		   "description" => esc_html__( "Choose the post template for the items", "kentha" )
		),
		
	 )
  ) );
}}
