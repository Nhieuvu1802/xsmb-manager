<?php
/**
 * @package kentha
 * @version	1.3.5
 */

if (!function_exists('kentha_short_mediagallery')){
function kentha_short_mediagallery($atts){
	extract( shortcode_atts( array(
		'items'    => false,
		'thumbsize' => 'm',
		'cols'  => '4',
		'colsm'  => '4',
		'colss'  => '4',
	), $atts ) );
	if(!function_exists('vc_param_group_parse_atts') ){
		return;
	}
	ob_start();

	if(is_array($atts)){
		if(array_key_exists("items", $atts)){
			$items = vc_param_group_parse_atts( $atts['items'] );
		}
	}

	/**
	 * Thimbnail size
	 */
	switch($thumbsize){
		case 'f':
			$imgsize = 'full';
			break;
		case 's':
			$imgsize = 'thumbnail';
			break;
		case 'm':
			$imgsize = 'medium';
			break;
		case 'ms':
			$imgsize = 'kentha-squared';
			break;
		case 'l':
		default: 
			$imgsize = 'large';
	}


	/**
	 * Columns
	 */
	
	if(!$cols){ $cols = 4; }
	$colsclass = 'l'.(12 / $cols);

	if(!$colss){ $colss = 4; }
	$colsclass_s = 's'.(12 / $colss);

	if(!$colsm){ $colsm = 4; }
	$colsclass_m = 'm'.(12 / $colsm);

	if(is_array($items)){
		?>
		<div class="row qt-mediagallery">
			<?php
			foreach($items as $item){
				if(array_key_exists("image", $item)){
					/**
					 * [$image the thumbnail and eventually link to bigger]
					 * @var [type]
					 */
					$image = $item['image'];
					$thumb = wp_get_attachment_image_src($image, $imgsize); 
					$link  = wp_get_attachment_image_src($image, 'full');
					$thumb = $thumb[0];
					$link  = $link[0];
					$title = '';

					/**
					 * Has a video link?
					 */
					if(array_key_exists("link", $item)){
						$link = $item['link'];
					}
					if(array_key_exists("title", $item)){
						$title = $item['title'];
					}
					?>
					<div class="col <?php echo esc_attr( $colsclass.' '.$colsclass_s.' '.$colsclass_m ); ?>" data-bgimage="<?php echo esc_url($thumb); ?>">
						<a href="<?php echo esc_url($link); ?>" title="<?php echo esc_attr($title); ?>" class="qt-disableembedding">
							<i class='material-icons'>zoom_in</i>
							<span class="qt-t qt-capfont"><?php echo esc_html($title); ?></span>
							<span class="qt-frame"></span>
						</a>
					</div>
					<?php
				}
			}
			?>
		</div>
		<?php  
	}
	return ob_get_clean();
}}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode('kentha-mediagallery', 'kentha_short_mediagallery' );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_mediagallery_vc' );
if(!function_exists('kentha_short_mediagallery_vc')){
function kentha_short_mediagallery_vc() {
  vc_map( array(
	 "name" 	=> esc_html__( "Gallery Multimedia", "kentha" ),
	 "base" 	=> "kentha-mediagallery",
	 "icon" 	=> get_template_directory_uri(). '/img/gallery.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" 	=> array(

	 	array(
			'type' => 'param_group',
			'param_name' => 'items',
			'params' => array(
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Title", "kentha" ),
				   "param_name" => "title",
				   'value' => ''
				),
				array(
					"type" 			=> "attach_image",
					"heading" 		=> esc_html__( "Images", "kentha" ),
					"param_name" 	=> "image"
				),
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Youtube video or external link", "kentha" ),
				   "param_name" => "link",
				),
			)
		),	
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Columns desktop", "kentha" ),
			"param_name" 	=> "cols",
			"std" 			=> 4,
			'value' 		=> array(
				1,2,3,4,6,12
			),
		),
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Columns medium screen", "kentha" ),
			"param_name" 	=> "colsm",
			"std" 			=> 4,
			'value' 		=> array(
				1,2,3,4,6,12
			),
		),
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Columns small screen", "kentha" ),
			"param_name" 	=> "colss",
			"std" 			=> 4,
			'value' 		=> array(
				1,2,3,4,6,12
			),
		),
		array(
			"type" 			=> "dropdown",
			"heading" 		=> esc_html__( "Thumbnail size", "kentha" ),
			"param_name" 	=> "thumbsize",
			"std" 			=> 'm',
			'value' 		=> array(
				esc_html__("Small", "kentha")	=>"s",
				esc_html__("Medium", "kentha")	=>'m',
				esc_html__("Large", "kentha")	=>'l',
				esc_html__("Full", "kentha")	=>'f',
			),
		   "description" 	=> esc_html__( "Choose the post template for the items", "kentha" )
		),
	 )
  ) );
}}
