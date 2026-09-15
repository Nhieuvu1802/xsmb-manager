<?php 

global $product;
$id = get_the_ID();

/**
 * Details
 * made from file custom-product-fields.php
 */


$releasetrack_mp3_demo 	= get_post_meta(  $id, 'releasetrack_mp3_demo', true );
$thumb 					= get_the_post_thumbnail_url( $id ,'kentha-squared');
$title 					= get_the_title( $id );
$link 					= get_the_permalink( $id );
$tinythumb 				= get_the_post_thumbnail_url(null,'post-thumbnail');
$kentha_artist 			= get_post_meta( $id, 'kentha_artist', true );
if ( $product->is_type( 'variable' ) ) {
	$buylink = get_the_permalink( $id );
} else {
	$buylink = add_query_arg("add-to-cart" ,   $id, get_the_permalink());
}
	?>
<div class="qt-prodcard-singletrack-mini"><?php  
	

	


	?><div class="qt-cardthumb"><?php  

		/** 
		 * Icon
		 * @since  2.0.3
		* =============================================================================*/
		kentha_software_icon($id);
	
		/**
		 * =============================================================================
		 * Thumbnail
		 * =============================================================================
		 */
		if($tinythumb){
			?>
			<img src="<?php echo esc_url($tinythumb); ?>" alt="cover">
			<?php
		}
	
		if ( ( $product->managing_stock() && $product->is_in_stock() ) || !$product->managing_stock() ){
			?>
				<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($releasetrack_mp3_demo); ?>" data-qtmplayer-title="<?php echo esc_attr( $title ); ?>" <?php if( $kentha_artist ) { ?>data-qtmplayer-artist="<?php echo esc_attr( get_the_title( $kentha_artist[0] ) ); ?>" <?php } ?> data-qtmplayer-album="<?php echo esc_attr( kentha_postcategories_text( 1, "trackgenre") ); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_url($link ); ?>"  data-qtmplayer-icon="add_shopping_cart" ><i class='material-icons'>play_circle_filled</i></span>
			<?php  
		} else {
			?>
			<span class="qt-play qt-play-noclick"></span>
			<?php  
		}
		?>
	</div>



	
	<div class="qt-item-metas">

		<span class="qt-track-genre qt-ellipsis"><?php echo kentha_postcategories( 1, "trackgenre"); ?></span>


		<?php  
		if( ( $product->managing_stock() && $product->is_in_stock() ) || !$product->managing_stock()) {
			if( $product->is_type( 'simple' ) ){
			   if ( $price_html = $product->get_price_html() ) : 
					echo $price_html; 
			   endif;
			} else {
				$variation_min_price = $product->get_variation_price('min');
			  	echo esc_html('From', 'kentha').' '.wc_price( $variation_min_price ); 
			} 
		} else {
			?><?php esc_html_e('Sold out', 'kentha') ?><?php
		}
		?>
	</div>

	<div class="qt-addtocart-section qt-paper">
		<a href="<?php the_permalink( $id ); ?>" class="qt-btn qt-btn-secondary"><?php esc_html_e('Info', 'kentha'); ?></a>
		<?php  
		if ( ( $product->managing_stock() && $product->is_in_stock() ) || !$product->managing_stock() ){
			if( $product->is_type( 'simple' ) ){
				$prodid = get_the_id();
				$buylink = add_query_arg("add-to-cart", $prodid, get_the_permalink());
			    ?>
			    <a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-btn qt-btn-primary product_type_simple add_to_cart_button ajax_add_to_cart"><?php if ( $price_html = $product->get_price_html() ) : ?><?php echo $price_html; ?><?php endif; ?></a>
			  	<?php
			} else {
			  	 // Product has variations
			   	?>
			   	<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary"><?php esc_html_e('Price', 'kentha') ?></a>
			   	<?php
			} 
		} else {
			?><a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary disabled qt-btn-disabled"><?php esc_html_e('Sold out', 'kentha') ?></a><?php
		}
		?>

	</div>

</div><?php /* qt-prodcard-singletrack-mini */ ?>