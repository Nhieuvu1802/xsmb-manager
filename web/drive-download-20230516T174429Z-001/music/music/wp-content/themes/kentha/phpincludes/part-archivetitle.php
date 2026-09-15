<?php
/*
Package: kentha
Description: title or logo
*/


/**
 * =================================
 * kentha_is_shop
 * This function tells you if we are in a shop page
 * =================================
 */
if(!function_exists('kentha_is_shop')){
	function kentha_is_shop(){
		if(function_exists("is_shop")){
			if( is_shop() || is_woocommerce() || is_product_category() || is_cart() || is_checkout() || is_account_page() || is_wc_endpoint_url() ){
				return true;
			} else {
				return false;
			}
		}
		return false;
	}
}

/**
 * =================================
 * kentha_shop_title
 * This function returns an appropriate string for the page title of a shop page
 * =================================
 */
if(!function_exists('kentha_shop_title')){
	function kentha_shop_title(){
		if(function_exists("is_shop")){
			if(function_exists("is_shop")){
				if( is_shop() ){
					return esc_html__('Shop' , 'kentha');
				}
				else if( is_cart() ){
					return esc_html__('Cart' , 'kentha');
				}
				else if( is_product() ){
					return get_the_title();
				}
				else if( is_checkout() ){
					return esc_html__('Checkout' , 'kentha');
				}
				else if( is_account_page() ){
					return esc_html__('Account' , 'kentha');
				} 
				else if( is_tax('trackgenre') ||  is_tax('royalty-types') ||  is_tax('tracksoftware') ){
					$termname = '';
					$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
					if(is_object($term)){
						echo esc_html($term->name);
					}
				}
				else if( is_wc_endpoint_url() ){
					if( is_wc_endpoint_url('order-pay') ){
						return esc_html__('Order payment' , 'kentha');
					} 
					else if( is_wc_endpoint_url( 'order-received' ) ){
						return esc_html__('Order received' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'view-order' ) ){
						return esc_html__('View order' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'edit-account' ) ){
						return esc_html__('Edit account' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'edit-address' ) ){
						return esc_html__('Edit address' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'lost-password' ) ){
						return esc_html__('Password recovery' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'customer-logout' ) ){
						return esc_html__('Log out' , 'kentha');
					}
					else if( is_wc_endpoint_url( 'add-payment-method' ) ){
						return esc_html__('Add payment method' , 'kentha');
					}
				}
				else  {
					return esc_html__('Shop' , 'kentha');
				}
			}
		}
		return;
	}
}




$logo_url = false;
if(is_singular() || is_single()){
	$logo = get_post_meta(get_the_id(), 'qt_page_logo', true);
	if($logo){
		$logo_url = wp_get_attachment_url( $logo );
		?>
		<img src="<?php echo esc_url($logo_url); ?>" alt="<?php esc_attr(get_the_title()); ?>" class="qt-title-logo">
		<?php
	}
}
if(!$logo_url){
	if ( is_category() ) : single_cat_title();
	elseif (is_page() || is_singular() ) : the_title();
	elseif ( is_search() ) : printf( esc_html(__( 'Search Results for: %s', "kentha" )), '<span>' . esc_html(get_search_query()) . '</span>' );
	elseif ( is_tag() ) : single_tag_title();
	elseif ( is_author() ) :
		the_post();
		the_author_meta('nickname');
		rewind_posts();
	elseif ( is_day() ) : printf( esc_html__( 'Day: %s', "kentha" ), '<span>' . esc_html(get_the_date()) . '</span>' );
	elseif ( is_month() ) : printf( esc_html__( 'Month: %s', "kentha" ), '<span>' . esc_html(get_the_date( 'F Y' )) . '</span>' );
	elseif ( is_year() ) :  printf( esc_html__( 'Year: %s', "kentha" ), '<span>' . esc_html(get_the_date( 'Y' )) . '</span>' );
	elseif ( is_tax( 'post_format', 'post-format-aside' ) ) : esc_html_e( 'Asides', "kentha" );
	elseif ( is_tax( 'post_format', 'post-format-image' ) ) : esc_html_e( 'Images', "kentha");
	elseif ( is_tax( 'post_format', 'post-format-video' ) ) : esc_html_e( 'Videos', "kentha" );
	elseif ( is_tax( 'post_format', 'post-format-quote' ) ) : esc_html_e( 'Quotes', "kentha" );
	elseif ( is_tax( 'post_format', 'post-format-link' ) ) : esc_html_e( 'Links', "kentha" );
	elseif ( is_tax( 'post_format', 'post-format-gallery' ) ) : esc_html_e( 'Galleries', "kentha" );
	elseif ( is_tax( 'post_format', 'post-format-audio' ) ) : esc_html_e( 'Sounds', "kentha" );
	/*
	*
	*   Custom post type titles
	*
	*/


	elseif(is_post_type_archive( 'chart' ) || is_tax('chartcategory')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name);
				} else {
					esc_html_e("Charts","kentha");            
				}
	elseif(is_post_type_archive( 'qtvideo' ) || is_tax('vdl_filters')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name);
				} else {
					esc_html_e("Videos","kentha");    
				}
	elseif (is_post_type_archive( 'podcast' ) || is_tax('podcastfilter')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name);
				} else {
					esc_html_e("Podcast","kentha"); 
				}
	elseif (is_post_type_archive( 'artist' ) || is_tax('artistgenre')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name).' ';
				} else {
					esc_html_e("Artists","kentha");  
				}

	elseif (is_post_type_archive( 'release' ) || is_tax('genre')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name);
				} else {
					echo esc_html__("Releases","kentha");  
				}
				
	elseif (is_post_type_archive( 'testimonial' ) || is_tax('testimonial-category')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name);
				} else {
					esc_html_e("Testimonials","kentha"); 
				}
	elseif (is_post_type_archive( 'event' ) || is_tax('eventtype')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name).' ';
				} else {
					esc_html_e("Events","kentha"); 
				}
	elseif (is_post_type_archive( 'members' ) || is_tax('membertype')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name).' ';
				} else {
					esc_html_e("Team","kentha"); 
				}
	elseif (is_post_type_archive( 'shows' ) || is_tax('qt-kentharadio-showgenre')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name).' ';
				} else {
					esc_html_e("Radio shows","kentha"); 
				}
	elseif (is_post_type_archive( 'radiochannel' ) ):      
				esc_html_e("Radio channels","kentha"); 

	elseif (is_post_type_archive( 'schedule' ) || is_tax('schedulefilter')):      
				$termname = '';
				$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
				if(is_object($term)){
					echo esc_html($term->name).' ';
				} else {
					esc_html_e("Radio schedules","kentha"); 
				}

	// WooCommerce
	elseif( kentha_is_shop() ) : 
		echo esc_html( kentha_shop_title() );// the function has already the translation inside
		

	/**
	 * @since
	 */
	elseif ( is_tax('trackgenre') || is_tax('royalty-types') ):      
			$termname = '';
			$term = get_term_by( 'slug', get_query_var( 'term' ), get_query_var( 'taxonomy' ) );
			if(is_object($term)){
				echo esc_html($term->name).' ';
			} else {
				esc_html_e("Tracks","kentha"); 
			}

	else: esc_html_e( 'Blog', "kentha" );
	endif;
}
?>