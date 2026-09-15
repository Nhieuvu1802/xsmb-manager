<?php
/*
Package: Kentha
*/
if(!function_exists('kentha_card_grid')) {
	function kentha_card_grid($atts){
		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'quantity' => 6,
			'posttype' => 'post',
			'title' => false,
			'category' => false,
			'orderby' => 'date',
			'offset' => 0,
			'template' => 'phpincludes/part-archive-item',
			'iprd' => '3',		
			'iprt' => '3',	
		), $atts ) );
	
		$offset = (int)$offset;
		if(!is_numeric($offset)) {
			$offset = 0;
		}


		
		/**
		 *  Query for my content
		 */
		$args = array(
			'post_type' =>  $posttype,
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

		// ========== ORDERBY =================
		if($orderby == 'date'){
			$args['orderby'] = 'date';
			$args['order'] = 'DESC';
		}
		if($orderby == 'title'){
			$args['orderby'] = 'title';
			$args['order'] = 'ASC';
		}
		if($orderby == 'orderdate'){
			$args['orderby'] = array ( 'menu_order' => 'ASC', 'date' => 'DESC');
		}
		if($orderby == 'rand'){
			$args['orderby'] = 'rand';
		}
		// ========== ORDERBY END =================

		// ========== EVENTS ONLY QUERY =================
		if($posttype == 'event'){
			$args['orderby'] = 'meta_value';
			$args['order']   = 'ASC';
			$args['meta_key'] = 'eventdate';
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
					'post_type' =>  $posttype,
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
		switch($posttype){
			case 'artist':
				$template = 'part-archive-item-artist';
				break;
			case 'event':
				$template = 'part-archive-item-event';
				break;
			case 'podcast':
				$template = 'part-archive-item-podcast';
				break;
			case 'release':
				$template = 'part-archive-item-release';
				break;
			case 'shows':
				$template = 'item-show';
				break;
			case 'post':
			default:
				$template = 'part-archive-item';
		}

		ob_start();

		$colwidth_desktop = 12 / intval($iprd);
		$colwidth_tablet = 12 / intval($iprt);

		if ( $wp_query->have_posts() ) : 

			?>

			<div class="row">
				<?php
				while ( $wp_query->have_posts() ) : $wp_query->the_post();
				$post = $wp_query->post;
				setup_postdata( $post );
				/**
				 *  WE HAVE TO USE THE ARCHIVE ITEM FOR EACH SPECIFIC POSTTYPE
				 */
				?>
				<div class="col s12 m<?php echo esc_attr( $colwidth_tablet); ?> l<?php echo esc_attr( $colwidth_desktop); ?>">
					<?php get_template_part ( 'phpincludes/'.$template); ?>
				</div>
				<?php endwhile;  ?>

			</div>

			
			<!--  POSTS CAROUSEL END ================================================== -->
			<?php 
		else: 
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
	ttg_custom_shortcode("kentha-card-grid","kentha_card_grid");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_card_grid_vc' );
if(!function_exists('kentha_card_grid_vc')){
function kentha_card_grid_vc() {
  vc_map( array(
	 "name" => esc_html__( "Card grid", "kentha" ),
	 "base" => "kentha-card-grid",
	 "icon" => get_template_directory_uri(). '/img/cards-grid-vc-shortcode.png',
	 "description" => esc_html__( "Grid of interactive cards", "kentha" ),
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Items per row desktop", "kentha" ),
		   "param_name" => "iprd",
			"std" => "3",
		   'value' => array("1","2","3", "4"),
		   "description" => esc_html__( "Number of items per row. NOT ANY AMOUNT WILL FIT CORRECTLY, ADJUST DEPENDING ON THE CONTAINER SIZE.", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Items per row tablet", "kentha" ),
		   "param_name" => "iprt",
			"std" => "3",
		   'value' => array("1","2","3", "4"),
		   "description" => esc_html__( "Number of items per row. NOT ANY AMOUNT WILL FIT CORRECTLY, ADJUST DEPENDING ON THE CONTAINER SIZE.", "kentha" )
		),
		
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Post type", "kentha" ),
		   "param_name" => "posttype",
		   'value' => array(
				esc_html__("Post", "kentha")		=>"post",
				esc_html__("Artist", "kentha")	=>"artist",
				esc_html__("Event", "kentha")	=>"event",
				esc_html__("Podcast", "kentha")	=>"podcast",
				esc_html__("Release", "kentha")	=>"release",
			),
		   "description" => esc_html__( "IMPORTANT: DO NOT OVERLOAD YOUR PAGE OF INTERACTIVE CARDS!", "kentha" )
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Order by", "kentha" ),
		   "param_name" => "orderby",
		   'value' => array(
				esc_html__("Date", "kentha")		=>	"date",
				esc_html__("Page order, then date", "kentha")=>"orderdate",
				esc_html__("Random", "kentha")	=>"rand",
				esc_html__("Title", "kentha")	=>"title",
			),
		    "description" => esc_html__( "Ignored for Events", "kentha" )
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Title", "kentha" ),
		   "param_name" => "title",
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
		   "type" => "dropdown",
		   "heading" => esc_html__( "Quantity", "kentha" ),
		   "param_name" => "quantity",
			"std" => "6",
		   'value' => array("1","2", "3", "4",  "6", "8", "9", "12"),
		   "description" => esc_html__( "Number of items to display", "kentha" )
		),
		
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Filter by category (slug)", "kentha" ),
		   "description" => esc_html__("Instert the slug of a category to filter the results","kentha"),
		   "param_name" => "category"
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Offset (number)", "kentha" ),
		   "description" => esc_html__("Number of posts to skip in the database query","kentha"),
		   "param_name" => "offset"
		)
	 )
  ) );
}}


		



