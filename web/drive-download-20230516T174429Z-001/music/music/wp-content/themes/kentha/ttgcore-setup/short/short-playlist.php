<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_short_playlist')) {
	function kentha_short_playlist($atts){
		extract( shortcode_atts( array(
			'id' => false,
		), $atts ) );
		ob_start();
		if ($id) {
			?>
			<div class="qt-playlist-large">
				<ul class="qt-playlist">
					<?php echo kentha_playlist_by_id($id); ?>
				</ul>
			</div>
			<?php  
		}
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-playlist","kentha_short_playlist");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_playlist_vc' );
if(!function_exists('kentha_short_playlist_vc')){
function kentha_short_playlist_vc() {
	vc_map( array(
		"name" => esc_html__( "Playlist", "kentha" ),
		"base" => "kentha-playlist",
		"icon" => get_template_directory_uri(). '/img/release-l.png',
		"description" => esc_html__( "Add a playlist from a release", "kentha" ),
		"category" => esc_html__( "Theme shortcodes", "kentha"),
		"params" => array(
			array(
	        	'type' 			=> 'autocomplete',
				'class' 		=> '',
				'heading' 		=> esc_html__( 'Release name', 'kentha' ),
				'param_name' 	=> 'id',
				'settings'		=> array( 'values' => kentha_get_type_posts_data('release') ),
			)
		)
	));
}}


		



