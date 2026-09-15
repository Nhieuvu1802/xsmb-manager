<?php
/**
 * @package Kentha
 */



if ( ! function_exists( 'qtmp_is_mobile' ) ) {
function qtmp_is_mobile() {

	if(
		wp_is_mobile()
		|| strpos($_SERVER['HTTP_USER_AGENT'], 'iPhone') !== false
		|| strpos($_SERVER['HTTP_USER_AGENT'], 'iPad') !== false
		// || strpos($_SERVER['HTTP_USER_AGENT'], 'Android') !== false
		// || strpos($_SERVER['HTTP_USER_AGENT'], 'Kindle') !== false
		// || strpos($_SERVER['HTTP_USER_AGENT'], 'BlackBerry') !== false
		// || strpos($_SERVER['HTTP_USER_AGENT'], 'Opera Mini') !== false
		// || strpos($_SERVER['HTTP_USER_AGENT'], 'Opera Mobi') !== false
	) { return true; }
	return false;
}}



if(!function_exists('qt_musicplayer')){
	function qt_musicplayer(){
		$musicplayerapi = site_url( '/?kenthaplayer_json_data=' );
		$smflash = qt_kenthaplayer_flashurl();
		$color = get_theme_mod( 'kentha_color_secondary', '#ff0d51' );
		$data_analyzer = get_option( 'qt_kenthaplayer_basicplayer' );
		if(wp_is_mobile()){
			$data_analyzer = 0;
		}
		


		/**
		 * Since 1.8.3 check if I have channels or releases
		 */
		$quantity = 0;
		$args = array(
			'post_type' => 'radiochannel',
			'post_status' => 'publish',
		);
		$wp_query = new WP_Query( $args );
		$quantity = $quantity + $wp_query->found_posts;

		$args = array(
			'post_type' => 'release',
			'post_status' => 'publish',
		);
		$wp_query = new WP_Query( $args );
		$quantity = $quantity + $wp_query->found_posts;


		$playlist = get_theme_mod( 'kentha_custom_playlist' );
		if($playlist){
			if( is_array( $playlist )){
				if( count( $playlist ) > 0 ){
					$quantity = $quantity + count( $playlist );
				}
			}
		}

		/**
		 * @since @2.1.1
		 * Count also products
		 */
		if ( class_exists( 'WooCommerce' ) ) {
			if( get_theme_mod('kentha_woocommerce_singletrack_enable') ){
				$featureds = get_theme_mod( 'kentha_player_prodfeatured' );
				$ids_featured = str_replace(' ', '', $featureds);
				$arr_featprod = explode(',',$ids_featured);
				// Counter featured products
				$quantity = $quantity + count( $arr_featprod );
				// Counter default products
				$quantity = $quantity + intval( get_theme_mod( 'kentha_player_prodamount', '1' ) );

			}
		}


		/**
		 * New Chrome policy: autoplay is disabled
		 * @var string
		 * Forcing autoplay disabled to prevent Chrome-induced blocking
		 */
		// $autoplay = get_option( 'qt_kenthaplayer_autoplay' ); // Not anymore
		$autoplay = '';

		$pclasses = array("qt-mplayer", "qt-scrollbarstyle");
		if(qtmp_is_mobile()){
			$pclasses[] = "qt-mplayer-mobile";
		}
		if($quantity == 0) {
			$pclasses[] = "qt-hidden";
		}
		
		?>
		<div id="qtmusicplayer" class="<?php echo esc_attr( implode(' ', $pclasses)); ?>" 
			data-blanksound="<?php echo qt_kenthaplayer_blanksound_url(); ?>" 
			data-is-mobile="<?php echo qtmp_is_mobile(); ?>" 
			data-showplayer="<?php  echo esc_attr(get_option( 'qt_kenthaplayer_showplayer' )); ?>" 
			data-analyzer="<?php echo esc_attr($data_analyzer); ?>" 
			data-autoplay="<?php if( function_exists('qt_ajax_pageload_is_active') && !qtmp_is_mobile() ){  echo esc_attr( $autoplay ); } ?>" 
			data-hiquality="<?php  echo esc_attr(get_option( 'qt_kenthaplayer_hiquality' )); ?>" 
			data-qtmusicplayer-api="<?php echo esc_attr($musicplayerapi); ?>" 
			data-qtmusicplayer-smflash="<?php echo esc_attr($smflash); ?>">
			<?php
			
			/**
			 *	=================================================
			 *	Playlist container
			 * 	=================================================
			 */
			?>
			<div id="qtmusicplayer-playlistcontainer" class="qt-mplayer__playlistcontainer qt-content-primary">
				<div class="row qt-mplayer__playlistmaster">
					<div class="col s12 m4 l3">
						<div id="qtmusicplayer-cover" class="qt-mplayer__album">
							<a href="#" class="qt-btn qt-btn-ghost qt-btn-l qt-albumlink"><?php esc_html_e( "Go to album", 'qt-kenthaplayer' ); ?></a>
						</div>
					</div>
					<div id="qtmusicplayer-playlist" class="qt-mplayer__playlist qt-content-primary col s12 m8 l9">
						<?php  
						/**
						 * =================================================
						 * Tracks:
						 * Load the single tracks for the different post types
						 * =================================================
						 */
						?>
						<ul class="qt-playlist">
							<?php  
							include 'playlists/radios.php';
							include 'playlists/single.php';
							include 'playlists/products.php';
							
							include 'playlists/custom.php';
							include 'playlists/album.php';
							include 'playlists/podcast.php';
							?>
						</ul>
					</div>
				</div>
			</div>
			<?php
			/**
			 * =================================================
			 *	Control bar
			 * =================================================
			 */
			include '_controlbar.php';
			?>


			
		</div>

		<?php
		if(qtmp_is_mobile()){

			?>
			<a class="qt-mplayer__triucco qt-content-primary-dark" id="qtmPlayerMobenable"><h2><?php include '_mobile-message.php'; ?></h2></a>
			<?php
		}

		?>
		<?php 
		/**
		 * =================================================
		 * Waveform
		 * =================================================
		 */
		if(get_option( 'qt_kenthaplayer_basicplayer' )){ 
			?>
			<div id="qtmusicplayerWF"  class="qt-mplayer__waveform">
				<canvas></canvas>
			</div>
			<div id="qtmusicplayerFFT" data-color="<?php esc_attr_e($color); ?>" class="qt-mplayer__waves"></div>
			<?php 
		}

	}
}
