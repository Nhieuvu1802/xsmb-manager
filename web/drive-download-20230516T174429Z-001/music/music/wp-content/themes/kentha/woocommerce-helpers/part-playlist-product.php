<?php
/*
Package: Kentha
*/

global $product;


$linked_release_ar = get_post_meta(  $product->get_id(), 'kentha_related_release', true );
$linked_release_id = $linked_release_ar[0];

$events = get_post_meta($linked_release_id, 'track_repeatable');
if(array_key_exists(0, $events)){
	$n = 1;
	$events = $events[0];
	$thumb = get_the_post_thumbnail_url( $linked_release_id ,'kentha-squared');
	$title = get_the_title( $linked_release_id );
	$link = get_the_permalink( $linked_release_id );
	?>
	<?php
	// Classic playlist created via metadata
	 
	foreach($events as $track){ 
		$neededEvents = array('releasetrack_track_title','releasetrack_scurl','releasetrack_buyurl','releasetrack_artist_name', 'add_shopping_cart', 'icon_type');
		foreach($neededEvents as $ne){
			if(!array_key_exists($ne,$track)){
				$track[$ne] = '';
			}
		}
		if($track['releasetrack_mp3_demo'] == ''){
				continue;
			}
		$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
		switch ($track['icon_type']){
			case "download": 
				$icon = 'file_download';
				break;
			case "cart": 
			default:
				$icon = 'add_shopping_cart';
		}
		?>
		<li class="qtmusicplayer-trackitem">
			<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($track['releasetrack_mp3_demo']); ?>" data-qtmplayer-title="<?php echo esc_attr($track['releasetrack_track_title']); ?>" data-qtmplayer-artist="<?php echo esc_attr($track['releasetrack_artist_name']); ?>" data-qtmplayer-album="<?php echo esc_attr($title); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_url($track['releasetrack_buyurl']); ?>" data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" ><i class='material-icons'>play_circle_filled</i></span>
			<p>
				<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($track['releasetrack_track_title']); ?></span><br>
				<span class="qt-art">
					<?php echo esc_attr($track['releasetrack_artist_name']); ?>
				</span>
			</p>
			<?php
			if($track['releasetrack_buyurl'] !== ''){ 
				/**
				 *
				 * WooCommerce update:
				 *
				 */
				$buylink = $track['releasetrack_buyurl'];
				if(is_numeric($buylink)) {
					$prodid = $buylink;
					$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
					?>
					<a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
					<?php  
				} else {
					?>
					<a href="<?php echo esc_url($buylink); ?>" class="qt-cart" target="_blank"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
					<?php
				}
			}  ?>
		</li>
		<?php 
		$n = $n + 1;
	} 
}

/**
 * Special playlist created from WP playlist
 * 
 * Extract songs from embedded playlist
 */


$content = get_post_field('post_content', $linked_release_id);
if ( has_shortcode($content, 'playlist') ) { 


	$pattern = get_shortcode_regex();
	preg_match_all('/'.$pattern.'/s', $content, $matches);
	$lm_shortcode = array_keys($matches[2],'playlist'); // lista di tutti gli ID di shortcodes di tipo playlist. Se ne ho 1 torna 0
	ob_start();
	if (count($lm_shortcode) > 0) {
		$buylink_std = '';
		$buy_links = get_post_meta($linked_release_id, 'track_repeatablebuylinks', false);
		if(array_key_exists(0, $buy_links)){
			$data = $buy_links[0];
			if(count($data)>0){
				$buylink_std = $data[0]['cbuylink_url'];
			}
		}
		foreach($lm_shortcode as $sc) {
			$string_data =  $matches[3][$sc];
			$array_param = shortcode_parse_atts($string_data);
			if(array_key_exists("ids",$array_param)){
				$ids_array = explode(',', $array_param['ids']);
				foreach($ids_array as $audio_id){
					$tracktitle = get_the_title($audio_id);
					$metadata = wp_get_attachment_metadata($audio_id);
					$artist = '';
					if(array_key_exists('artist', $metadata)){
						$artist = $metadata['artist'];
					}
					$file = wp_get_attachment_url($audio_id);
					$buyurl = false; // for now we have no buy URL for drop-in tracks (how can we? Copy buy from album?)
					$icon = '';
					$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
					?>
					<li class="qtmusicplayer-trackitem">
						<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($file); ?>" data-qtmplayer-title="<?php echo esc_attr($tracktitle); ?>" data-qtmplayer-artist="<?php echo esc_attr($artist); ?>" data-qtmplayer-album="<?php echo esc_attr($title); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_attr( $buylink_std); ?>" data-qtmplayer-icon="" ><i class='material-icons'>play_circle_filled</i></span>
						<p>
							<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($tracktitle); ?></span><br>
							<span class="qt-art">
								<?php echo esc_attr($artist); ?>
							</span>
						</p>
						<?php 
						if($buyurl){ 
							/**
							 *
							 * WooCommerce update:
							 * NO CART FOR NOW, these are drop-in track and we can't specify a single purchase link for each one,
							 * so the function is here in place but the $buyurl will be empty for now and no icon will appear.
							 * If one day we figure out how to manage this, the code is already here.
							 *
							 */
							$buylink = $buyurl;
							if(is_numeric($buylink)) {
								$prodid = $buylink;
								$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
								?>
								<a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
								<?php  
							} else {
								?>
								<a href="<?php echo esc_url($buylink); ?>" class="qt-cart" target="_blank"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
								<?php
							}
						} ?>
					</li>
					<?php 
					$n = $n + 1;
				}
			}
			$active = '';
		}	   
	}
	echo  ob_get_clean();
}
