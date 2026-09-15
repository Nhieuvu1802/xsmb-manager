<?php
/*
Package: Kentha
*/


$event_artists_lineup = get_post_meta( get_the_ID(), 'event_lineup', $single = true );
if(is_array($event_artists_lineup)){
	if(count($event_artists_lineup) > 0){
		$artists_array = '';
		if(array_key_exists('artist', $event_artists_lineup[0])){
			if($event_artists_lineup[0]['artist'][0] || $event_artists_lineup[0]['manual_artist']){
				?>
				<ul class="qt-lineup">
				<?php
				foreach ($event_artists_lineup as $item){
					
					// artist from archive
					$artist_id =  $item['artist'][0];
					if($artist_id) {
						?>
						<li><?php echo esc_html($item['time']); ?> - <strong><?php echo get_the_title( $artist_id); ?></strong></li>
						<?php
					}

					// manually added artist
					if( array_key_exists('manual_artist', $item)) {
						?>
						<li><?php echo esc_html($item['time']); ?> - <strong><?php echo esc_html($item['name']); ?></strong></li>
						<?php
					}
				}
				?>
				</ul>
				<?php
			}
		}
	}
}