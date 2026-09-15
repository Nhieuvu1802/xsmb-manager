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
$kentha_bpm = get_post_meta( $id, 'kentha_bpm', true );
$kentha_duration = get_post_meta( $id, 'kentha_duration', true );




if ( $product->is_type( 'variable' ) ) {
	$buylink = get_the_permalink( $id );
} else {
	$buylink = add_query_arg("add-to-cart" ,   $id, get_the_permalink());
}


?>

<li class="qtmusicplayer-trackitem  qt-woocommerce-singletrack-loop__item">

	<?php  
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
	<p>
		<a href="<?php the_permalink(); ?>" class="qt-tit"><?php 
		echo esc_html( $title ); 
		?></a><br>
		<span class="qt-art qt-item-metas">
			<?php
			if( $kentha_artist ) { 
				?> <i class="material-icons">face</i><a href="<?php echo get_the_permalink( $kentha_artist[0] ); ?>"><?php echo get_the_title(  $kentha_artist[0]);  ?></a><?php  
			}

			if( $kentha_bpm ) { 
				?> <i class="material-icons">album</i><?php echo esc_html(  $kentha_bpm ); 
			} 

			$genres = get_the_term_list( $id, 'trackgenre', '<span>', '</span>, <span>', '</span>' );
			if( !is_wp_error( $genres ) && !empty( $genres ) ) { ?> <i class="material-icons">label_outline</i><?php echo wp_kses_post(  $genres ); } 
			if( $kentha_duration ) { ?> <i class="material-icons">schedule</i><?php echo esc_html(  $kentha_duration ); } 
			?>
		</span>
	</p>

	
	<div class="qt-addtocart">
		<?php  
		if( ( $product->managing_stock() && $product->is_in_stock() ) || !$product->managing_stock()) {
			if( $product->is_type( 'simple' ) ){
				$prodid = get_the_id();
				$buylink = add_query_arg("add-to-cart", $prodid, get_the_permalink());
			    ?>
			    <a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-btn qt-btn-primary product_type_simple add_to_cart_button ajax_add_to_cart">
					<?php if ( $price_html = $product->get_price_html() ) : ?>
						<span class="price"><?php echo $price_html; ?></span> 
					<?php else: ?>
						<span class=""><?php esc_html_e('Buy', 'kentha'); ?></span> 
					<?php endif; ?>
			    </a>
			  	<?php
			} elseif( $product->is_type( 'variable' ) ){
			   // Product has variations
			   	?>
			    <a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary"><?php esc_attr_e( 'Details', 'kentha' ); ?></a>
			  	<?php
			} else {
			 	echo apply_filters( 'woocommerce_loop_add_to_cart_link', // WPCS: XSS ok.
				sprintf( '<a href="%s" data-quantity="%s" class="%s" %s>%s</a>',
					esc_url( $product->add_to_cart_url() ),
					1,
					'qt-btn qt-btn-primary',
					'',
					esc_html( $product->add_to_cart_text() )
				),
				$product, array() );
			}
		}
		?>

		<?php  
		if ( $product->managing_stock() && ! $product->is_in_stock() ){
			?><h6 class="qt-woocommerce-soldout"><?php esc_html_e( 'Sold out' , 'kentha' ); ?></h6><?php
		}
		?>
		<?php  
		if (! $product->is_type( 'variable' ) ) {
			?>
			<a href="<?php echo get_the_permalink( $id ); ?>" class="qt-btn qt-btn-txt qt-btn-moreinfo qt-btn-secondary"><?php esc_html_e('More info', 'kentha'); ?></a>
			<?php  
		}
		?>

	</div>

</li>