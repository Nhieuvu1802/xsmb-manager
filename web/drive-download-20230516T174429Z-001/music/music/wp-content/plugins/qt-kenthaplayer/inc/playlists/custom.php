<?php
/**
 * =================================================
 * Kentha custom playlist
 * =================================================
 * @since 1.9.0
 * @var array
 */
$playlist = get_theme_mod( 'kentha_custom_playlist' );
if($playlist){
	if( is_array( $playlist )){
		$n = 1;
		foreach($playlist as $track){
			$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
			$neededEvents = array('title','artist','album','buylink','link', 'sample', 'art','icon', 'price');
			foreach($neededEvents as $ne){
				if(!array_key_exists($ne,$track)){
					$track[$ne] = '';
				}
			}
			switch ($track['icon']){
				case "download": 
					$icon = 'file_download';
					break;
				case "cart": 
				default:
					$icon = 'add_shopping_cart';
			}



			// Get the right thumbnail
			if( $track['art'] !== '' ) {
				$cover = wp_get_attachment_image_src( $track['art'], 'kentha-squared' );
				$thumb = wp_get_attachment_image_src( $track['art'], 'thumbnail' );
			} else {

			}

			// Get the sample URL
			$file = false;
			if( array_key_exists('sample',  $track)) {
				if( $track['sample'] !== '' ) {
					$file = wp_get_attachment_url( $track['sample'] );
					
					
					$price = $track['price'];

					?>
					

					<li class="qtmusicplayer-trackitem">
						<?php
						if( isset( $thumb ) ){
							?>
							<img src="<?php echo esc_url($thumb[0]); ?>" alt="cover">
							<?php
						}
						?>
						<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
						<?php if( isset( $cover ) ){ ?>data-qtmplayer-cover="<?php echo esc_url($cover[0]); ?>" <?php } ?>
						data-qtmplayer-file="<?php echo esc_url($file); ?>" 
						data-qtmplayer-title="<?php echo esc_attr($track['title']); ?>" 
						data-qtmplayer-artist="<?php echo esc_attr($track['artist']); ?>" 
						data-qtmplayer-album="<?php echo esc_attr($track['album']); ?>" 
						data-qtmplayer-link="<?php echo esc_url($track['link']); ?>" 
						data-qtmplayer-price="<?php echo esc_url($track['price']); ?>" 
						data-qtmplayer-buylink="<?php echo esc_attr($track['buylink']); ?>" 
						data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" ><i class='material-icons'>play_circle_filled</i></span>
						<p>
							<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($track['title']); ?></span><br>
							<span class="qt-art">
								<?php echo esc_attr($track['artist']); ?>
							</span>
						</p>
						<?php 
						if($track['buylink'] !== ''){
							/**
							 *
							 * WooCommerce update:
							 *
							 */
							$buylink = $track['buylink'];
							if(is_numeric($buylink)) {
								$prodid = $buylink;
								$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
								?>
								<a href="<?php echo esc_attr($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart">
								<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
								</a>
								<?php 
							} else {
								?>
								<a href="<?php echo esc_attr($buylink); ?>" class="qt-cart" target="_blank">
								<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
								</a>
								<?php
							}
						} 
						?>
					</li>

					<?php
				}
			}
			$n = $n + 1;
		}
	}
}


/**
 * =================================================
 * END OF Kentha custom playlist
 * =================================================
 */
