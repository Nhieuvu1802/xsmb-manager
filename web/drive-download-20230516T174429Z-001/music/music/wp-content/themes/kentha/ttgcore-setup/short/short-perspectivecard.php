<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_perspectivecard_sc')) {
function kentha_perspectivecard_sc($atts){


	/*
	 *	Defaults
	 * 	All parameters can be bypassed by same attribute in the shortcode
	 */
	extract( shortcode_atts( array(
		'id' => false,
		'linkto' => 'play',
		'quantity' => 1,
		'text' => false,
		'posttype' => 'release',
		'orderby' => 'date',
		'background1' => false,
		'background2' => false,
		'background3' => false,
		'background4' => false,
		'foreground1' => false,
		'foreground2' => false,
	), $atts ) );

	
	/**
	 *  Query for my content
	 */
	$args = array(
		'post_type' =>  'release',
		'posts_per_page' => 1,
		'post_status' => 'publish',
		'paged' => 1,
		'suppress_filters' => false,
		'ignore_sticky_posts' => 1
	);

	// ========== ORDERBY =================
	$args['orderby'] = array ( 'menu_order' => 'ASC', 'date' => 'DESC');
	// ========== ORDERBY END =================


	// ========== QUERY BY ID =================
	if($id){		
		if(is_numeric($id)){
			$id = str_replace(' ', '', $id);
			$args = array(
				'post_type' =>  'release',
				'post__in'=> array($id),
				'orderby' => 'post__in',
				'posts_per_page' => 1,
				'paged' => 1,

			);  
		}
	}
	// ========== QUERY BY ID END =================

	/**
	 * [$wp_query execution of the query]
	 * @var WP_Query
	 */
	$wp_query = new WP_Query( $args );
	
	/**
	 * Output object start
	 */
	ob_start();
	if ( $wp_query->have_posts() ) : 
		while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		?>
		<div class="qt-perspectivecard-wrapper ">
			<div class="qt-perspectivecard" <?php  if($background1){ $background_image1 = wp_get_attachment_image_src($background1, 'full');  ?> data-bgimage="<?php echo esc_url($background_image1[0]); ?>" <?php } ?> >
				
				<?php  
				if($background2){
					$background_image2 = wp_get_attachment_image_src($background2, 'full'); 
					?>
					<div class="qt-perspectivecard__bg2" data-bgimage="<?php echo esc_url($background_image2[0]); ?>"></div>
					<?php
				}
				if($background3){
					$background_image3 = wp_get_attachment_image_src($background3, 'full'); 
					?>
					<div class="qt-perspectivecard__bg3" data-bgimage="<?php echo esc_url($background_image3[0]); ?>"></div>
					<?php
				}
				if($background4){
					$background_image4 = wp_get_attachment_image_src($background4, 'full'); 
					?>
					<div class="qt-perspectivecard__bg4" data-bgimage="<?php echo esc_url($background_image4[0]); ?>"></div>
					<?php
				}
				if(has_post_thumbnail()){
					?><div class="qt-perspectivecard__cover"><?php  
						the_post_thumbnail( 'kentha-squared' );
					?></div><?php  
				}
				if($foreground1){
					$foreground_image1= wp_get_attachment_image_src($foreground1, 'full'); 
					?>
					<div class="qt-perspectivecard__fg1" data-bgimage="<?php echo esc_url($foreground_image1[0]); ?>"></div>
					<?php
				}
				if($foreground2){
					$foreground_image2= wp_get_attachment_image_src($foreground2, 'full'); 
					?>
					<div class="qt-perspectivecard__fg2" data-bgimage="<?php echo esc_url($foreground_image2[0]); ?>"></div>
					<?php
				}
				?>
				<p>
					<?php 
					if($linkto == 'play'){ 
						?>
						<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary qt-btn-xl z-depth-2 noajax" data-kenthaplayer-addrelease="<?php echo add_query_arg('qt_json', '1',  get_the_permalink()); ?>" data-playnow="1">
							<i class="material-icons">play_arrow</i>&nbsp;
							<?php 
							if($text){
								echo esc_html($text);
							} else {
								esc_html_e( 'Play all', 'kentha' ); 
							}
							?>
						</a>
						<?php 
					} else { 
						?>
						<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary qt-btn-xl">
							<i class="material-icons">play_arrow</i>&nbsp;
							<?php 
							if($text){
								echo esc_html($text);
							} else {
								esc_html_e( 'Play all', 'kentha' ); 
							}
							?>								
						</a>
						<?php 
					}
					?>
				</p>
			</div>

		</div>
		<?php  
		endwhile; 
	endif;
	wp_reset_postdata();
	return ob_get_clean();
}}



if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode('kentha-perspectivecard', 'kentha_perspectivecard_sc' );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_perspectivecard_sc_vc' );
if(!function_exists('kentha_perspectivecard_sc_vc')){
function kentha_perspectivecard_sc_vc() {
  vc_map( array(
	 "name" => esc_html__( "3D Album", "kentha" ),
	 "base" => "kentha-perspectivecard",
	 "icon" => get_template_directory_uri(). '/img/3d-album.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(


		array(
		   'type' 			=> 'autocomplete',
			'heading' 		=> esc_html__( 'Release name', 'kentha' ),
			'param_name' 	=> 'id',
			'settings'		=> array( 'values' => kentha_get_type_posts_data('release') ),
		),
		 array(
           "type" => "textfield",
           "heading" => esc_html__( "Button text", "kentha" ),
           "param_name" => "text",
        ),

		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Link to", "kentha" ),
		   "param_name" => "linkto",
		   "std" => "play",
		   'value' => array(
				esc_html__("Release page", "kentha")	=>"page",
				esc_html__("Play action", "kentha")		=>"play",
			),
		   "description" => esc_html__( "Choose the size for the images", "kentha" )
		),


		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Background layer 1", "kentha" ),
		   "param_name" => "background1"
		),
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Background layer 2", "kentha" ),
		   "param_name" => "background2"
		),
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Background layer 3", "kentha" ),
		   "param_name" => "background3"
		),
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Background layer 4", "kentha" ),
		   "param_name" => "background4"
		),
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Foreground layer 1", "kentha" ),
		   "param_name" => "foreground1"
		),
		array(
		   "type" => "attach_image",
		   "heading" => esc_html__( "Foreground layer 2", "kentha" ),
		   "param_name" => "foreground2"
		),
		
		
	 )
  ) );
}}
