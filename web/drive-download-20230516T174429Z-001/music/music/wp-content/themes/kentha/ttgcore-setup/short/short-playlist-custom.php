<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_playlistcustom_shortcode')){
	function kentha_playlistcustom_shortcode ($atts){
		extract( shortcode_atts( array(
			'items' => array(),
		), $atts ) );
		

		if(!function_exists('vc_param_group_parse_atts') ){
			return;
		}
		ob_start();
		if(is_array($atts)){
			if(array_key_exists("items", $atts)){
				$items = vc_param_group_parse_atts( $atts['items'] );
			}
		}
		if(is_array($items)){
			$id = preg_replace('/[0-9]+/', '', uniqid('qttabs')); 

			?>
				<div class="qt-playlist-large">
					<ul class="qt-playlist">
					<?php  
					$n = 1;
					foreach($items as $track){
						if (!array_key_exists("mp3_demo", $track)) { 
							continue;
						}
						if ( $track['mp3_demo']  == '' ) { 
							continue; 
						}
						$neededEvents = array('title','album','album_id','buy','artist', 'icon', 'image');
						foreach($neededEvents as $ne){
							if(!array_key_exists($ne,$track)){
								$track[$ne] = '';
							}
						}
						$track_index = str_pad($n, 2 , "0", STR_PAD_LEFT);
						$mp3_demo = ($track["mp3_demo"] != '') ?  wp_get_attachment_url( $track['mp3_demo'] ) : '';
						$thumb =  ($track["image"] != '') ? wp_get_attachment_image_src($track['image'], 'post-thumbnail') : ''; 
						if (is_array($thumb)) { $thumb = $thumb[0]; }
						$link = ($track["album_id"] != '' ) ? get_the_permalink( $track['album_id'] )  : '';
						$album = ($track["album_id"] != '' ) ? get_the_title( $track['album_id'] )  : '';
						$title = ($track["title"] != '' ) ? $track['title'] : esc_html__('Missing title', 'kentha');
						$artist = ($track["artist"] != '' ) ? $track['artist'] : '';
						$buy = $track["buy"];
						$icon = ($track["icon"] != '') ? $track['icon'] : '';

						?>
						<li class="qtmusicplayer-trackitem">
							<span class="qt-play qt-link-sec qtmusicplayer-play-btn" data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" data-qtmplayer-file="<?php echo esc_url($mp3_demo); ?>" 
								data-qtmplayer-title="<?php echo esc_attr($title); ?>" 
								data-qtmplayer-artist="<?php echo esc_attr($artist); ?>" 
								data-qtmplayer-album="<?php echo esc_attr($album); ?>" 
								data-qtmplayer-link="<?php echo esc_url($link); ?>" 
								data-qtmplayer-buylink="<?php echo esc_url($buy); ?>" 
								data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" ><i class='material-icons'>play_circle_filled</i></span>
							<p>
								<span class="qt-tit"><?php echo esc_attr($track_index); ?>. <?php echo esc_attr($title); ?></span><br>
								<span class="qt-art">
									<?php echo esc_attr($artist); ?>
								</span>
							</p>
							<?php
							if($buy!== ''){ 
								/**
								 *
								 * WooCommerce update:
								 *
								 */
								$buylink = $buy;
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
					?>
				</ul>
			</div>
			<?php  
		}
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-playlistcustom","kentha_playlistcustom_shortcode");
}



/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_playlistcustom_shortcode_vc' );
if(!function_exists('kentha_playlistcustom_shortcode_vc')){
function kentha_playlistcustom_shortcode_vc() {
  vc_map( array(
	 "name" => esc_html__( "Playlist custom", "kentha" ),
	 "base" => "kentha-playlistcustom",
	 "icon" => get_template_directory_uri(). '/img/release-l.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		array(
			'type' => 'param_group',
			'value' => '',
			'param_name' => 'items',
			'params' => array(
				
				array(
					'type' => 'attach_image',
					'heading' => 'Image',
					'param_name' => 'image',
				),
				array(
					'type' => 'file_picker',
					'value' => '',
					'heading' =>  esc_html__( 'MP3 demo file (required)', "kentha" ),
					'param_name' => 'mp3_demo',
				),
				array(
					"type" => "textfield",
					"heading" => esc_html__( "Track title (required)", "kentha" ),
					"param_name" => "title",
				),
				array(
				   	"type" => "textfield",
				   	"heading" => esc_html__( "Artist", "kentha" ),
				   	"param_name" => "artist",
					'settings' => array( 'values' => kentha_get_type_posts_data('release') ),
				),
				array(
				   	"type" => "autocomplete",
				   	"heading" => esc_html__( "Album link", "kentha" ),
				   	'param_name' => 'album_id',
					'settings' => array( 'values' => kentha_get_type_posts_data('release') ),
				),
				array(
					"type" => "textfield",
					"heading" => esc_html__( "Buy link", "kentha" ),
					"description" => esc_html__( "Use numeric ID in case of WooCommerce products", "kentha" ),
					"param_name" => "buy",
				),
				array(
					"type" => "dropdown",
					"heading" => esc_html__( "Icon", "kentha" ),
					"param_name" => "icon",
					'value' => array(
							esc_html__("Cart", "kentha")	=>"add_shopping_cart",
						esc_html__("Download", "kentha")	=>"file_download",
					),
					"description" => esc_html__( "Only appear if you set a Buy Link", "kentha" )
				),
			)
		),
		
	 )
  ) );
}}