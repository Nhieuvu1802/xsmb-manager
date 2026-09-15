<?php
/*
Package: Kentha
*/

get_header();
$enable_podcasts_in_single_artist = true;
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-artist qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<span class="qt-tags">
						<?php  echo get_the_term_list( get_the_id(), 'artistgenre'); ?>
					</span>
					<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
					<span class="qt-item-metas"><?php
						/*
						*
						*   Artist nationality
						*/
						$nat = get_post_meta($post->ID, '_artist_nationality',true);
						$res = get_post_meta($post->ID, '_artist_resident',true); 
						if($res){
							echo esc_html( $res );
						}
						if($nat && $res){ ?>&nbsp;<?php }
						if($nat){
							echo esc_html( '['.$nat.']' );
						}
						?></span>
					<hr class="qt-capseparator">
				</div>
			</header>
			<div class="row">
				<div class="col s12 m8 l8">
					<?php if(has_post_thumbnail(  )){ ?>
					<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'large' ); ?>">
						<?php the_post_thumbnail("large" ); ?>
					</a>
					<?php } ?>
					<div class="qt-paper qt-card">
						<?php  
						$artist_releases = kentha_get_artist_releases( get_the_title() );


						/**
						 * @since 2.0.3
						 * Extract the products having the artist field with same ID as this current artist
						 */
						$artist_products = kentha_get_artist_products( $post->ID );


						$artist_podcasts = false;
						if( true == $enable_podcasts_in_single_artist ){
							$artist_podcasts = kentha_get_artist_podcasts( get_the_title() );
						}
						$artist_events		= kentha_get_artist_events($post->ID);
						$artist_email = get_post_meta($post->ID, '_artist_booking_contact_email', true);
						$artist_v1 = get_post_meta($post->ID, '_artist_youtubevideo1', true);
						$artist_v2 = get_post_meta($post->ID, '_artist_youtubevideo2', true);
						$artist_v3 = get_post_meta($post->ID, '_artist_youtubevideo3', true);
						$artist_v4 = get_post_meta($post->ID, '_artist_youtubevideo4', true);
						$artist_v5 = get_post_meta($post->ID, '_artist_youtubevideo5', true);
						$artist_v6 = get_post_meta($post->ID, '_artist_youtubevideo6', true);
						$artist_soundcloud = get_post_meta($post->ID, '_artist_soundcloud', true);
						$custom_tab_title = get_post_meta($post->ID,'custom_tab_title', true);
						$custom_tab_content = get_post_meta($post->ID,'custom_tab_content', true);
						?>
						<div class="row">
							<div class="col s12">
								<ul class="tabs qt-tabs qt-content-primary-dark qt-small">

									<?php if($artist_products){ ?>
									<li class="tab col s3">
										<a href="#qt-tracks"><i class="material-icons">album</i> <span class="hide-on-small-only"><?php esc_html_e( 'Tracks', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>


									<li id="qt-bio-btn" class="tab col s3">
										<a href="#qt-bio"><i class="material-icons">person_outline</i> <span class="hide-on-small-only"><?php esc_html_e( 'Bio', 'kentha' ); ?></span></a>
									</li>
									<?php if($artist_releases){ ?>
									<li class="tab col s3">
										<a href="#qt-music"><i class="material-icons">album</i> <span class="hide-on-small-only"><?php esc_html_e( 'Album', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>
									
									<?php if($artist_podcasts){ ?>
									<li class="tab col s3">
										<a href="#qt-podcasts"><i class="material-icons">play_arrow</i> <span class="hide-on-small-only"><?php esc_html_e( 'Podcast', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>
									<?php if($artist_v1){ ?>
									<li class="tab col s3">
										<a href="#qt-videos"><i class="material-icons">videocam</i> <span class="hide-on-small-only"><?php esc_html_e( 'Videos', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>
									<?php if($artist_soundcloud){ ?>
									<li class="tab col s3">
										<a href="#qt-soundcloud"><i class="material-icons">play_arrow</i> <span class="hide-on-small-only"><?php esc_html_e( 'Soundcloud', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>
									<?php if($custom_tab_title){ ?>
									<li class="tab col s3">
										<a href="#qt-customtab"><i class="material-icons">control_point</i> <span class="hide-on-small-only"><?php echo esc_html( $custom_tab_title ); ?></span></a>
									</li>
									<?php } ?>
									<?php if($artist_events){ ?>
									<li class="tab col s3">
										<a href="#qt-events"><i class="material-icons">event</i> <span class="hide-on-small-only"><?php esc_html_e( 'Events', 'kentha' ); ?></span></a>
									</li>
									<?php } ?>
									
								</ul>
							</div>
							<div id="qt-bio" class="col s12">
								<div class="qt-paddedcontent">
									<h3 class="qt-caption-small"><?php esc_html_e( 'Biography', 'kentha' ); ?></h3>
									<hr class="qt-spacer-s">
									<div id="qttext" class="<?php if(wp_is_mobile()){ ?>qt-text-shortened<?php } ?> qt-biography">
										<div class="qt-text qt-tall">
											<div class="qt-the-content">
												<?php the_content(); ?>
											</div>
										</div>
										<?php if(wp_is_mobile()){ ?>
										<span class="qt-shorten-trigger qt-center">
											<a href="#" data-activates="#qttext" class="qt-link-sec qt-small">
												<span class="qt-more"><?php esc_html_e( 'More', 'kentha' ); ?> <i class="material-icons">keyboard_arrow_down</i></span>
												<span class="qt-less"><?php esc_html_e( 'Less', 'kentha' ); ?> <i class="material-icons">keyboard_arrow_up</i></span>
											</a>
										</span>
										<?php } ?>
									</div>
								</div>
							</div>
							<?php if($artist_releases){ ?>
								<div id="qt-music" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Album', 'kentha' ); ?></h3>
										<hr class="qt-spacer-m">
										<div class="row">
											<?php  echo kentha_sanitize_content($artist_releases); // sanitized on generation ?>
										</div>
									</div>
								</div>
							<?php } ?>
							<?php if($artist_products){ ?>
								<div id="qt-tracks" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Tracks', 'kentha' ); ?></h3>
									</div>
									<?php  echo wp_kses_post($artist_products); // sanitized on generation ?>
								</div>
							<?php } ?>
							<?php if($artist_podcasts){ ?>
								<div id="qt-podcasts" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Podcast', 'kentha' ); ?></h3>
										<hr class="qt-spacer-m">
										<div class="row">
											<?php  echo kentha_sanitize_content($artist_podcasts); // sanitized on generation ?>
										</div>
									</div>
								</div>
							<?php } ?>
							<?php if($artist_events){ ?>
								<div id="qt-events" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Events', 'kentha' ); ?></h3>
										<?php  echo kentha_sanitize_content($artist_events); // sanitized on generation ?>
									</div>
								</div>
							<?php } ?>
							<?php if($artist_v1){ ?>
								<div id="qt-videos" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Videos', 'kentha' ); ?></h3>
										<hr class="qt-spacer-m">
										<div data-autoembed="<?php echo esc_url($artist_v1); ?>"></div>
										<?php if($artist_v2){ ?>
											<div data-autoembed="<?php echo esc_url($artist_v2); ?>"></div>
										<?php } ?>
											<?php if($artist_v3){ ?>
										<div data-autoembed="<?php echo esc_url($artist_v3); ?>"></div>
										<?php } ?>
										<?php if($artist_v4){ ?>
											<div data-autoembed="<?php echo esc_url($artist_v4); ?>"></div>
										<?php } ?>
										<?php if($artist_v5){ ?>
											<div data-autoembed="<?php echo esc_url($artist_v5); ?>"></div>
										<?php } ?>
										<?php if($artist_v6){ ?>
											<div data-autoembed="<?php echo esc_url($artist_v6); ?>"></div>
										<?php } ?>
									</div>
								</div>
							<?php } ?>

							<?php if($artist_soundcloud){ ?>
								<div id="qt-soundcloud" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php esc_html_e( 'Soundcloud', 'kentha' ); ?></h3>
										<hr class="qt-spacer-s">
										<div data-fixedheight="500" data-autoembed="<?php echo esc_url($artist_soundcloud); ?>"></div>
									</div>
								</div>
							<?php } ?>

							<?php if($custom_tab_title){ ?>
								<div id="qt-customtab" class="col s12">
									<div class="qt-paddedcontent">
										<h3 class="qt-caption-small"><?php echo esc_html( $custom_tab_title ); ?></h3>
										<hr class="qt-spacer-s">
										<div class="qt-the-content">
											<?php echo apply_filters('the_content', $custom_tab_content); ?>
										</div>
									</div>
								</div>
							<?php } ?>

						</div>

					</div>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php  
					$artist_social = '';
					$links_array=array(
						'_artist_website' 		=> 'qt-socicon-www',
						'_artist_facebook'		=>'qt-socicon-facebook',
						'_artist_beatport'		=>'qt-socicon-beatport',
						'_artist_hearthis'		=>'qt-socicon-hearthis',
						'_artist_soundcloud'	=>'qt-socicon-soundcloud',
						'_artist_mixcloud'		=>'qt-socicon-mixcloud',
						'_artist_myspace'		=>'qt-socicon-myspace',
						'_artist_instagram'		=>'qt-socicon-instagram',
						'_artist_residentadv'	=>'qt-socicon-residentadvisor',
						'_artist_twitter'		=>'qt-socicon-twitter',
						// new social icons 2017: 
						'_artist_hearthis'		=>'qt-socicon-hearthis',
						'_artist_instagram'		=>'qt-socicon-instagram',
						'_artist_snapchat'		=>'qt-socicon-snapchat',
						'_artist_whatpeopleplay'=>'qt-socicon-whatpeopleplay',
						'_artist_lastfm'		=>'qt-socicon-lastfm',
						'_artist_vimeo'			=>'qt-socicon-vimeo',
						'_artist_pinterest'		=>'qt-socicon-pinterest',
						'_artist_googleplus'	=>'qt-socicon-googleplus',
						'_artist_trackitdown'	=>'qt-socicon-trackitdown',
						'_artist_android'		=>'qt-socicon-android',
						'_artist_itunes'		=>'qt-socicon-itunes',
						'_artist_amazon'		=>'qt-socicon-amazon',
						'_artist_djtunes'		=>'qt-socicon-djtunes',
						'_artist_reddit'		=>'qt-socicon-reddit',
						'_artist_beatmusic'		=>'qt-socicon-beatmusic',
						'_artist_vk'			=>'qt-socicon-vk',
						'_artist_reverbnation'	=>'qt-socicon-reverbnation',
						'_artist_kuvo'	=>'qt-socicon-kuvo',
					);		
					foreach ($links_array as $l => $r){
						$valore = get_post_meta(get_the_id(),  $l, true );
						if($valore!=''){
							$artist_social .= '<li><a target="_blank" rel="external nofollow" href="'.esc_url($valore).'" class="qw-disableembedding qt-artist-socialicon qt-btn qt-btn-secondary" ><i class="'.esc_attr($r).'"></i></a>';
						}
					}
					if ($artist_social){
						?>
						<div class="qt-paddedcontent qt-card qt-paper qt-booking-contacts">
							<h4 class="qt-caption-small"><?php esc_html_e( 'Social profiles', 'kentha' ); ?></h4>
							<ul class="qt-social-list">
							<?php echo wp_kses_post( $artist_social); ?>
							</ul>
						</div>
						<hr class="qt-spacer-s">
						<?php 
					} 
					
					/**
					 * 
					 * Agency contacts
					 * 
					 */
					$agency = get_post_meta($post->ID,'_artist_booking_contact_name', true);
					$phone = get_post_meta($post->ID,'_artist_booking_contact_phone', true);
					$email = get_post_meta($post->ID,'_artist_booking_contact_email', true);
					$site = get_post_meta($post->ID,'_artist_website', true);
					if($agency || $phone || $phone || $email || $site){ 
						?>
						<div class="qt-paddedcontent qt-card qt-paper qt-booking-contacts">
							<h4 class="qt-caption-small"><?php esc_html_e( 'Booking contacts', 'kentha' ); ?></h4>
							<?php
							if($agency){
							?>
								<p class="qt-fontsize-h6 qt-capfont"><strong><?php esc_html_e( 'Agency', 'kentha' ); ?>: </strong><?php echo esc_html( $agency ); ?></p>
							<?php 
							}
							if($phone){ 
							?>
								<p class="qt-fontsize-h6 qt-capfont"><strong><?php esc_html_e( 'Phone', 'kentha' ); ?>: </strong><?php echo esc_html( $phone ); ?></p>
							<?php 
							}
							if($site){ 
							?>
								<p class="qt-fontsize-h6 qt-capfont"><strong><?php esc_html_e( 'Website', 'kentha' ); ?>: </strong><a href="<?php echo esc_url( $site ); ?>" rel="nofollow" target="_blank"><?php echo esc_html( $site ); ?></a></p>
							<?php 
							}
							if($email){ 
							?>
								<p class="qt-fontsize-h6 qt-capfont"><strong><?php esc_html_e( 'Email', 'kentha' ); ?>: </strong><?php echo esc_html( $email ); ?></p>
							<?php 
							}
							?>
						</div>
						<hr class="qt-spacer-s">
						<?php 
					}
					/**
					 * Booking form
					 */
					if(get_post_meta( $post->ID, 'qt_contacts_recipient', true )){ ?>
						<div class="qt-paddedcontent qt-card qt-paper qt-booking-sideform">
							<h4 class="qt-caption-small"><?php esc_html_e( 'Request availability', 'kentha' ); ?></h4>
							<?php get_template_part('phpincludes/part-contactform' ); ?>
						</div>
						<hr class="qt-spacer-s">
						<?php 
					}
					get_template_part( 'phpincludes/part-listenon-artist' );
					get_template_part( 'phpincludes/part-share' ); 
					?>
					<?php get_sidebar('artist'); ?>
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