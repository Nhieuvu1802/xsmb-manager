<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_sliderpost_shortcode')){
	function kentha_sliderpost_shortcode ($atts){
		extract( shortcode_atts( array(
			'title' => false,
			'class' => '',
			'items' => array(),
			'size' => 'large',
			'proportion' => 'wide',
			'proportionmob' => 'auto',
			'height' => '400',
			'hideold' => false,
			'id' => false,
			'quantity' => 3,
			'posttype' => 'post',
			'category' => false,
			'orderby' => 'date',
			'offset' => 0,
			'showmeta' => false,
			'btn' => false,
			'buttonlabel' => esc_html__('Read more', 'kentha'),
			'csize' => 'h2'
		), $atts ) );
		


		$offset = (int)$offset;
		if(!is_numeric($offset)) {
			$offset = 0;
		}
		
		// Query for my content
		 
		$args = array(
			'post_type' =>  $posttype,
			'posts_per_page' => $quantity,
			'post_status' => 'publish',
			'paged' => 1,
			'suppress_filters' => false,
			'offset' => esc_attr($offset),
			'ignore_sticky_posts' => 1
		);

		//Add category parameters to query if any is set
		 
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
			if($hideold){
				$args['meta_query'] = array(
					array(
						'key' => 'eventdate',
						'value' => date('Y-m-d'),
						'compare' => '>=',
						'type' => 'date'
					 )
				);
			};
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
		$wp_query_slider = new WP_Query( $args );
		ob_start();
		if ( $wp_query_slider->have_posts() ) : 
				?>
				<!-- SLIDER SHORTCODE ================================================== -->
				<div class="slider qt-material-slider qt-<?php echo esc_attr($proportion); ?>" data-height="<?php echo esc_attr($height); ?>" data-proportion="<?php echo esc_attr($proportion); ?>" data-proportionmob="<?php echo esc_attr($proportionmob); ?>">
					<ul class="slides">
						<?php
						while ( $wp_query_slider->have_posts() ) : $wp_query_slider->the_post();
							$post = $wp_query_slider->post;
							setup_postdata( $post );
							?>
							<li>
								<img src="<?php echo get_the_post_thumbnail_url(null, $size); ?>" alt="img">
								<div class="caption qt-slidecaption">
									<div class="qt-txt qt-negative">
										<?php 
										if($showmeta){ 
											?>
											<h4 class="qt-item-metas">
												<?php 
												switch($posttype){
													case 'artist':
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
											</h4>	
											<?php 
										} 
										?>
										<h3 class="qt-fontsize-<?php echo esc_attr($csize); ?>"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
										<?php 
										if($btn){ 
											?>
											<p>
												<a href="<?php the_permalink(); ?>" class="qt-link qt-capfont"><?php  echo esc_html( $buttonlabel ); ?></a>
											</p>
											<?php 
										} 
										?>
									</div>
								</div>
							</li>
							<?php 
						endwhile;  
						?>
					</ul>
					<div class="qt-control-arrows">
						<a href="#" class="prev qt-slideshow-link"><i class='material-icons qt-icon-mirror'>arrow_back</i></a>
						<a href="#" class="next qt-slideshow-link"><i class='material-icons'>arrow_forward</i></a>
					</div>
				</div>
				<!--  SLIDER SHORTCODE END ================================================== -->
				<?php  
		endif;
		wp_reset_postdata();
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-sliderpost","kentha_sliderpost_shortcode");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_sliderpost_shortcode_vc' );
if(!function_exists('kentha_sliderpost_shortcode_vc')){
function kentha_sliderpost_shortcode_vc() {
  vc_map( 

		array(
			 "name" => esc_html__( "Slideshow post", "kentha" ),
			 "base" => "kentha-sliderpost",
			 "icon" => get_template_directory_uri(). '/img/post-slider.png',
			 "description" => esc_html__( "Slideshow of posts", "kentha" ),
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
					   "type" => "checkbox",
					   "heading" => esc_html__( "Hide past events", "kentha" ),
					   "description" => esc_html__( "For events post type only", "kentha" ),
					   "param_name" => "hideold",
					   'value' => ''
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
							__("Thumbnail", "kentha")	=>"thumbnail",
							__("Medium", "kentha")		=>"medium",
							__("Large", "kentha")		=>"large",
							__("Full", "kentha")		=> "full"
						),
					   "description" => esc_html__( "Choose the size of the images", "kentha" )
					),
					array(
					   "type" => "dropdown",
					   "heading" => esc_html__( "Slider proportion", "kentha" ),
					   "param_name" => "proportion",
					   "std" => "wide",
					   'value' => array(
					   		__("Widescreen 16:7", "kentha")		=>"wide",
							__("Fixed (specify below)", "kentha")	=>"auto",
							__("Ultrawide 2:1", "kentha")		=>"ultrawide",
							__("Fullscreen", "kentha")		=>"full",
						),
					   "description" => esc_html__( "Choose the size of the images", "kentha" )
					),
					array(
					   "type" => "dropdown",
					   "heading" => esc_html__( "Slider proportion mobile", "kentha" ),
					   "param_name" => "proportionmob",
					   "std" => "auto",
					   'value' => array(
							__("Fixed (specify below)", "kentha")	=>"auto",
							__("Widescreen 16:7", "kentha")		=>"wide",
							__("Ultrawide 2:1", "kentha")		=>"ultrawide",
							__("Fullscreen", "kentha")		=>"full",
						),
					   "description" => esc_html__( "Choose the size of the images", "kentha" )
					),
					array(
					   "type" => "textfield",
					   "heading" => esc_html__( "Fixed height", "kentha" ),
					   "param_name" => "height",
					   'value' => ''
					),
					array(
					   "type" => "textfield",
					   "heading" => esc_html__( "Button label", "kentha" ),
					   "param_name" => "buttonlabel",
					),
					array(
					   "type" => "checkbox",
					   "heading" => esc_html__( "Display button", "kentha" ),
					   "description" => esc_html__( "Add a read more button below titles", "kentha" ),
					   "param_name" => "btn",
					   'value' => ''
					),
					array(
					   "type" => "checkbox",
					   "heading" => esc_html__( "Display meta info", "kentha" ),
					   "description" => esc_html__( "Display author, date and more depending on the post type", "kentha" ),
					   "param_name" => "showmeta",
					   'value' => ''
					),
					array(
					   "type" => "dropdown",
					   "heading" => esc_html__( "Caption size", "kentha" ),
					   "param_name" => "csize",
					   "std" => "h2",
					   'value' => array(
							__("h6", "kentha")	=>"h6",
							__("h5", "kentha")		=>"h5",
							__("h4", "kentha")		=>"h4",
							__("h3", "kentha")		=> "h3",
							__("h2", "kentha")		=> "h2",
							__("h1", "kentha")		=> "h1",
							__("h0", "kentha")		=> "h0"
						),
					   "description" => esc_html__( "Caption size", "kentha" )
					),


			)
		)
  );
}}