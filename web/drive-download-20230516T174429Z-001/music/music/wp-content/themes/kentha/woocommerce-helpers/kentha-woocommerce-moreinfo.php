<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0
 * @version  2.0
 * @author QantumThemes 2019 Oct 07
 * 
 * Add a More Info button on the single track products
 * 
 */

if( !function_exists( 'kentha_woocommerce_moreinfo' )) {
	add_action('woocommerce_after_shop_loop_item' , 'kentha_woocommerce_moreinfo' , 10);
	function kentha_woocommerce_moreinfo(){
		global $product;
		$id = $product->get_id();
		if (! $product->is_type( 'variable' ) ) {
			if ( '1' == get_post_meta( $id, 'kentha_singletrack', true ) && get_theme_mod('kentha_woocommerce_singletrack_enable') ){
			?>
				<a href="<?php echo get_the_permalink( $id ); ?>" class="qt-btn qt-btn-secondary qt-btn-l qt-btn-moreinfo"><?php esc_html_e('More info', 'kentha'); ?></a>
			<?php
			}
		}
	}
}

