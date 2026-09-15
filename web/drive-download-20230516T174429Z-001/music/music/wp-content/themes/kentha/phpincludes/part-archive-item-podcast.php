<article id="post-<?php echo get_the_id(); ?>" <?php post_class("qt-part-archive-item qt-carditem qt-podcast qt-card qt-paper qt-interactivecard qt-scrollbarstyle"); ?>>
	<div class="qt-iteminner">
		<div class="qt-imagelink" data-activatecard >
			<span class="qt-header-bg" data-bgimage="<?php echo get_the_post_thumbnail_url(null,'kentha-squared'); ?>" data-parallax="0" data-attachment="local">
			</span>
		</div>
		<header class="qt-header">
			<div class="qt-headings" >
				<h3 class="qt-title qt-ellipsis qt-t" data-activatecard><?php the_title(); ?></h3>
				<?php  
				$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
				$date = date( get_option( "date_format", "d M Y" ) , strtotime(get_post_meta($post->ID, '_podcast_date',true)));
				if($artist || $date){
					?>
					<span class="qt-details qt-item-metas" data-activatecard>
						<?php 
						echo esc_html($artist); 
						if($artist && $date){ ?> | <?php }
						echo esc_html($date);
						?>
					</span>
					<?php
				}
				?>
				<span class="qt-capseparator" data-activatecard></span>
				<?php
				/**
				 * This is the podcast player. Can be MP3 or soundcloud/mixcloud/youtube/vimeo...
				 * In WordPress allow also HTML embed code or shortcodes (custom field)
				 */
				$resource_url = get_post_meta( get_the_id(), '_podcast_resourceurl', true );
				//======================= PLAYER ======================
				if($resource_url !=''){
					$regex_mixcloud = "/mixcloud.com/"; 
					$regex_soundcloud = "/soundcloud.com/";                  
					$regex_mp3 = "/.mp3/";
					$regex_youtube = "/youtube.com/";
					if (preg_match ( $regex_mp3 , $resource_url ) ) {
						if(kentha_has_player()){


						 /**
						 * =======================================================
						 * Since 1.3.9
						 * adding download or purchase options to podcast
						 * =======================================================
						 */
						
						$link = get_post_meta(get_the_id(), 'releasetrack_buyurl', true);
						if ( !$link || $link == '' ){
							$link = get_post_meta(get_the_id(), '_podcast_link', true);
						}
						$icon = get_post_meta(get_the_id(), 'icon_type', true);
						$price = get_post_meta(get_the_id(), 'price', true);

						switch ($icon){
							case "download": 
								$icon = 'file_download';
								break;
							case "cart": 
							default:
								$icon = 'add_shopping_cart';
						}

						/// End update ===========================================
						?>
						<div class="qtmusicplayer-trackitem qt-donut">
							<a href="#" class="qt-play qt-link-sec qtmusicplayer-play-btn qt-podcast-quickplayer" data-qtmplayer-cover="<?php 	echo get_the_post_thumbnail_url(); ?>" data-qtmplayer-file="<?php 		echo esc_url( $resource_url ); ?>" data-qtmplayer-title="<?php 	/* Need sanitarization for both js and attr */ echo esc_js( esc_attr( get_the_title() ) ); ?>" data-qtmplayer-artist="<?php 	/* Need sanitarization for both js and attr */ echo esc_js(esc_attr( get_post_meta( get_the_id(), '_podcast_artist', true ) )); ?>" data-qtmplayer-album="<?php 	/* Need sanitarization for both js and attr */ echo esc_js(esc_attr( get_post_meta( get_the_id(), '_podcast_artist', true ) )); ?>" data-qtmplayer-link="<?php 		the_permalink(); ?>" 
								
							data-qtmplayer-buylink="<?php echo esc_attr( $link ); ?>"
							data-qtmplayer-icon="<?php echo esc_attr( $icon ); ?>"
							data-qtmplayer-price="<?php echo esc_attr( $price ); ?>" 
							>
								<i class='material-icons'>play_circle_filled</i>
							</a>
							<?php the_post_thumbnail(); ?>
						</div>
						<?php
						} else {
							?><div class="qt-embeddedplayer"><?php
							echo do_shortcode('[audio src="'.esc_url($resource_url).'"]');
							?></div><?php
						}
					 } else {
						?>
						<div class="qt-embeddedplayer">
							<div  class="qt-differembed" data-autoembed="<?php echo esc_url( $resource_url ); ?>"><?php esc_html_e("Loading player", "kentha"); ?></div>
						</div>
						<?php  
					}
				}

				/**
				 * Get podcast from playlist shortcode
				 */
				if(!$resource_url  || $resource_url!=''){
					$content = get_the_content();
					if ( has_shortcode($content, 'playlist') ) { 
						$pattern = get_shortcode_regex();
						preg_match_all('/'.$pattern.'/s', $content, $matches);
						$lm_shortcode = array_keys($matches[2],'playlist'); // lista di tutti gli ID di shortcodes di tipo playlist. Se ne ho 1 torna 0
						ob_start();
						if (count($lm_shortcode) > 0) {
							$buylink_std = '';
							$buy_links = get_post_meta(get_the_id(), 'track_repeatablebuylinks', false);
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
										$artist = $metadata['artist'];
										$file = wp_get_attachment_url($audio_id);
										$buyurl = false; // for now we have no buy URL for drop-in tracks (how can we? Copy buy from album?)
										$icon = '';
										?>
										<div class="qtmusicplayer-trackitem qt-donut">
											<a href="#" class="qt-play qt-link-sec qtmusicplayer-play-btn qt-podcast-quickplayer" data-qtmplayer-cover="<?php echo get_the_post_thumbnail_url(); ?>" data-qtmplayer-file="<?php echo esc_url($file); ?>" data-qtmplayer-title="<?php echo esc_attr($tracktitle); ?>" data-qtmplayer-artist="<?php echo esc_attr($artist); ?>" data-qtmplayer-album="<?php echo esc_attr(get_the_title()); ?>" data-qtmplayer-link="<?php echo esc_url($link); ?>" data-qtmplayer-buylink="<?php echo esc_url( $buylink_std); ?>" data-qtmplayer-icon="insert_link">
												<i class='material-icons'>play_circle_filled</i>
											</a>
											<?php the_post_thumbnail(); ?>
										</div>
										<?php
									}
								}
								$active = '';
							}
						}
						echo  ob_get_clean();
					}
				}
				?>
				<i class="material-icons qt-close" data-activatecard>close</i>
			</div>
			<div class="qt-actionbtn fixed-action-btn horizontal click-to-toggle">
				<a href="<?php the_permalink(); ?>" class="btn-floating btn-large qt-btn-primary">
					<i class="material-icons">add</i>
				</a>
			</div>
			<i class="material-icons qt-ho" data-activatecard>keyboard_arrow_down</i>
		</header>
		<span class="qt-animation" data-color="<?php echo get_theme_mod( 'kentha_color_secondary', '#ff0d51' ); ?>" ></span>
		<div class="qt-content">
			<div class="qt-summary">
				<?php 
				$tracklist = get_post_meta($post->ID, 'podcast_tracklist', true);
				if(count($tracklist)>0){ 
					if($tracklist[0]['title'] != ''){
					?>
					<h5 class="qt-caption-small"><?php esc_html_e("Tracklist","kentha"); ?></h5>
				<?php 
				}} ?>
				<?php get_template_part('phpincludes/part-tracklist' ); ?>
				<?php 
					the_excerpt();
				?>
			</div>
		</div>
	</div>
</article>