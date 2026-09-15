<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_short_releases_large')) {
	function kentha_short_releases_large($atts){
		
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
			'offset' => 0,
			'design' => 'default',
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

		if ( $wp_query->have_posts() ) : 
		?>

		<!-- POSTS CAROUSEL ================================================== -->	
		<div class="qt-container qt-relative">
			<div class="qt-slickslider-outercontainer qt-slickslider-outercontainer__<?php echo esc_attr($design); ?>">
				<div class="row">
					<div class="col s9 m8">
						<?php if($title){ ?>
							<h3 class="qt-sectiontitle "><?php echo esc_html($title); ?></h3>
						<?php } else { ?>
							<span class="qt-sectiontitle qt-fontsize-h3 qt-invisible"></span>
						<?php } ?>
					</div>
					<?php if($wp_query->post_count > 1  && $design == 'default'){ ?>
					<div class="col s3 m4 qt-carouselcontrols qt-right">
						<i data-slickprev class="material-icons">chevron_left</i>
						<i data-slicknext class="material-icons">chevron_right</i>
					</div>
					<?php } ?>
				</div>
				<div class="qt-relative">
					<div class="qt-slickslider-container qt-singleslide qt-slickslider-cards">
						<div class="qt-slickslider qt-invisible qt-animated qt-slickslider-multiple" data-slidestoshow="1" data-slidestoscroll="1" data-variablewidth="false" data-arrows="false" data-dots="true" data-infinite="true" data-centermode="false" data-pauseonhover="true" data-autoplay="4000" data-arrowsmobile="false"  data-centermodemobile="false" data-dotsmobile="false"  data-slidestoshowmobile="1" data-variablewidthmobile="true" data-infinitemobile="false" data-slidestoshowipad="1">
							<?php
							while ( $wp_query->have_posts() ) : $wp_query->the_post();
							$post = $wp_query->post;
							setup_postdata( $post );
							/**
							 *  WE HAVE TO USE THE ARCHIVE ITEM FOR EACH SPECIFIC POSTTYPE
							 */
							?>
							<div class="qt-item qt-item-card qt-card-featured">
								<?php get_template_part( 'phpincludes/part-archive-item-release-featured' ); ?>
							</div>
							<?php endwhile;  ?>
						</div>
					</div>
					<?php if($wp_query->post_count > 1 && $design == 'center'){ ?>
					<div class="qt-carouselcontrols">
						<i data-slickprev class="qt-arr"></i>
						<i data-slicknext class="qt-arr"></i>
					</div>
					<?php } ?>
				</div>
			</div>
		</div>
		<!--  POSTS CAROUSEL END ================================================== -->
		<?php endif;
		wp_reset_postdata();
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-releases-large","kentha_short_releases_large");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_releases_large_vc' );
if(!function_exists('kentha_short_releases_large_vc')){
function kentha_short_releases_large_vc() {
  vc_map( array(
     "name" => esc_html__( "Release featured", "kentha" ),
     "base" => "kentha-releases-large",
     "icon" => get_template_directory_uri(). '/img/release-l.png',
     "description" => esc_html__( "Display a featured release", "kentha" ),
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


		



