<?php
/*
Package: Kentha
*/

$lineup = get_post_meta($post->ID, 'event_lineup', true);
if(is_array($lineup)){
	?>
	<div class="qt-lineup-full">
	<?php
	foreach($lineup as $item){
		$artist_id =  $item['artist'][0];
		if($artist_id != ''){
			?>
			<a href="<?php echo get_the_permalink($artist_id); ?>" class="qt-lineup-item qt-content-primary-light" data-bgimage="<?php echo get_the_post_thumbnail_url( $artist_id, 'large' ); ?>">
				<div>
					<h4><?php echo get_the_title( $artist_id); ?></h4>
					<h6><?php echo esc_html($item['time']); ?></h6>
				</div>
			</a>
			<?php
		}
		// manually added artists
		if($item['manual_artist']){

			$img = wp_get_attachment_image_src($item['photo'],'post-thumbnail');
			if($img){
				$photo_url = $img[0];
			}


			?>
			<a href="<?php echo esc_attr($item['link']); ?>" class="qt-lineup-item qt-content-primary-light" data-bgimage="<?php echo $photo_url; ?>">
				<div>
					<h4><?php echo esc_html($item['name']); ?></h4>
					<h6><?php echo esc_html($item['time']); ?></h6>
				</div>
			</a>
			<?php

		}
	}
	?>
	</div>
	<?php
}

