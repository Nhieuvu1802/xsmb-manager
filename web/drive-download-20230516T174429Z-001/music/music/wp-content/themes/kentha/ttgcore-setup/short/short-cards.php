<?php
/*
Package: Kentha
*/


if(!function_exists('kentha_card_shortcode')) {
	function kentha_card_shortcode($atts){

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
			'cols' => "12",
			'size' => 'medium',
			'csize' => 'h5'
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
		ob_start();

		if($title){ ?>
			<h3 class="qt-sectiontitle"><?php echo esc_html($title); ?></h3>
		<?php }
		?>
		<div class="row">
			<?php
			if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
			$post = $wp_query->post;
			setup_postdata( $post );

			?>
				<div class="col s12 m<?php echo esc_attr($cols); ?>">
					<!-- ITEM CARD  ========================= -->
					<div <?php post_class("qt-glass-card qt-negative"); ?> data-bgimage="<?php echo get_the_post_thumbnail_url(null, $size); ?>">
						<a href="<?php the_permalink(); ?>" class="qt-content">
							<<?php echo esc_attr($csize); ?>>
								<?php echo kentha_shorten( get_the_title(), 80); ?>
							</<?php echo esc_attr($csize); ?>>
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
						</a>
					</div>
					<!-- ITEM CARD ========================= -->
				</div>
			<?php endwhile;  else: 
				esc_html_e("Sorry, there is nothing for the moment.", "kentha"); ?>
			<?php  
			endif; 
			wp_reset_postdata();?>
		</div>
		<?php
		/**
		 * Loop end;
		 */
		
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-card","kentha_card_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_card_shortcode_vc' );
if(!function_exists('kentha_card_shortcode_vc')){
function kentha_card_shortcode_vc() {
  vc_map( array(
     "name" => esc_html__( "Cards", "kentha" ),
     "base" => "kentha-card",
     "icon" => get_template_directory_uri(). '/img/cards-vc-shortcode.png',
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
		   "type" => "dropdown",
		   "heading" => esc_html__( "Columns", "kentha" ),
		   "param_name" => "cols",
		   'value' => array(
		   		esc_html__("1 column", "kentha") => '12',
				esc_html__("2 columns", "kentha") => '6',
				esc_html__("3 columns", "kentha") => '4',
				esc_html__("4 columns", "kentha") => '3',
				esc_html__("6 columns", "kentha") => '2',
			)
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
		   "heading" => esc_html__( "Caption size", "kentha" ),
		   "param_name" => "csize",
		   "std" => "h5",
		   'value' => array(
				esc_html__("h6", "kentha")	=>"h6",
				esc_html__("h5", "kentha")		=>"h5",
				esc_html__("h4", "kentha")		=>"h4",
				esc_html__("h3", "kentha")		=> "h3"
			),
		   "description" => esc_html__( "Caption size", "kentha" )
		),
     )
  ) );
}}


		



