<?php

/* = This is used to serve json contents
=======================================================================*/
if(!function_exists('kenthaplayer_get_json_data')){
function kenthaplayer_get_json_data(){
	$tracks = array();
	if(have_posts()): while ( have_posts() ) : the_post();
		global $post;
		if(is_object($post)){
			$thumb = '';
			if(has_post_thumbnail()){
				$thumb = wp_get_attachment_image_src( get_post_thumbnail_id($post->ID), 'kentha-squared');
				$thumb = $thumb['0']; 
			}
			$track_repeatable = get_post_meta(get_the_id(), 'track_repeatable', true);
			foreach($track_repeatable as $tr){ 
				if($tr['releasetrack_mp3_demo'] == ''){
					continue;
				}
				$icon = 'add_shopping_cart';
				if(array_key_exists('icon_type', $tr)){
					if( $tr['icon_type'] == 'download' ){
						$icon = 'file_download';
					}
				}
				$releasetrack_buyurl ='';
				$releasetrack_mp3_demo ='';
				$releasetrack_artist_name ='';
				$releasetrack_track_title ='';
				$price = '';
				if(array_key_exists('releasetrack_buyurl', $tr)) {
					$releasetrack_buyurl = $tr['releasetrack_buyurl'];
				}
				if(array_key_exists('releasetrack_mp3_demo', $tr)) {
					$releasetrack_mp3_demo = $tr['releasetrack_mp3_demo'];
				}
				if(array_key_exists('releasetrack_artist_name', $tr)) {
					$releasetrack_artist_name = $tr['releasetrack_artist_name'];
				}
				if(array_key_exists('releasetrack_track_title', $tr)) {
					$releasetrack_track_title = $tr['releasetrack_track_title'];
				}
				if(array_key_exists('price', $tr)) {
					if ($tr['price'] !== 'undefined') {
						$price = $tr['price'];
					}
				}
				$tracks[] = array(
					'cover'		=> esc_url($thumb),
					'album' 	=> esc_attr(get_the_title()),
					'link' 		=> esc_attr(get_the_permalink()),
					'buylink' 	=> esc_attr($releasetrack_buyurl),
					'title' 	=> esc_attr($releasetrack_track_title),
					'icon' 		=> esc_attr($icon),
					'file' 		=> esc_attr($releasetrack_mp3_demo),
					'artist' 	=> esc_attr($releasetrack_artist_name),
					'price' 	=> esc_attr($price),
				);
			}
			
			/**
			 * Special playlist created from WP playlist
			 * Extract songs from embedded playlist
			 */
			$buylink_std = '';
			$buy_links = get_post_meta(get_the_id(), 'track_repeatablebuylinks', false);
			if(array_key_exists(0, $buy_links)){
				$data = $buy_links[0];
				if(count($data)>0){
					$buylink_std = $data[0]['cbuylink_url'];
				}
			}
			if ( has_shortcode( $post->post_content, 'playlist' ) ) { 
				$pattern = get_shortcode_regex();
				preg_match_all('/'.$pattern.'/s', get_the_content(), $matches);
				$lm_shortcode = array_keys($matches[2],'playlist'); // lista di tutti gli ID di shortcodes di tipo playlist. Se ne ho 1 torna 0
				if (count($lm_shortcode) > 0) {
				    foreach($lm_shortcode as $sc) {
						$string_data =  $matches[3][$sc];
						$array_param = shortcode_parse_atts($string_data);
				      	if(array_key_exists("ids",$array_param)){
				      		$ids_array = explode(',', $array_param['ids']);
				      		foreach($ids_array as $audio_id){
				      			$metadata = wp_get_attachment_metadata($audio_id);
				      			$artist = '';
				      			if(array_key_exists('artist', $metadata)){
				      				$artist = $metadata['artist'];
				      			}
				      			$tracks[] = array(
									'cover'		=> esc_url($thumb),
									'album' 	=> esc_attr(get_the_title()),
									'link' 		=> get_the_permalink(),
									'buylink' 	=> $buylink_std,
									'title' 	=> esc_attr(stripslashes(get_the_title($audio_id))),
									'icon' 		=> 'add_shopping_cart',
									'file' 		=> wp_get_attachment_url($audio_id),
									'artist' 	=> esc_attr($artist),
								);
				      		}
				      	}
				      	$active = '';
				    }	   
				}
			}
		}
	endwhile; endif; 
	die( json_encode($tracks));
}}
if(isset($_GET['qt_json'])){
	add_action('get_header','kenthaplayer_get_json_data');
}