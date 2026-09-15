<?php  
/*
Package: kentha
*/


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



/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_single_tracks_products_shortcode')){
	function kentha_single_tracks_products_shortcode ($atts){
		extract( shortcode_atts( array(
			'class' => '',
			'tax_filter' => false,
			'list_design' => '',
			'items' => array(),
			'outofstock' => false,
			'id' => false,
			'quantity' => 3,
			'orderby' => 'date',
			'offset' => 0,
			'showmeta' => false,
			'btn' => false,
			'csize' => 'h2'
		), $atts ) );

		$offset = (int)$offset;
		if(!is_numeric($offset)) {
			$offset = 0;
		}
		
		// Query for my content
		 
		$args = array(
			'post_type' =>  'product',
			'posts_per_page' => $quantity,
			'post_status' => 'publish',
			'paged' => 1,
			'suppress_filters' => false,
			'offset' => esc_attr($offset),
			'ignore_sticky_posts' => 1
		);

		//Add category parameters to query if any is set
		 
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

		if($outofstock == 'hide'){
			$args['meta_query'] = array(
				'relation' => 'AND',
				array(
					'key' => 'kentha_singletrack',
					'value' => '1',
					'compare' => '=',
				 ),
				array(
					'key'       => '_stock_status',
					'value'     => 'outofstock',
					'compare'   => 'NOT IN'
				)
			);
		} else {
			$args['meta_query'] = array(
				array(
					'key' => 'kentha_singletrack',
					'value' => '1',
					'compare' => '=',
				 )
			);
		}


		// ========== QUERY BY ID END =================
		$wp_query_singletracks = new WP_Query( $args );
		ob_start();

		if ( $wp_query_singletracks->have_posts() ) : 
			?>
			<div class="qt-playlist-large qt-short-products-singletracks qt-woocommerce-singletrack-loop qt-paper qt-card">
				<ul class="qt-playlist qt-card">
					<?php  
					while ( $wp_query_singletracks->have_posts() ) : $wp_query_singletracks->the_post();
						$post = $wp_query_singletracks->post;
						setup_postdata( $post );
						get_template_part ('phpincludes/part-archive-item-product-singletrack', $list_design); 
						wp_reset_postdata();
					endwhile;
					?>
				</ul>
			</div>
			<?php 
		endif;
		wp_reset_postdata();
		
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-single-tracks-products","kentha_single_tracks_products_shortcode");
}

/**
 *  Visual Composer integration
 */

if(!function_exists('kentha_single_tracks_products_shortcode_vc')){
	add_action( 'vc_before_init', 'kentha_single_tracks_products_shortcode_vc' );
	function kentha_single_tracks_products_shortcode_vc() {
  		vc_map( 

			array(
				 "name" => esc_html__( "Products single tracks", "kentha" ),
				 "base" => "kentha-single-tracks-products",
				 "icon" => get_template_directory_uri(). '/img/music-product.png',
				 "description" => esc_html__( "List of single track products", "kentha" ),
				 "category" => esc_html__( "Theme shortcodes", "kentha"),
				 "params" => array(
					array(
					   "type" => "dropdown",
					   "heading" => esc_html__( "Design", "kentha" ),
					   "param_name" => "list_design",
					   'std' => '',
					   'value' => array(
							esc_html__("Default", "kentha")	=> "",
							esc_html__("Small", "kentha")	=> "small",
						),
					),
					array(
					   "type" => "dropdown",
					   "heading" => esc_html__( "Hide out of stock", "kentha" ),
					   "param_name" => "outofstock",
					   'value' => array(
							esc_html__("Show", "kentha")	=> false,
							esc_html__("Hide", "kentha")	=> "hide",
						),
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
					),

					// Category filtering ===================================================================================================
					array(
						'type' 			=> 'autocomplete',
						'heading' => esc_html__( 'Narrow data source', 'kentha' ),
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
					   "heading" => esc_html__( "Offset (number)", "kentha" ),
					   "description" => esc_html__("Number of posts to skip in the database query","kentha"),
					   "param_name" => "offset"
					),
					
				)
			)
	  	);
	}
}