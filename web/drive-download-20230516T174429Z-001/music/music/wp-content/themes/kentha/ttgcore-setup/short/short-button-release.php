<?php  
/*
Package: Kentha
*/

if(!function_exists('kentha_button_release_shortcode')){
	function kentha_button_release_shortcode ($atts){
		extract( shortcode_atts( array(
			'text' => 'click',
			'size' => 'qt-btn-s',
			'style' => 'qt-btn-default',
			'alignment' => '',
			'class' => '',
			'id' => false
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
		// ========== QUERY BY ID =================
		if($id){		
			if(is_numeric($id)){
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
		// 
		/**
		 * [$wp_query execution of the query]
		 * @var WP_Query
		 */
		$wp_query = new WP_Query( $args );
		
		ob_start();
		if ( $wp_query->have_posts() ) : 
			while ( $wp_query->have_posts() ) : $wp_query->the_post();
			$post = $wp_query->post;
			setup_postdata( $post );
			
			?>
			<?php if ( $alignment == 'aligncenter' ) { ?><p class="aligncenter"> <?php } ?>
				<a href="<?php the_permalink(); ?>" class="qt-btn noajax <?php  echo esc_attr($size.' '.$class.' '.$style.' '.$alignment); ?>" data-kenthaplayer-addrelease="<?php echo add_query_arg('qt_json', '1',  get_the_permalink()); ?>" data-playnow="1">
					<i class="material-icons">play_arrow</i> <?php echo esc_html($text); ?>
				</a>
			<?php if ( $alignment == 'aligncenter' ) { ?></p><?php } ?>
		<?php
		endwhile; endif;
		wp_reset_postdata();
		return ob_get_clean();
		
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-button-release","kentha_button_release_shortcode");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_button_release_shortcode' );
if(!function_exists('kentha_vc_button_release_shortcode')){
function kentha_vc_button_release_shortcode() {
  vc_map( array(
	"name" 			=> esc_html__( "Album play button", "kentha" ),
	"base" 			=> "kentha-button-release",
	"icon" 			=> get_template_directory_uri(). '/img/button-vc-shortcode-release.png',
	"description" 	=> esc_html__( "Play album button", "kentha" ),
	"category" 		=> esc_html__( "Theme shortcodes", "kentha"),
	"params" 		=> array(
			array(
				'type' 			=> 'autocomplete',
				'heading' 		=> esc_html__( 'Release name', 'kentha' ),
				'param_name' 	=> 'id',
				'settings'		=> array( 'values' => kentha_get_type_posts_data('release') ),
			),
			
			array(
				'type' 		=> 'textfield',
				'value' 	=> '',
				'heading' 	=> 'Text',
				'param_name'=> 'text',
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
