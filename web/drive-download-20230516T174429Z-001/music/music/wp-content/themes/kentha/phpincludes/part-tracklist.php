<?php
/*
Package: Kentha
*/


$tracklist = get_post_meta($post->ID, 'podcast_tracklist', true);


/**
 * The tracklist needs to be connected to a mp3 URL 
 * so we calculate the MP3 url from the post meta or attached playlist
 * @var [type]
 */
$resource_url = get_post_meta( get_the_id(), '_podcast_resourceurl', true );
if(!$resource_url){
	$content = get_the_content();
	if ( has_shortcode($content, 'playlist') ) { 
		$pattern = get_shortcode_regex();
		preg_match_all('/'.$pattern.'/s', $content, $matches);
		$lm_shortcode = array_keys($matches[2],'playlist'); // lista di tutti gli ID di shortcodes di tipo playlist. Se ne ho 1 torna 0
		if (count($lm_shortcode) > 0) {
		    foreach($lm_shortcode as $sc) {
				$string_data =  $matches[3][$sc];
				$array_param = shortcode_parse_atts($string_data);
		      	if(array_key_exists("ids",$array_param)){
		      		$ids_array = explode(',', $array_param['ids']);
		      		foreach($ids_array as $audio_id){
		      			$metadata = wp_get_attachment_metadata($audio_id);
		      			$resource_url = wp_get_attachment_url($audio_id);
		      		}
		      	}
		    }
		}
	}
}
// file calculation end

if($tracklist){ 
	if($tracklist[0]['title'] != ''){
	?>
	<ul class="qt-tracklist">
		<?php  
		// $tracklist = $tracklist[0];
		foreach ($tracklist as $item){
			if($item['title'] != '' && $item['cue'] !== ''){
				$cue = date( "H:i:s", strtotime($item['cue']));
				?>
				<li><a data-qttrackurl="<?php echo esc_url($resource_url); ?>" data-qtplayercue="<?php echo esc_attr($cue); ?>"><i class="material-icons">play_circle_outline</i></a> <?php echo esc_html($cue); ?> - <strong><?php echo esc_html($item['artist'].' - '.$item['title']); ?></strong></li>

				<?php
		}	}
		?>
	</ul>
	<?php 
	}
}