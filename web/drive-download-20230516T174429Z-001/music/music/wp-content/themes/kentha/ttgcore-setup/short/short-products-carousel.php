<?php
/*
Package: Kentha
*/
/* Global function to get terms
============================================= */
if(!function_exists('kentha_get_terms_array')) {
function kentha_get_terms_array( ) {
	$cats = get_terms(array(
		'hide_empty'=>false,
	));
	$result = array();
	if(is_wp_error( $cats ) || 0 === $cats){
		$result = array();
	}
	$current_taxonomy = '';
	foreach ( $cats as $cat )	{
		if( $cat->taxonomy == 'nav_menu'){
			continue;
		}
		$result[] = array(
			'value' => $cat->taxonomy.':'.$cat->slug,
			'label' => '['. str_replace('_', ' ', $cat->taxonomy) .'] <strong>'.$cat->name.'</strong>',
		);
	}
	return $result;
}}

if(!function_exists('kentha_product_carousel')) {
	function kentha_product_carousel($atts){

		/*
		 *	Defaults
		 * 	All parameters can be bypassed by same attribute in the shortcode
		 */
		extract( shortcode_atts( array(
			'id' => false,
			'quantity' => 6,
			'title' => false,
			'tax_filter' => false,
			'orderby' => 'date',
			'offset' => 0,
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
			'post_type' =>  'product',
			'posts_per_page' => $quantity,
			'post_status' => 'publish',
			'paged' => 1,
			'suppress_filters' => false,
			'offset' => esc_attr($offset),
			'ignore_sticky_posts' => 1
		);

		// ========== TAXONOMY FILTERING =================
		if( $tax_filter  ){
			$tax_filter_array = explode(',', trim($tax_filter) );
			$tax_atts = array();
			$tax_query = array(
				'relation' => 'OR'
			);
			foreach( $tax_filter_array as $var => $val){
				$tax = explode(':', $val);
				if( array_key_exists(1, $tax)){
					$tax_atts[ trim( $tax[0] ) ] [] = trim( $tax[1] );
				}
			}
			foreach( $tax_atts as $taxname => $termslist ){
				$tax_query[] = array(
					'taxonomy' 	=> trim( $taxname ),
					'field' 	=> 'slug',
					'terms'		=>  $termslist,
					'operator'	=> 'IN'
				);
			}
			$args[ 'tax_query'] = $tax_query;
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
					'post_type' =>  'product',
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
		ob_start();
		if ( $wp_query->have_posts() ) : 
			?>
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
						<?php if(  intval($quantity) > 3 && $design == 'default'){ ?>
						<div class="col s3 m4 qt-carouselcontrols qt-right">
							<i data-slickprev class="material-icons">chevron_left</i>
							<i data-slicknext class="material-icons">chevron_right</i>
						</div>
						<?php } ?>
					</div>
					<div class="qt-slickslider-container qt-slickslider-cards">
						<div class="row">
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
										<?php get_template_part ( 'phpincludes/part-archive-item-product'); ?>
									</div>
									<?php 
								endwhile;  
								?>
							</div>
						</div>
					</div>
					<?php if( intval($quantity) > 3 && $design == 'center'){ ?>
					<div class="qt-carouselcontrols">
						<i data-slickprev class="qt-arr"></i>
						<i data-slicknext class="qt-arr"></i>
					</div>
					<?php } ?>
				</div>
				
			</div>
			<?php else: 
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

if( function_exists( 'ttg_custom_shortcode' )) {
	ttg_custom_shortcode( "kentha-product-carousel" , "kentha_product_carousel" );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_product_carousel_vc_short' );
if(!function_exists('kentha_product_carousel_vc_short')){
function kentha_product_carousel_vc_short() {
  vc_map( array(
	 "name" => esc_html__( "Products carousel", "kentha" ),
	 "base" => "kentha-product-carousel",
	 "icon" => get_template_directory_uri(). '/img/wc-carousel.png',
	 "description" => esc_html__( "Products carousel", "kentha" ),
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
		   "type" => "textfield",
		   "heading" => esc_html__( "Title", "kentha" ),
		   "param_name" => "title",
		   'value' => false
		),
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
		   'value' => array("3", "6", "9", "12"),
		   "description" => esc_html__( "Number of items to display", "kentha" )
		),

		// Category filtering ===================================================================================================
		array(
			'type' 			=> 'autocomplete',
			'heading' => esc_html__( 'Filter by category', 'kentha' ),
			'description' => esc_html__( 'Enter categories, tags, formats or custom taxonomies.', 'kentha' ),
			'param_name' 	=> 'tax_filter',
			'admin_label' => true,
			'settings'		=> array( 
				'values' 		 => kentha_get_terms_array() ,
				'multiple'       => true,
				'sortable'       => true,
	      		'min_length'     => 1,
	      		'groups'         => false,  // In UI show results grouped by groups
	      		'unique_values'  => true,  // In UI show results except selected. NB! You should manually check values in backend
	      		'display_inline' => true, // In UI show results inline view),
			),
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


		



