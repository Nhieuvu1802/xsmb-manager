<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_sliderproduct_shortcode')){
	function kentha_sliderproduct_shortcode ($atts){
		extract( shortcode_atts( array(
			'title' => false,
			'class' => '',
			'items' => array(),
			'size' => 'large',
			'proportion' => 'wide',
			'proportionmob' => 'auto',
			'height' => '400',
			'id' => false,
			'quantity' => 3,
			'tax_filter' => false,
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

							global $product;

							?>
							<li>
								<img src="<?php echo get_the_post_thumbnail_url(null, $size); ?>" alt="img">
								<div class="caption qt-slidecaption">
									<div class="qt-txt qt-negative">
										
										<h4 class="qt-item-metas">
											<?php if( $showmeta ){ echo get_the_term_list( $product->get_id(), 'product_cat', '', ' '); } ?>
											<?php if ( $price_html = $product->get_price_html() ) : ?><?php if( $showmeta ){ ?> / <?php } ?><span class="price"><?php echo $price_html; ?></span> <?php endif; ?> 
										</h4>	
											

										<h3 class="qt-fontsize-<?php echo esc_attr($csize); ?>"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
										
									
										<p>

										<?php 
										if( $product->is_type( 'simple' ) ){
											$prodid = get_the_id();
											$buylink = add_query_arg("add-to-cart", $prodid, get_the_permalink());
										    ?>
										    <a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-btn qt-btn-primary qt-btn-l qt-cart product_type_simple add_to_cart_button ajax_add_to_cart">		<?php esc_attr_e( 'Add to cart', 'kentha' ); ?>
										    </a>
										  	<?php
										} elseif( $product->is_type( 'variable' ) ){
										   // Product has variations
										   	?>
										    <a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary qt-btn-l"><?php esc_attr_e( 'View details', 'kentha' ); ?></a>
										  	<?php
										} else {
										 	echo apply_filters( 'woocommerce_loop_add_to_cart_link', // WPCS: XSS ok.
											sprintf( '<a href="%s" data-quantity="%s" class="%s" %s>%s</a>',
												esc_url( $product->add_to_cart_url() ),
												1,
												'qt-btn qt-btn-primary qt-btn-l',
												'',
												esc_html( $product->add_to_cart_text() )
											),
											$product, array() );
										 }
										 ?>
										 </p>
											
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
	ttg_custom_shortcode("kentha-sliderproduct","kentha_sliderproduct_shortcode");
}

/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_sliderproduct_shortcode_vc' );
if(!function_exists('kentha_sliderproduct_shortcode_vc')){
function kentha_sliderproduct_shortcode_vc() {
  vc_map( 

		array(
			 "name" => esc_html__( "Products slider", "kentha" ),
			 "base" => "kentha-sliderproduct",
			 "icon" => get_template_directory_uri(). '/img/wc-carousel.png',
			 "description" => esc_html__( "Slideshow of products", "kentha" ),
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