<?php
/**
 * =================================================
 * Single release playlist
 * if I'm in a release page, load always this playlist first
 * =================================================
 * @since 1.9.0
 * @var array
 */
if(is_single() && get_post_type( get_the_id()) == 'release'){
	get_template_part('phpincludes/part-playlist' );  
}
/**
 * =================================================
 * END OF Single release playlist
 * =================================================
 */
?>