<?php
/**
 *	@package    kentha
 *	@author 	QantumThemes
 */

/**==========================================================================================
 *
 *
 *	WooCommerce settings
 *
 * 
 ==========================================================================================*/
if(!function_exists('kentha_vc_get_asset_url')){
	function kentha_vc_get_asset_url( $path ) {
		return apply_filters( 'woocommerce_get_asset_url', plugins_url( $path, WC_PLUGIN_FILE ), $path );
	}
}


if ( class_exists( 'WooCommerce' ) ) {



	if(!function_exists('kentha_wc_files_inclusion') && function_exists('qt_ajax_pageload_is_active')){
		add_action( 'wp_enqueue_scripts', 'kentha_wc_files_inclusion', 999999 );
		function kentha_wc_files_inclusion(){
			$suffix           = defined( 'SCRIPT_DEBUG' ) && SCRIPT_DEBUG ? '' : '.min';

			/**
			 * Move this to the ajax plugin
			 */
			wp_register_script( 'kentha-price-slider',  get_template_directory_uri().'/woocommerce-helpers/assets/js/min/price-slider-min.js', array(), kentha_theme_version(), true );
			$register_scripts = array(
				'flexslider',
				'js-cookie',
				'jquery-blockui',
				'jquery-cookie',
				'jquery-payment',
				'photoswipe',
				'photoswipe-ui-default',
				// 'prettyPhoto',
				// 'prettyPhoto-init',
				// 
				'select2',
				'selectWoo',
				// 'wc-cart',
				'wc-cart-fragments',
				'wc-add-to-cart',
				'wc-add-to-cart-variation',
				'wc-single-product',
				// 'wc-price-slider',
				'kentha-price-slider',
				'woocommerce',

				'zoom',
			);
			foreach ( $register_scripts as $name ) {
				wp_enqueue_script( $name );
			}
			

			// css =============================================
			$register_styles = array(
				'woocommerce-layout',
				'woocommerce-smallscreen',
				'woocommerce-general',
			);
			foreach ( $register_styles as $name ) {
				wp_enqueue_style( $name );
			}
		}
	}



	/* Customize number of posts depending on the archive post type
	============================================= */
	if(!function_exists('kentha_woocommerce_productsfilter')){
		add_action( 'pre_get_posts', 'kentha_woocommerce_productsfilter_mainquery', 1, 999 );
		function kentha_woocommerce_productsfilter_mainquery( $query ) {

			if( $query->is_main_query() && !is_admin() && get_theme_mod('kentha_woocommerce_singletrack_enable') && get_theme_mod('kentha_woocommerce_design_shop' ) == 'tracklist' ){
				if ( $query->is_post_type_archive( 'product' ) 
				) {

					$query->set ( 
						'meta_query' ,
						array(
							array(
								'key' => 'kentha_singletrack',
								'value' => '1',
								'compare' => '=',
							 )
						)
					);
					return;
				}
			}
		}
	}
	



	/* Declare WooCommercecontainer support
	============================================= */
	add_action( 'after_setup_theme', 'kentha_woocommerce_support_add' );
	if (!function_exists('kentha_woocommerce_support_add')) {
	function kentha_woocommerce_support_add() {
		add_theme_support( 'woocommerce', array(
			'thumbnail_image_width'         => 380,
			'gallery_thumbnail_image_width' => 180,
			'single_image_width'            => 720,
		) );

		register_sidebar( array(
			'name'          => esc_html__( 'WooCommerce Sidebar', "kentha" ),
			'id'            => 'kentha-woocommerce-sidebar',
			'before_widget' => '<aside id="%1$s" class="widgetSidebar qt-widget col s12 m12 qt-ms-item %2$s">',
			'before_title'  => '<h5 class="qt-widget-title"><span>',
			'after_title'   => '</span></h5>',
			'after_widget'  => '</aside>'
		));

		
		
	}}


	add_filter( 'woocommerce_get_image_size_shop_single', 'kentha_woocommerce_set_product_img_size' );
	function kentha_woocommerce_set_product_img_size()
	{
		$size = array(
			'width'  => 380,
			'height' => 380,
			'crop'   => 1,
		);
		return $size;
	}

	/* Check if WooCommerce is installed and active
	============================================= */
	if(!function_exists('kentha_woocommerce_active')){
	function kentha_woocommerce_active(){
		return  class_exists( 'WC_API' );
	}}


	/**
	 * ==========================================================================================
	 *
	 *
	 * Returns current plugin version.
	 * @return string Plugin version
	 *
	 * 
	 * ==========================================================================================*/

	if(!function_exists('kentha_woocommerce_get_version')){
	function kentha_woocommerce_get_version() {
		if( true === kentha_woocommerce_active() ){	
			if ( ! function_exists( 'get_plugins' ) ) {
				require_once ABSPATH . 'wp-admin/includes/plugin.php';
			}
			$the_plugs = get_option('active_plugins');
			$plugin_base_name = 'woocommerce/woocommerce.php';
			// if is active check version
			if(in_array($plugin_base_name, $the_plugs)) {
				$all_plugins = get_plugins();		
				$kentha_woocommerce_name = 'woocommerce/woocommerce.php';
				// echo '<pre>';
				// print_r($all_plugins);
				// echo '</pre>';
				if(array_key_exists($kentha_woocommerce_name, $all_plugins)){
					return $all_plugins[$kentha_woocommerce_name]['Version'];
				}
			}
		}
		// or return 0 means no woocommerce
		return 0;
	}}


	/* Custom WooCommerce columns number
	============================================= */
	add_filter( 'loop_shop_columns', 'kentha_woocommerce_loop_columns', 9999 );
	add_filter( 'loop_shop_per_page', 'kentha_woocommerce_loop_itemsn', 20 );
	if (!function_exists('kentha_woocommerce_loop_columns')) {
	function kentha_woocommerce_loop_columns() {
		$layout = get_theme_mod( 'kentha_woocommerce_design', 'left-sidebar' );
		switch($layout){
			case 'fullpage':
				return 3;
				break; 
			case 'left-sidebar':
			case 'right-sidebar':
			default:
			return 2;
		}
	}}


	if (!function_exists('kentha_woocommerce_loop_itemsn')) {
	function kentha_woocommerce_loop_itemsn() {
		return 9;
	}}


	add_filter( 'loop_shop_per_page', 'kentha_woocommerce_loop_shop_per_page', 20 );

	function kentha_woocommerce_loop_shop_per_page( $cols ) {
	 
	  $layout = get_theme_mod( 'kentha_woocommerce_design', 'left-sidebar' );
		switch($layout){
			case 'fullpage':
				return 9;
				break; 
			case 'left-sidebar':
			case 'right-sidebar':
			default:
			return 8;
		}
	}
		

	/* Custom WooCommerce container CSS
	============================================= */
	remove_action( 'woocommerce_before_main_content', 'woocommerce_output_content_wrapper', 10);
	remove_action( 'woocommerce_after_main_content', 'woocommerce_output_content_wrapper_end', 10);
	// Open block
	add_action('woocommerce_before_main_content', 'kentha_woocommerce_theme_wrapper_start', 10);
	if (!function_exists('kentha_woocommerce_theme_wrapper_start')) {
	function kentha_woocommerce_theme_wrapper_start() {
	  echo '<section id="kenthawoocommerce" class="kentha-woocommerce-content">';
	}}
	// Close block
	add_action('woocommerce_after_main_content', 'kentha_woocommerce_theme_wrapper_end', 10);
	if (!function_exists('kentha_woocommerce_theme_wrapper_end')) {
	function kentha_woocommerce_theme_wrapper_end() {
	  echo '</section>';
	}}

	/* Append Woocommerce Classes for the theme
	=============================================*/
	add_filter('body_class', 'kentha_woocommerce_class_names_append_woo_classes');
	if ( ! function_exists( 'kentha_woocommerce_class_names_append_woo_classes' ) ) {
	function kentha_woocommerce_class_names_append_woo_classes($classes){
		$classes[] = ' woocommerce woomanual kentha-woocommerce-body';
		return $classes;
	}}

	/* Woocommerce cart update
	=============================================*/
	

	
	//add_filter( 'woocommerce_add_to_cart_fragments', 'kentha_woocommerce_header_add_to_cart_fragment' );
	if(!function_exists('kentha_woocommerce_header_add_to_cart_fragment')){
	function kentha_woocommerce_header_add_to_cart_fragment( $fragments ) {
		ob_start();
		?>
		<a class="cart-contents qt-btn-square" href="<?php echo WC()->cart->get_cart_url(); ?>" title="<?php _e( 'View your shopping cart', 'kentha'); ?>">
			<?php /*echo sprintf (_n( '%d item', '%d items', WC()->cart->get_cart_contents_count() ), WC()->cart->get_cart_contents_count() ); */ ?><?php echo WC()->cart->get_cart_total(); ?>
			<i class="material-icons">cart</i>
		</a> 
		<?php
		$fragments['a.cart-contents'] = ob_get_clean();
		return $fragments;
	}}



	/* Woocommerce related products amount
	=============================================*/
	add_filter( 'woocommerce_output_related_products_args', 'kentha_woocommerce_related_products_args' );
	if(!function_exists('kentha_woocommerce_related_products_args')){
	function kentha_woocommerce_related_products_args( $args ) {
		$args['posts_per_page'] = 3; // number of related products
		$args['columns'] = 3;
		return $args;
	}}


	/* Woocommerce flash sale icon
	=============================================*/
	add_filter( 'woocommerce_sale_flash', 'kentha_woocommerce_woo_sale_flash' );
	if(!function_exists('kentha_woocommerce_woo_sale_flash')){
	function kentha_woocommerce_woo_sale_flash() {
		return '<span class="kentha-onsale-icon qt-content-accent"><i class="material-icons">flash_on</i></span>';
	}}



	/* WooCommerce thumbnail settings
	=============================================*/
	add_action( 'after_switch_theme', 'kentha_woocommerce_image_dimensions', 1 );
	if(!function_exists('kentha_woocommerce_image_dimensions')){
	function kentha_woocommerce_image_dimensions() {
		global $pagenow;
		if ( ! isset( $_GET['activated'] ) || $pagenow != 'themes.php' ) {
			return;
		}
		$catalog = array(
			'width' 	=> '400',	// px
			'height'	=> '400',	// px
			'crop'		=> 1 		// true
		);
		$single = array(
			'width' 	=> '690',	// px
			'height'	=> '690',	// px
			'crop'		=> 1 		// true
		);
		$thumbnail = array(
			'width' 	=> '170',	// px
			'height'	=> '170',	// px
			'crop'		=> 1 		// false
		);
		// Image sizes
		update_option( 'shop_catalog_image_size', $catalog ); 		// Product category thumbs
		update_option( 'shop_single_image_size', $single ); 		// Single product image
		update_option( 'shop_thumbnail_image_size', $thumbnail ); 	// Image gallery thumbs
	}}

	/* WooCommerce custom search form HTML
	=============================================*/
	function get_product_search_form(){
		?>
		<form role="search" method="get" class="woocommerce-product-search qt-spacer-s" action="<?php echo esc_url( home_url( '/'  ) ); ?>">
			<div class="qt-search-inline">
				<label class="screen-reader-text" for="s"><?php _e( 'Search for:', 'kentha' ); ?></label>
				<input type="text" class="search-field  qt-input-m" placeholder="<?php echo esc_attr_x( 'Search Products&hellip;', 'placeholder', 'kentha' ); ?>" value="<?php echo get_search_query(); ?>" name="s" title="<?php echo esc_attr_x( 'Search for:', 'label', 'kentha' ); ?>" />
	
				<button class="qt-btn qt-btn-m qt-btn-primary waves-light" type="submit" name="action">
					<i class="material-icons">search</i>
				</button>
				<input type="hidden" name="post_type" value="product" />
			</div>
		</form>
		<?php
	}


	/* WooCommerce style css inclusione
	=============================================*/
	add_action( 'wp_enqueue_scripts', 'kentha_woocommerce_files_inclusion', 999999 );
	if(!function_exists('kentha_woocommerce_files_inclusion')){
	function kentha_woocommerce_files_inclusion() {
		wp_enqueue_style( 'kentha-woocommerce', get_template_directory_uri().'/css/qt-woocommerce-min.css', false, kentha_theme_version() );
	}}




	/*=====================================================
	///////////////////////////////////////////////////////
	// Optionally remove some WC css //////////////////////
	///////////////////////////////////////////////////////

	add_filter( 'woocommerce_enqueue_styles', 'kentha_woocommerce_dequeue_styles' );
	if (!function_exists('kentha_woocommerce_dequeue_styles')) {
	function kentha_woocommerce_dequeue_styles( $enqueue_styles ) {
		 unset( $enqueue_styles['woocommerce-general'] );	// Remove the gloss
		 unset( $enqueue_styles['woocommerce-layout'] );		// Remove the layout
		return $enqueue_styles;
	}}

	///////////////////////////////////////////////////////
	=====================================================*/

}
