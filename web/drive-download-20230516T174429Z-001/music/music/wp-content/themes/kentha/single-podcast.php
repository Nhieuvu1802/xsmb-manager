<?php
/*
Package: Kentha
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-podcast qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" class="qt-container qt-main-contents">
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx" data-start>
				<div class="qt-pageheader__in">
					<div class="row">
						<div class="col s12 m4 l4">
							<?php if(has_post_thumbnail( )){ ?>
							<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'full' ); ?>">
								<?php the_post_thumbnail("medium" ); ?>
							</a>
							<?php } ?>
						</div>
						<div class="col s12 m8 l8">
							<span class="qt-tags">
								<?php echo get_the_term_list( get_the_id(), 'podcastfilter'); ?>
							</span>

							<div class="<?php kentha_is_negative(); ?>">
								<h1 class="qt-caption"><?php the_title(); ?></h1>
								<span class="qt-item-metas">
									<?php  
									/**
									 * [$artist artist name with optional link]
									 */
									$artist = get_post_meta( $post->ID, '_podcast_artist', true );
									if($artist){

										$artist_id_ob = get_page_by_title( $artist, 'OBJECT', 'artist' );
										if( is_object( $artist_id_ob )) {
											$artist_id = $artist_id_ob->ID ;
											if($artist){
												?>
												<?php if($artist_id){ ?><a href="<?php echo get_the_permalink( $artist_id ); ?>" class="qt-art"><?php } ?><?php echo esc_html($artist); ?><?php if($artist_id){ ?></a><?php } ?>
												<?php 
											} 
										} else {
											echo esc_html($artist);
										}
									}
									/**
									 * [$date podcast date]
									 */
									$date = get_post_meta( get_the_id(), '_podcast_date', true );
									if($date){
										$date = date( get_option( "date_format", "d M Y" ) , strtotime($date));
										echo ' | '.esc_html($date);
									}
									?>
								</span>
							</div>
							<?php  
							/**
							 * This is the podcast player. Can be MP3 or soundcloud/mixcloud/youtube/vimeo...
							 * In WordPress allow also HTML embed code or shortcodes (custom field)
							 */
							$resource_url = get_post_meta( get_the_id(), '_podcast_resourceurl', true );
			                //======================= PLAYER ======================
			                if($resource_url != ''){
			                    $regex_mixcloud = "/mixcloud.com/"; 
			                    $regex_soundcloud = "/soundcloud.com/";                       
			                    $regex_mp3 = "/.mp3/";
			                    $regex_youtube = "/youtube.com/";


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



			                    if (preg_match ( $regex_mp3 , $resource_url  )) {
									if(kentha_has_player()){
									?>
									<ul class="qt-playlist qt-the-content qt-paper qt-card">
										<li class="qtmusicplayer-trackitem">
											<span class="qt-play qt-link-sec qtmusicplayer-play-btn"
											data-qtmplayer-cover="<?php echo get_the_post_thumbnail_url(); ?>"
											data-qtmplayer-file="<?php echo esc_url($resource_url); ?>"
											data-qtmplayer-title="<?php echo esc_js(esc_attr( get_the_title() ) ); ?>"
											data-qtmplayer-artist="<?php echo esc_js(esc_attr( get_post_meta( get_the_id(), '_podcast_artist', true ) )); ?>"
											data-qtmplayer-album="<?php echo esc_js(esc_attr( get_the_title() )); ?>"
											data-qtmplayer-link="<?php the_permalink(); ?>"
											data-qtmplayer-buylink="<?php echo esc_attr( $link ); ?>"
											data-qtmplayer-icon="<?php echo esc_attr( $icon ); ?>"
											data-qtmplayer-price="<?php echo esc_attr( $price ); ?>" 
											><i class='material-icons'>play_circle_filled</i></span>
											<p>
												<span class="qt-tit"><?php the_title(); ?></span><br>
												<span class="qt-art">
													<?php echo esc_html( get_post_meta( get_the_id(), '_podcast_artist', true )); ?>
												</span>
											</p>

											<?php
											if($link !== ''){ 
												/**
												 *
												 * WooCommerce update:
												 *
												 */
												$buylink = $link;
												if(is_numeric($buylink)) {
													$prodid = $buylink;
													$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
													?>
													<a href="<?php echo esc_attr($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-cart product_type_simple add_to_cart_button ajax_add_to_cart">
													<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
													</a>
													<?php 
												} else {
													?>
													<a href="<?php echo esc_attr($buylink); ?>" class="qt-cart" target="_blank">
													<?php echo ($price !== '')? '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'.esc_html($price).'</span>' : '<i class="material-icons">'.esc_html($icon).'</i>'; ?>
													</a>
													<?php
												}
											} 
											?>
											
										</li>
									</ul>
									<?php 
									} else {
										?><div class="qt-embeddedplayer"><?php
										echo do_shortcode('[audio src="'.esc_url($resource_url).'"]');
										?></div><?php
									}
								 } else {
								 	?>
								 	<div class="qt-embeddedplayer">
			                        	<div data-fixedheight="205" data-autoembed="<?php echo esc_url( $resource_url ); ?>"><?php esc_html_e("Loading player", "kentha"); ?></div>
			                        </div>
			                        <?php  
			                    }
			                }
			                /**
			                 * Get podcast from playlist shortcode
			                 */
			                

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
											
												<ul class="qt-playlist qt-the-content qt-paper qt-card">
													<li class="qtmusicplayer-trackitem">
														<span class="qt-play qt-link-sec qtmusicplayer-play-btn"
														data-qtmplayer-cover="<?php 	echo get_the_post_thumbnail_url(); ?>"
														data-qtmplayer-file="<?php echo esc_url($file); ?>"
														data-qtmplayer-title="<?php echo esc_attr($tracktitle); ?>"
														data-qtmplayer-artist="<?php echo esc_attr($artist); ?>"
														data-qtmplayer-album="<?php echo esc_attr(get_the_title()); ?>"
														data-qtmplayer-link="<?php echo esc_url($link); ?>"
														data-qtmplayer-buylink="<?php echo esc_attr( $buylink_std); ?>"
														data-qtmplayer-icon="insert_link"
														><i class='material-icons'>play_circle_filled</i></span>
														<p>
															<span class="qt-tit"><?php echo esc_attr($tracktitle); ?></span><br>
															<span class="qt-art">
																<?php echo esc_attr($artist); ?>
															</span>
														</p>
														<?php if($buyurl){ ?>
															<a href="<?php echo esc_url($track['releasetrack_buyurl']); ?>" class="qt-cart" target="_blank"><i class="material-icons"><?php echo esc_html($icon); ?></i></a>
														<?php } ?>
													</li>
												</ul>


												<?php 
								      		}
								      	}
								      	$active = '';
								    }	   
								}
								echo  ob_get_clean();
								
							}
							?>
						</div>
					</div>
				</div>
			</header>
			<div class="row">
				<div class="col s12 m8 l8">
					<?php
					$tracklist = get_post_meta($post->ID, 'podcast_tracklist', true);
					if($tracklist[0]['title'] !== ''){
					?>
					<ul class="tabs qt-content-primary-dark qt-small">
						<li class="tab col s3">
							<a href="#qt-content"><i class="material-icons">format_align_left</i> <span class="hide-on-small-only"><?php esc_html_e("About", 'kentha'); ?></span></a>
						</li>
						<li class="tab col s3">
							<a href="#qt-tracklist"><i class="material-icons">playlist_play</i> <span class="hide-on-small-only"><?php esc_html_e("Tracklist", 'kentha'); ?></span></a>
						</li>
					</ul>
					<?php } ?>
					<div class="qt-paper qt-card ">
						<div class="qt-paddedcontent">
							<div id="qt-content">
								<div class="qt-the-content">
									<?php the_content(); ?>
								</div>
							</div>
							<?php  
							$tracklist = get_post_meta($post->ID, 'podcast_tracklist', true);
							if($tracklist[0]['title'] !== ''){
							?>
							<div id="qt-tracklist">
								<h5 class="qt-caption-small"><?php esc_html_e("Tracklist","kentha"); ?></h5>
								<?php get_template_part('phpincludes/part-tracklist' ); ?>
							</div>
							<?php } ?>
						</div>
					</div>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php get_template_part( 'phpincludes/part-listenon' ); ?>
					<?php get_template_part( 'phpincludes/part-share' ); ?>
					<?php get_sidebar('podcast'); ?>
					<hr class="qt-spacer-s">
				</div>
			</div>
		</article>
		<?php get_template_part( 'phpincludes/part-related' ); ?>
		<hr class="qt-spacer-m">
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();