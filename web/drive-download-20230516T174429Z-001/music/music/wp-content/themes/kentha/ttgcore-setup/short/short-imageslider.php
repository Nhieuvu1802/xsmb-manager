<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_imageslider_shortcode')){
	function kentha_imageslider_shortcode ($atts){
		extract( shortcode_atts( array(
			'title' => false,
			'class' => '',
			'items' => array(),
			'size' => 'large',
			'proportion' => 'auto',
			'proportionmob' => 'auto',
			'height' => '400'
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
		if(is_array($items)){
			$id = preg_replace('/[0-9]+/', '', uniqid('qttabs')); 
			?>


			<!-- IMAGE SLIDER SHORTCODE ================================================== -->	
			<div class="slider qt-material-slider qt-<?php echo esc_attr($proportion); ?>" data-height="<?php echo esc_attr($height); ?>" data-proportion="<?php echo esc_attr($proportion); ?>" data-proportionmob="<?php echo esc_attr($proportionmob); ?>">
				<ul class="slides">
					<?php  
					foreach($items as $item){
						if(array_key_exists("image", $item)){

							$image = wp_get_attachment_image_src($item['image'], $size); 
							?>
							<li class="qt-negative">
								<img src="<?php echo esc_url($image[0]); ?>" alt="img">
								<div class="caption qt-slidecaption">
									<div class="qt-txt">
										<?php if(array_key_exists("desc", $item)){ ?>
											<h4><?php echo esc_html($item['desc']); ?></h4>
										<?php } ?>
										<?php if(array_key_exists("title", $item)){ ?>
											<h3 class="qt-fontsize-h0"><span><?php echo esc_html($item['title']); ?></span></h3>
										<?php } ?>
										<?php if(array_key_exists("link", $item)){ 
											$linkt = array_key_exists("linkt", $item)? $item['linkt'] : esc_html__( 'Discover More','kentha' );
											?>
											<p>
												<a href="<?php echo esc_url($item['link']); ?>" class="qt-link qt-capfont"><?php echo esc_html( $linkt ); ?> <i class='material-icons'>trending_flat</i></a>
											</p>
										<?php } ?>
									</div>
								</div>
							</li>
							<?php
						}
					}
					?>
				</ul>
				<div class="qt-control-arrows">
					<a href="#" class="prev qt-slideshow-link"><i class='material-icons qt-icon-mirror'>arrow_back</i></a>
					<a href="#" class="next qt-slideshow-link"><i class='material-icons'>arrow_forward</i></a>
				</div>
			</div>
			<!--  IMAGE SLIDER SHORTCODE END ================================================== -->
			<?php  
		}
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-imageslider","kentha_imageslider_shortcode");
}







/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_imageslider_shortcode_vc' );
if(!function_exists('kentha_imageslider_shortcode_vc')){
function kentha_imageslider_shortcode_vc() {
  vc_map( array(
	 "name" => esc_html__( "Image slideshow", "kentha" ),
	 "base" => "kentha-imageslider",
	 "icon" => get_template_directory_uri(). '/img/image-slider-vc-shortcode.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		array(
			'type' => 'param_group',
			'value' => '',
			'param_name' => 'items',
			'params' => array(
				
				array(
					'type' => 'attach_image',
					'value' => '',
					'heading' => 'Image',
					'param_name' => 'image',
				),
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Title", "kentha" ),
				   "param_name" => "title",
				   'value' => ''
				),
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Description", "kentha" ),
				   "param_name" => "desc",
				   'value' => ''
				),
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Link", "kentha" ),
				   "param_name" => "link",
				   'value' => ''
				),
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Link text", "kentha" ),
				   "param_name" => "linkt",
				   'value' => ''
				),
			)
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Image size", "kentha" ),
		   "param_name" => "size",
		   "std" => "large",
		   'value' => array(
				esc_html__("Thumbnail", "kentha")	=>"thumbnail",
				esc_html__("Medium", "kentha")		=>"medium",
				esc_html__("Large", "kentha")		=>"large",
				esc_html__("Full", "kentha")		=> "full"
			),
		   "description" => esc_html__( "Choose the size of the images", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Slider proportion", "kentha" ),
		   "param_name" => "proportion",
		   "std" => "auto",
		   'value' => array(
				esc_html__("Fixed (specify below)", "kentha")	=>"auto",
				esc_html__("Widescreen 16:7", "kentha")		=>"wide",
				esc_html__("Ultrawide 2:1", "kentha")		=>"ultrawide",
				esc_html__("Fullscreen", "kentha")		=>"full",
			),
		   "description" => esc_html__( "Choose the size of the images", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Slider proportion mobile", "kentha" ),
		   "param_name" => "proportionmob",
		   "std" => "auto",
		   'value' => array(
				esc_html__("Fixed (specify below)", "kentha")	=>"auto",
				esc_html__("Widescreen 16:7", "kentha")		=>"wide",
				esc_html__("Ultrawide 2:1", "kentha")		=>"ultrawide",
				esc_html__("Fullscreen", "kentha")		=>"full",
			),
		   "description" => esc_html__( "Choose the size of the images", "kentha" )
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Fixed height", "kentha" ),
		   "param_name" => "height",
		   'value' => ''
		),
	 )
  ) );
}}