<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0
 * @version  2.0
 * @author QantumThemes 2019 Oct 07
 * 
 * Add track play in item product archive.
 * Requires "single track attribute" enabled
 * 
 */

if( !function_exists( 'kentha_woocommerce_productplay' )) {

	add_action('woocommerce_before_shop_loop_item' , 'kentha_woocommerce_productplay' , 0);
	
	function kentha_woocommerce_productplay(){

		/**
		 * Extract custom fields and taxonomies
		 */
		global $product;
		$id = $product->get_id();
		$singletrack = get_post_meta( $id, 'kentha_singletrack', true );
		if( '1' !== $singletrack ){
			return;
		}

		/**
		 * 
		 * ============================================================
		 * MANAGE ONE TIME SELL ITEMS
		 * ============================================================
		 * 
		 */
		
		if ( $product->managing_stock() && ! $product->is_in_stock() ){
			?>
				<div class="qt-woocommerce-productplay">
					<h6 class="qt-woocommerce-soldout"><?php esc_html_e( 'Sold out' , 'kentha' ); ?></h6>
				</div>
			<?php
		} else {

			/**
			 * Thumb
			 */
			$thumb = false;
			if ( has_post_thumbnail( $id ) ) {
				$thumb = get_the_post_thumbnail_url($id);
			}

			/**
			 * Details
			 * made from file custom-product-fields.php
			 */
			
			$releasetrack_mp3_demo = get_post_meta(  $id, 'releasetrack_mp3_demo', true );
			$title = get_the_title( $id );
			$link = get_the_permalink( $id );
			$kentha_artist = get_post_meta( $id, 'kentha_artist', true );

			$kentha_artist_name = false;
			if($kentha_artist){
				$kentha_artist_name = get_the_title( $kentha_artist[0] );
			}

			/**
			 * Purchase link
			 */
			if ( $product->is_type( 'variable' ) ) {
				$buylink = get_the_permalink( $id );
			} else {
				$buylink = $id;
			}

			?>
			<div class="qt-woocommerce-productplay">
				<div class="qtmusicplayer-trackitem">
					<span class="qt-play qt-link-sec qtmusicplayer-play-btn qt-podcast-quickplayer"  <?php if( $thumb ){ ?>data-qtmplayer-cover="<?php echo esc_attr( $thumb ); ?>"<?php } ?> <?php if( $kentha_artist_name ) { ?>data-qtmplayer-artist="<?php echo esc_attr( $kentha_artist_name ); ?>" <?php } ?> data-qtmplayer-file="<?php echo esc_url($releasetrack_mp3_demo); ?>"  data-qtmplayer-title="<?php echo esc_attr( $title ); ?>" data-qtmplayer-album="<?php echo esc_attr( kentha_postcategories_text( 1, "trackgenre") ); ?>"  data-qtmplayer-link="<?php echo esc_url($link); ?>"  data-qtmplayer-buylink="<?php echo esc_attr( $buylink ); ?>"  data-qtmplayer-icon="add_shopping_cart" data-qtmplayer-icon="cart" ><i class="material-icons qt-icons-circle">play_circle_filled</i></span>
				</div>
			</div>


			<div class="qt-woocommerce-genre qt-tags">
			<?php  
				$genres = get_the_term_list( $id, 'trackgenre', '', '', '' );
				if( !is_wp_error( $genres ) && !empty( $genres ) ) { echo wp_kses_post(  $genres ); } 
			?>
			</div>
			<?php
		}
	}
}







