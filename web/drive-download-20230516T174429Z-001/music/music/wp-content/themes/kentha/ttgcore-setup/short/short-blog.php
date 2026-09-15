<?php
/*
Package: Kentha
*/
if(!function_exists('kentha_blog_shortcode')) {
	function kentha_blog_shortcode($atts){
		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' 		=> false,
			'quantity' 	=> 3,
			'posttype' 	=> 'post',
			'title' 	=> false,
			'category' 	=> false,
			'orderby' 	=> 'date',
			'offset' 	=> 0,
			'design' 	=> 'large'
			
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
			'post_type' 		=>  $posttype,
			'posts_per_page' 	=> $quantity,
			'post_status' 		=> 'publish',
			'paged' 			=> 1,
			'suppress_filters' 	=> false,
			'offset' 			=> esc_attr($offset),
			'ignore_sticky_posts' => 1
		);

		/**
		 * Add category parameters to query if any is set
		 */
		if (false !== $category && 'all' !== $category) {
			$args[ 'tax_query'] = array(
            	array(
                    'taxonomy' 	=> esc_attr( kentha_get_type_taxonomy( $posttype ) ),
                    'field' 	=> 'slug',
                    'terms' 	=> array(esc_attr($category)),
                    'operator'	=> 'IN' //Or 'AND' or 'NOT IN'
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

		// ========== QUERY BY ID =================
		if($id){
			$idarr = explode(",",$id);
			if(count($idarr) > 0){
				$quantity = count($idarr);
				$args = array(
					'post__in'=> $idarr,
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
		switch($design){
			case 'split':
				$template = 'part-archive-item-split';
				break;
			case 'card':
				$template = 'part-archive-item';
				break;
			case 'masonry':
				$template = 'part-archive-item-grid';
				break;
			case 'large':
			default:
				$template = 'part-archive-item-large';
		}

		ob_start();
		add_filter( 'excerpt_length', 'kentha_excerpt_length_20', 1000 );
		if($title){ 
			?>
			<h3 class="qt-sectiontitle"><?php echo esc_html($title); ?></h3>
			<hr class="qt-spacer-s">
			<?php 
		} 
		$customid = preg_replace('/[0-9]+/', '', uniqid());

		?>
		<div class="qt-shortcode-blog <?php if($design == 'card' || $design == 'masonry'){ ?> row <?php } ?> <?php if($design == 'masonry'){ ?>qt-masonry <?php } ?>" id="<?php echo esc_attr($customid); ?>">
			<?php  
				if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
				$post = $wp_query->post;
				setup_postdata( $post );
					if($design == 'card' || $design == 'masonry'){ ?><div class="col s12 m6 l4 qt-ms-item"><?php }
						get_template_part( 'phpincludes/'. $template );
					if($design == 'card' || $design == 'masonry'){ ?></div><?php } 
				endwhile;  else: 
					esc_html_e("Sorry, there is nothing for the moment.", "kentha");
				endif; 
			?>
		</div>
		<?php 
		remove_filter( 'excerpt_length', 'kentha_excerpt_length_20', 1000 );
		wp_reset_postdata();
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-blog","kentha_blog_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_blog_shortcode_vc' );
if(!function_exists('kentha_blog_shortcode_vc')){
function kentha_blog_shortcode_vc() {
  vc_map( array(
     "name"			=> esc_html__( "Blog archive", "kentha" ),
     "base" 		=> "kentha-blog",
     "icon" 		=> get_template_directory_uri(). '/img/blog-archive-vc-shortcode.png',
     "description" 	=> esc_html__( "Blog archive", "kentha" ),
     "category" 	=> esc_html__( "Theme shortcodes", "kentha"),
     "params" 		=> array(
     	array(
		   "type" 		=> "dropdown",
		   "heading" 	=> esc_html__( "Design", "kentha" ),
		   "param_name" => "design",
		   'value' 		=> array(
		   		esc_html__("Large", "kentha")		=>"large",
				esc_html__("Split", "kentha")		=> "split",
				esc_html__("Masonry", "kentha")		=> "masonry",
				esc_html__("Card list", "kentha")	=> "card",
			)
		),
        array(
           "type" 		=> "textfield",
           "heading" 	=> esc_html__( "Title", "kentha" ),
           "param_name" => "title",
           'value' 		=> false
        ),
        array(
           "type" 		=> "textfield",
           "heading" 	=> esc_html__( "ID, comma separated list (123,345,7638)", "kentha" ),
           "description"=> esc_html__( "Display only the contents with these IDs. All other parameters will be ignored.", "kentha" ),
           "param_name" => "id",
           'value' 		=> ''
        ),

      	array(
           "type" 		=> "textfield",
           "heading" 	=> esc_html__( "Quantity", "kentha" ),
           "param_name" => "quantity",
           "description"=> esc_html__( "Number of items to display", "kentha" )
        ),
        array(
           "type" 		=> "textfield",
           "heading" 	=> esc_html__( "Filter by category (slug)", "kentha" ),
           "description"=> esc_html__("Instert the slug of a category to filter the results","kentha"),
           "param_name" => "category"
        ),
		array(
		   "type" 		=> "textfield",
		   "heading" 	=> esc_html__( "Offset (number)", "kentha" ),
		   "description"=> esc_html__("Number of posts to skip in the database query","kentha"),
		   "param_name" => "offset"
		)
     )
  ) );
}}


		



