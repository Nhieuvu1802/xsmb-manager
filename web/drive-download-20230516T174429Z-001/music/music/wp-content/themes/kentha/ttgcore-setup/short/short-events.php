<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_events_shortcode')) {
	function kentha_events_shortcode($atts){

		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'quantity' => 3,
			'posttype' => 'event',
			'hideold' => false,
			'title' => false,
			'category' => false,
			'orderby' => 'date',
			'offset' => 0,
			'template' => 'phpincludes/part-archive-item'
			
		), $atts ) );


		if(!is_numeric($quantity)) {
			$quantyty = 3;
		}

		$offset = (int)$offset;
		if(!is_numeric($offset)) {
			$offset = 0;
		}
		
		/**
		 *  Query for my content
		 */
		$args = array(
			'post_type' =>  'event',
			'posts_per_page' => $quantity,
			'post_status' => 'publish',
			'paged' => 1,
			'suppress_filters' => false,
			'offset' => esc_attr($offset),
			'ignore_sticky_posts' => 1
		);

		/**
		 * Add category parameters to query if any is set
		 */
		if (false !== $category && 'all' !== $category) {
			$args[ 'tax_query'] = array(
            		array(
                    'taxonomy' => esc_attr( kentha_get_type_taxonomy( $posttype ) ),
                    'field' => 'slug',
                    'terms' => array(esc_attr($category)),
                    'operator'=> 'IN' //Or 'AND' or 'NOT IN'
             	)
            );
		}

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
			get_template_part( 'phpincludes/part-event-inline' );

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
	ttg_custom_shortcode("kentha-events","kentha_events_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_events_shortcode_vc' );
if(!function_exists('kentha_events_shortcode_vc')){
function kentha_events_shortcode_vc() {
  vc_map( array(
     "name" => esc_html__( "Events list", "kentha" ),
     "base" => "kentha-events",
     "icon" => get_template_directory_uri(). '/img/event.png',
     "description" => esc_html__( "List of items with thumbnail", "kentha" ),
     "category" => esc_html__( "Theme shortcodes", "kentha"),
     "params" => array(

     	
		
        array(
           "type" => "textfield",
           "heading" => esc_html__( "Title", "kentha" ),
           "param_name" => "title",
           'value' => false
        ),

        array(
           "type" => "checkbox",
           "heading" => esc_html__( "Hide old events", "kentha" ),
           "param_name" => "hideold",
           'value' => false
        ),

        array(
           "type" => "textfield",
           "heading" => esc_html__( "ID, comma separated list (123,345,7638)", "kentha" ),
           "description" => esc_html__( "Display only the contents with these IDs. All other parameters will be ignored.", "kentha" ),
           "param_name" => "id",
           'value' => ''
        ),

      	array(
           "type" => "textfield",
           "heading" => esc_html__( "Quantity", "kentha" ),
           "param_name" => "quantity",
           "description" => esc_html__( "Number of items to display", "kentha" )
        ),
        
        array(
           "type" => "textfield",
           "heading" => esc_html__( "Filter by event type (slug)", "kentha" ),
           "description" => esc_html__("Instert the slug of the event type to filter the results","kentha"),
           "param_name" => "category"
        ),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Offset (number)", "kentha" ),
		   "description" => esc_html__("Number of items to skip in the database query","kentha"),
		   "param_name" => "offset"
		)
     )
  ) );
}}


		



