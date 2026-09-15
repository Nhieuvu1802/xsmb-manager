<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_event_feat_shortcode')) {
	function kentha_event_feat_shortcode($atts){

		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'posttype' => 'event',
			'hideold' => false,
			'title' => false,
			'orderby' => 'date',
			'offset' => 0,
			'template' => 'phpincludes/part-archive-item'
		), $atts ) );


		$offset = (int)$offset;
		if(!is_numeric($offset)) {
			$offset = 0;
		}
		
		/**
		 *  Query for my content
		 */
		$args = array(
			'post_type' =>  'event',
			'posts_per_page' => 1,
			'post_status' => 'publish',
			'paged' => 1,
			'suppress_filters' => false,
			'offset' => esc_attr($offset),
			'ignore_sticky_posts' => 1
		);



		// ========== EVENTS ONLY QUERY =================
		
		$args['orderby'] = 'meta_value';
		$args['order']   = 'ASC';
		$args['meta_key'] = 'eventdate';

		if($hideold){
			$args['meta_query'] = array(
				array(
					'key' => 'eventdate',
					'value' => date('Y-m-d'),
					'compare' => '>=',
					'type' => 'date'
				 )
			);
		}
		// ========== END OF EVENTS ONLY QUERY =================


		// ========== QUERY BY ID =================
		if($id){
			$idarr = explode(",",$id);
			if(count($idarr) > 0){
				$quantity = count($idarr);
				$args = array(
					'post__in'=> $idarr,
					'post_type' =>  'event',
					'orderby' => 'post__in',
					'posts_per_page' => -1,
					'ignore_sticky_posts' => 1
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

		if($title){ ?>
			<h3 class="qt-sectiontitle"><?php echo esc_html($title); ?></h3>
		<?php }

		
		if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		/**
		 *  WE HAVE TO USE THE ARCHIVE ITEM FOR EACH SPECIFIC POSTTYPE
		 */
		get_template_part( 'phpincludes/part-event-featured' );

		endwhile;  else: 
			esc_html_e("Sorry, there is nothing for the moment.", "kentha"); ?>
		<?php  
		endif; 
		wp_reset_postdata();
		/**
		 * Loop end;
		 */
		
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-eventfeatured","kentha_event_feat_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_event_feat_shortcode_vc' );
if(!function_exists('kentha_event_feat_shortcode_vc')){
function kentha_event_feat_shortcode_vc() {
  vc_map( array(
     "name" => esc_html__( "Featured event", "kentha" ),
     "base" => "kentha-eventfeatured",
     "icon" => get_template_directory_uri(). '/img/event-featured.png',
     "description" => esc_html__( "List of items with thumbnail", "kentha" ),
     "category" => esc_html__( "Theme shortcodes", "kentha"),
     "params" => array(
        array(
           "type" => "checkbox",
           "heading" => esc_html__( "Hide old events (show first upcoming)", "kentha" ),
           "param_name" => "hideold",
           'value' => false
        ),

        array(
           "type" => "textfield",
           "heading" => esc_html__( "Event by ID", "kentha" ),
           "description" => esc_html__( "Display only a specific event", "kentha" ),
           "param_name" => "id",
           'value' => ''
        ),
     )
  ) );
}}


		



