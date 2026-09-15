<?php
/*
Package: Kentha
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-release qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<div class="row">
						<div class="col s12 valign-wrapper">
							<div class="col s12 m4 l4">
								<?php if(has_post_thumbnail(  )){ ?>
								<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'full' ); ?>">
									<?php the_post_thumbnail("large" ); ?>
								</a>
								<?php } ?>
							</div>
							<div class="col s12 m8 l8">
								<span class="qt-tags">
									<?php echo get_the_term_list( get_the_id(), 'genre'); ?>
								</span>
								<h1 class="qt-caption"><?php the_title(); ?></h1>
								<span class="qt-item-metas">
									<?php
									$artist_id 	= get_post_meta( get_the_id(), 'releasetrack_artist', true );
									$date 		= get_post_meta( get_the_id(), 'general_release_details_release_date', true );
									$tracks 	= get_post_meta( get_the_id(), 'track_repeatable' );
									$label 		= get_post_meta( get_the_id(), 'general_release_details_label', true );
									$catalog  	= get_post_meta( get_the_id(), 'general_release_details_catalognumber', true );
									if(is_array($artist_id)){
										if(array_key_exists(0, $artist_id)){
											$artist_id = $artist_id[0];
											?>
											<a href="<?php echo get_the_permalink($artist_id); ?>"><?php echo get_the_title($artist_id); ?></a>&nbsp;&mdash;&nbsp;
											<?php
										}
									}
									if($date){
										echo date( "Y", strtotime($date)); 
									}
									if(is_array($tracks)){ 
										$tracks = $tracks[0]; 
										echo ' / '.count($tracks).' '; 
										esc_html_e( 'Tracks ', 'kentha' );  
									}
									if($label){
										echo esc_html(' / '.$label);
									}
									if($catalog){
										echo esc_html(' / '.$catalog);
									}
									?>
								</span>
								<div class="qt-release-actions qt-spacer-s">
									<?php get_template_part( 'phpincludes/part-buylink-release' ); ?>
									<?php  $url =  add_query_arg('qt_json', '1',  get_the_permalink()); ?>
									<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-primary qt-btn-l noajax" data-kenthaplayer-addrelease="<?php echo esc_url($url); ?>" data-playnow="1">
										<i class='material-icons '>play_arrow</i> <?php esc_html_e( 'Play all', 'kentha' ); ?>
									</a>
									<a href="<?php the_permalink(); ?>" class="qt-btn dropdown-button qt-btn-ghost qt-btn-l noajax" data-clickonce="1" data-notificate="#qtadded" data-kenthaplayer-addrelease="<?php echo esc_url($url); ?>">
										<i class="material-icons">playlist_add</i> <?php esc_html_e( 'Add to playlist', 'kentha' ); ?>
									</a>
									<span id="qtadded" class="qt-btn dropdown-button qt-btn-done qt-btn-l">
										<i class='material-icons '>check</i> <?php esc_html_e( 'Added', 'kentha' ); ?>
									</span>
								</div>
							</div>
						</div>
					</div>
				</div>
			</header>
			<div class="row">
				<div class="col s12 m8 l8">
					<div class="qt-the-content qt-paper qt-card">
						<?php 

						/**
						 * Has player plugin?
						 */
						if(kentha_has_player()){ 
							?><div class="qt-playlist-large">
								<ul class="qt-playlist">
								<?php get_template_part( 'phpincludes/part-playlist' ); ?>
								</ul>
							</div>
							<?php 
						} 


						/**
						 * We can't only use the_content because if the player is enabled, the playlist may have been recreated by the plugin
						 * @var [html]
						 */
						$content = $post->post_content;
						// still have text after stripping playlist?
						if($content != ''){
							?>
							<div id="qttext" class="qt-paddedcontent qt-text-shortened">
								<div class="qt-text">
									<div class="qt-the-content">
										<?php
										the_content();
									    ?>
									</div>
								</div>
								<span class="qt-shorten-trigger qt-center">
									<a href="#" data-activates="#qttext" class="qt-link-sec qt-small">
										<span class="qt-more"><?php esc_html_e( 'More', 'kentha' ); ?> <i class="material-icons">keyboard_arrow_down</i></span>
										<span class="qt-less"><?php esc_html_e( 'Less', 'kentha' ); ?> <i class="material-icons">keyboard_arrow_up</i></span>
									</a>
								</span>
							</div>
							<?php  
						}
						?>
					</div>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php get_template_part( 'phpincludes/part-listenon' ); ?>
					<?php get_template_part( 'phpincludes/part-share' ); ?>
					<?php get_sidebar('release'); ?>
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