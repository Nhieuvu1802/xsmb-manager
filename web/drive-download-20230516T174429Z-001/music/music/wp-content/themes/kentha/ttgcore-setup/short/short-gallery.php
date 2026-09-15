<?php
/*
Package: kentha
*/
if (!function_exists('kentha_short_gallery')){
function kentha_short_gallery($atts){
	extract( shortcode_atts( array(
		'images'    => false,
		'thumbsize' => 'm',
		'linksize'  => 'large'
	), $atts ) );
	if(!function_exists('vc_param_group_parse_atts') ){
		return;
	}
	if(is_array($atts)){
		if(array_key_exists("images", $atts)){
			$images = explode(',', $images);
		}
	}
	ob_start();
	if(count($images) > 0){ 
		?>
			<div class="qt-kentha-gallery qt-s<?php echo esc_attr($thumbsize); ?>">
				<?php
					switch('thumbsize'){
						case 's':
							$imgsize = 'thumbnail';
							break;
						case 'm':
						case 'l':
						default: 
							$imgsize = 'kentha-squared';
					}
					foreach($images as $image){
						$thumb = wp_get_attachment_image_src($image, $imgsize); 
						$link  = wp_get_attachment_image_src($image, $linksize);
						$thumb = $thumb[0];
						$link  = $link[0];
						?>
						<a href="<?php echo esc_url( $link ); ?>" class="qt-gallery-item">
							<img src="<?php echo esc_url($thumb); ?>" alt="<?php echo esc_attr(get_the_title($image)); ?>">
							<i class='material-icons'>zoom_in</i>
							<span class="qt-frame"></span>
						</a>
						<?php
					}
				?>
			</div>
		<?php  
	}
	return ob_get_clean();
}}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode('kentha-gallery', 'kentha_short_gallery' );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_gallery_vc' );
if(!function_exists('kentha_short_gallery_vc')){
function kentha_short_gallery_vc() {
  vc_map( array(
	 "name" 	=> esc_html__( "Gallery", "kentha" ),
	 "base" 	=> "kentha-gallery",
	 "icon" 	=> get_template_directory_uri(). '/img/gallery.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" 	=> array(
		array(
			"type" 			=> "attach_images",
			"heading" 		=> esc_html__( "Images", "kentha" ),
			"param_name" 	=> "images"
		),
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Image size", "kentha" ),
			"param_name" 	=> "thumbsize",
			"std" 			=> 'm',
			'value' 		=> array(
				esc_html__("Small", "kentha")	=>"s",
				esc_html__("Medium", "kentha")	=>'m',
				esc_html__("Large", "kentha")	=>'l',
			),
		   "description" 	=> esc_html__( "Choose the post template for the items", "kentha" )
		),
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Linked image size", "kentha" ),
			"param_name" 	=> "linksize",
			"std" 			=> "large",
			'value' 		=> array(
				esc_html__("Thumbnail", "kentha")	=>"thumbnail",
				esc_html__("Medium", "kentha")		=>"medium",
				esc_html__("Large", "kentha")		=>"large",
				esc_html__("Full", "kentha")			=> "full"
			),
		   "description" => esc_html__( "Choose the post template for the items", "kentha" )
		)		
	 )
  ) );
}}
