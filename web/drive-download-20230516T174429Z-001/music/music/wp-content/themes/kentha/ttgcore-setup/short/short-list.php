<?php
/*
Package: Kentha
*/


if(!function_exists('kentha_list_shortcode')) {
	function kentha_list_shortcode($atts){

		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'quantity' => 3,
			'posttype' => 'post',
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
			case 'post':
			default:
				$template = 'part-archive-item';
		}


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
		?>

			<div class="qt-part-archive-item qt-item-inline qt-clearfix">
				<?php if(has_post_thumbnail()){ ?>
				<a class="qt-inlineimg" href="<?php the_permalink(); ?>">
					<img width="150" height="150" src="<?php echo get_the_post_thumbnail_url(null, 'thumbnail'); ?>" class="attachment-thumbnail size-thumbnail wp-post-image" alt="Thumbnail">
				</a>
				<?php } ?>

				<h6 class="qt-tit">
					<a class="" href="<?php the_permalink(); ?>">
						<?php 
						$title = get_the_title();
						echo esc_attr(kentha_shorten($title, 70) ); 
						if(strlen($title) > 70) { ?>...<?php }
						?>
					</a>
				</h6>

				<span class="qt-item-metas">
					<?php  
					switch($posttype){
						case 'artist':
							/*
							*
							*   Artist nationality
							*/
							$nat = get_post_meta($post->ID, '_artist_nationality',true);
							$res = get_post_meta($post->ID, '_artist_resident',true); 
							if($res){
								echo esc_html( $res );
							}
							if($nat && $res){ ?>&nbsp;<?php }
							if($nat){
								echo esc_html( '['.$nat.']' );
							}
							break;
						case 'release':
							$tracks = get_post_meta(get_the_id(), 'track_repeatable');
							if(is_array($tracks)){ 
								$tracks = $tracks[0]; 
								echo count($tracks);  ?>&nbsp;<?php esc_html_e( 'Tracks', 'kentha' ); 
							} ?> | <?php 
								echo date( "Y", strtotime(get_post_meta(get_the_id(), 'general_release_details_release_date',true))); 
							break;
						case 'podcast':
							$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
							$date = get_post_meta( get_the_id(), '_podcast_date', true );
							echo esc_html($artist); 
							if($artist && $date){ ?> | <?php }
							echo esc_html($date);
							break;
						case 'event':
							$date = date( 'd M Y', strtotime(get_post_meta($post->ID, 'eventdate',true)));
							$location = get_post_meta($post->ID, 'qt_location',true); 
							if($location){
								echo esc_html( $location );
							}
							if($date && $location){ ?> / <?php }
							if($date){
								echo esc_html($date);
							}
							break;
						case 'post':
						default:
							the_author(); ?> | <?php kentha_international_date();
					}
					?>
				</span>
			</div>
		<?php endwhile;  else: 
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
	ttg_custom_shortcode("kentha-list","kentha_list_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_list_short' );
if(!function_exists('kentha_vc_list_short')){
function kentha_vc_list_short() {
  vc_map( array(
	 "name" => esc_html__( "Posts list", "kentha" ),
	 "base" => "kentha-list",
	 "icon" => get_template_directory_uri(). '/img/posts-list-vc-shortcode.png',
	 "description" => esc_html__( "List of items with thumbnail", "kentha" ),
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(

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
			)
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
		   "type" => "textfield",
		   "heading" => esc_html__( "Quantity", "kentha" ),
		   "param_name" => "quantity",
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


		



