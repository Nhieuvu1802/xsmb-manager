<?php
/*
Package: Kentha
*/
if(!function_exists('kentha_carousel_post')) {
	function kentha_carousel_post($atts){
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
			'design' => 'default',			
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
		if ( $wp_query->have_posts() ) : 

		?>

		<!-- POSTS CAROUSEL ================================================== -->	
		<div class="qt-container qt-relative">
			<div class="qt-slickslider-outercontainer qt-slickslider-outercontainer__<?php echo esc_attr($design); ?> qt-relative">
				<div class="row">
					<div class="col s9 m8">
						<?php if($title){ ?>
							<h3 class="qt-sectiontitle "><?php echo esc_html($title); ?></h3>
						<?php } else { ?>
							<span class="qt-sectiontitle qt-fontsize-h3 qt-invisible"></span>
						<?php } ?>
					</div>
					<?php if( intval($quantity) > 3 && $design == 'default'){ ?>
					<div class="col s3 m4 qt-carouselcontrols qt-right">
						<i data-slickprev class="material-icons">chevron_left</i>
						<i data-slicknext class="material-icons">chevron_right</i>
					</div>
					<?php } ?>
				</div>
				<div class="row">
					<div class="qt-slickslider-container qt-slickslider-cards">
						<div class="qt-slickslider qt-invisible qt-animated qt-slickslider-multiple" data-slidestoshow="3" data-slidestoscroll="1" data-variablewidth="false" data-arrows="false" data-dots="true" data-infinite="true" data-centermode="false" data-pauseonhover="true" data-autoplay="false" data-arrowsmobile="false"  data-centermodemobile="false" data-dotsmobile="false"  data-slidestoshowmobile="1" data-variablewidthmobile="true" data-infinitemobile="false" data-slidestoshowipad="3">
							<?php
							while ( $wp_query->have_posts() ) : $wp_query->the_post();
							$post = $wp_query->post;
							setup_postdata( $post );
							/**
							 *  WE HAVE TO USE THE ARCHIVE ITEM FOR EACH SPECIFIC POSTTYPE
							 */
							?>
							<div class="qt-item qt-item-card col s12 m4">
								<?php get_template_part ( 'phpincludes/'.$template); ?>
							</div>
							<?php endwhile;  ?>
						</div>
						<?php if( intval($quantity) > 3 && $design == 'center'){ ?>
						<div class="qt-carouselcontrols">
							<i data-slickprev class="qt-arr"></i>
							<i data-slicknext class="qt-arr"></i>
						</div>
						<?php } ?>
					</div>
				</div>
			</div>
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
	ttg_custom_shortcode("kentha-carousel-post","kentha_carousel_post");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_vc_carousel_short' );
if(!function_exists('kentha_vc_carousel_short')){
function kentha_vc_carousel_short() {
  vc_map( array(
	 "name" => esc_html__( "Cards carousel", "kentha" ),
	 "base" => "kentha-carousel-post",
	 "icon" => get_template_directory_uri(). '/img/cards-carousel-vc-shortcode.png',
	 "description" => esc_html__( "Carousel of posts on 3 columns", "kentha" ),
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Design", "kentha" ),
		   "param_name" => "design",
		   "std" => "default",
		   'value' => array(
				esc_html__("Default: top right navigation", 'kentha') =>  "default",
				esc_html__("Center: side arrows, bottom center navigation", 'kentha') =>  "center",
			),
		   "description" => esc_html__( "Number of items to display", "kentha" )
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
		   'value' => array("1", "3", "4", "5", "6", "9", "12"),
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


		



