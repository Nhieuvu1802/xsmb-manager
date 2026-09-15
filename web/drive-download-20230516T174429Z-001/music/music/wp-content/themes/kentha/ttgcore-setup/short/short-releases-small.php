<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_short_releases_small')) {
	function kentha_short_releases_small($atts){

		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'quantity' => 12,
			'posttype' => 'release',
			'title' => false,
			'category' => false,
			'orderby' => 'date',
			'size' => 'post-thumbnail',
			'offset' => 0,
			'cols' => "2"			
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


		// ========== QUERY BY ID =================
		if($id){
			$idarr = explode(",",$id);
			if(count($idarr) > 0){
				$quantity = count($idarr);
				$args = array(
					'post_type' =>  'release',
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

			$eventslinks= get_post_meta( get_the_id() , 'track_repeatablebuylinks', true );   
			$url =  add_query_arg('qt_json', '1',  get_the_permalink());

			?>
				<div class="col s6 m<?php echo esc_attr($cols); ?>">
					<!-- ITEM INLINE  ========================= -->
					<div <?php post_class("qt-part-archive-item qt-carditem qt-release-small"); ?>>
						
						<?php if(has_post_thumbnail()) { ?>
							<span class="qt-thumbactions">
								<?php the_post_thumbnail( $size, array('class' => "attachment-thumbnail size-thumbnail wp-post-image")); ?>
								<a href="<?php the_permalink(); ?>" class="noajax qt-playthis" data-kenthaplayer-addrelease="<?php echo add_query_arg('qt_json', '1',  get_the_permalink()); ?>" data-playnow="1">
									<i class="material-icons qt-icons-circle">play_arrow</i>
								</a>
								<a href="<?php the_permalink(); ?>" class="noajax qt-add qt-btn-secondary" data-clickonce="1" data-kenthaplayer-addrelease="<?php echo esc_url($url); ?>">
									<i class="material-icons">playlist_add</i>
								</a>
								<?php  
								if(is_array($eventslinks)){
									if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
										// WooCommerce integration 
										$buylink = $eventslinks[0]['cbuylink_url'];
										if(is_numeric($buylink)) {
											$prodid = $buylink;
											$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
											?>
											<a href="<?php echo esc_url( $buylink ); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="noajax qt-cartbt qt-btn-secondary product_type_simple add_to_cart_button ajax_add_to_cart">
												<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
											</a>
											<?php  
										} else {
											?>
											<a href="<?php the_permalink(); ?>" class="qt-cartbt qt-btn-secondary" rel="nofollow" target="_blank">
												<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
											</a>
											<?php
										}
									}
								}
								?>
							</span>
						<?php } ?>
						<span class="qt-details qt-small"></span>
						
						<h6 class="qt-tit">
							<a href="<?php the_permalink(); ?>" class="qt-ellipsis qt-t">
								<?php echo kentha_shorten(get_the_title(), 16); ?>
							</a>
						</h6>
						<span class="qt-item-metas qt-small">
							<?php 
							$tracks = get_post_meta(get_the_id(), 'track_repeatable');
							if(is_array($tracks)){ 
								$tracks = $tracks[0]; 
								echo count($tracks);  ?>&nbsp;<?php esc_html_e( 'Tracks', 'kentha' ); 
							} ?> | <?php 
								echo date( "Y", strtotime(get_post_meta(get_the_id(), 'general_release_details_release_date',true))); 
							?>
						</span>
					</div>
					<!-- ITEM INLINE END ========================= -->
				</div>
			<?php 
			endwhile;  else: 
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
	ttg_custom_shortcode("kentha-releases-small","kentha_short_releases_small");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_releases_small_vc' );
if(!function_exists('kentha_releases_small_vc')){
function kentha_releases_small_vc() {
  vc_map( array(
	 "name" => esc_html__( "Album releases", "kentha" ),
	 "base" => "kentha-releases-small",
	 "icon" => get_template_directory_uri(). '/img/album-releases-visual-composer-icon.png',
	 "description" => esc_html__( "List of releases with thumbnail", "kentha" ),
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
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
		   "std" => "2",
		   'value' => array(
				esc_html__("1 column", "kentha") => '12',
				esc_html__("2 columns", "kentha") => '6',
				esc_html__("3 columns", "kentha") => '4',
				esc_html__("4 columns", "kentha") => '3',
				esc_html__("6 columns", "kentha") => '2',
			)
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Image size", "kentha" ),
		   "param_name" => "size",
		   "std" => "post-thumbnail",
		   'value' => array(
				esc_html__("Thumbnail", "kentha")	=>"post-thumbnail",
				esc_html__("Medium", "kentha")		=>"medium",
				esc_html__("Large", "kentha")		=>"large",
			),
		   "description" => esc_html__( "Choose the size of the images", "kentha" )
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
		   "std" => "12",
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


		



