<?php
/*
Package: Kentha
*/
get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?> data-start>
			<?php
			/**
			 * Events data
			 */
			$e = array(
			  'id' =>  $post->ID,
			  'date' =>  get_post_meta($post->ID,'eventdate',true),
			  'time' =>  get_post_meta($post->ID,'eventtime',true),
			  'location' =>  get_post_meta($post->ID, 'qt_location',true),
			  'street' =>  get_post_meta($post->ID, 'qt_address',true),
			  'city' =>  get_post_meta($post->ID, 'qt_city',true),
			  'country' =>  get_post_meta($post->ID, 'qt_country',true),
			  'permalink' =>  get_permalink($post->ID),
			  'title' =>  $post->post_title,
			  'phone' => get_post_meta($id, 'qt_phone',true),
			  'website' => get_post_meta($id, 'qt_link',true),
			  'facebooklink' => get_post_meta($id, 'eventfacebooklink',true),
			  'coord' => get_post_meta($id,  'qt_coord',true),
			  'email' => get_post_meta($id,  'qt_email',true)
			);
			$event_artists_lineup = get_post_meta( get_the_ID(), 'event_lineup', $single = true );
			
			$has_lineup = false;
			if(is_array($event_artists_lineup)){
				if(count($event_artists_lineup) > 0){
					$artists_array = '';
					// $has_lineup = true;

					foreach( $event_artists_lineup as $artist){
						if(array_key_exists('artist', $artist) ){
							if($artist['artist'][0] ){
								$has_lineup = true;
							}
						}
						if(array_key_exists('manual_artist', $artist) ){
							if( $artist['manual_artist'] == '1'){
								$has_lineup = true;
							}
						}
					}
					
				}
			}
			?>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<span class="qt-tags">
						<?php echo get_the_term_list( get_the_id(), 'eventtype'); ?>
					</span>
					<h1 class="qt-caption qt-caption-event"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
					<span class="qt-item-metas">
						<?php  
						if($e['location']){ echo esc_html( $e['location'] ).'&nbsp;/&nbsp;'; }
						if($e['city']){ echo esc_html( $e['city'] ); }
						if($e['country']){ ?>&nbsp;[<?php echo esc_html( $e['country'] );?>]<?php  }
						if($e['date']){ echo ' / '.date_i18n( get_option( "date_format", "d M Y" ) , strtotime($e['date'])).' '.esc_html($e['time']); }
						?>
					</span>

					<?php  
					$evdate = get_post_meta($post->ID, 'eventdate',true);
					$now =  current_time("Y-m-d");
					if( $evdate && $evdate !== '' && $evdate > $now){
						?>
						<h3 class="qt-countdown" data-date="<?php echo esc_attr(get_post_meta($post->ID, 'eventdate',true)); ?>" data-time="<?php echo esc_attr(get_post_meta($post->ID, 'eventtime',true)); ?>" data-days="<?php esc_attr_e('D','kentha'); ?>" data-hours="<?php esc_attr_e('H','kentha'); ?>" data-minutes="<?php esc_attr_e('M','kentha'); ?>" data-seconds="<?php esc_attr_e('S','kentha'); ?>"><?php esc_html_e("Coming Soon", "kentha"); ?></h3>
						<div class="qt-event-actions">
							<?php get_template_part( 'phpincludes/part-buylink' ); ?>
						</div>
						<?php  
					}
					?>
				</div>
			</header>
			<div class="row">
				<div class="col s12 m8 l8">
					<?php
					/**
					 * Tabs
					 */
					?>
					<ul class="tabs qt-content-primary-dark qt-small">
						<?php if($e['street'] || $e['city'] || $e['country'] || $e['facebooklink'] || $e['email'] || $e['phone']){  ?>
							<li class="tab col s3">
								<a href="#qt-details"><i class="material-icons">date_range</i> <span class="hide-on-small-only"><?php esc_html_e("Details", 'kentha'); ?></span></a>
							</li>
						<?php } ?>
						<?php if($has_lineup){  ?>
							<li class="tab col s3">
								<a href="#qt-lineup"><i class="material-icons">queue_music</i> <span class="hide-on-small-only"><?php esc_html_e("Lineup", 'kentha'); ?></span></a>
							</li>
						<?php } ?>
						<?php if(get_the_content()){ ?>
							<li class="tab col s3">
								<a href="#qt-description"><i class="material-icons">format_align_left</i> <span class="hide-on-small-only"><?php esc_html_e("The event", 'kentha'); ?></span></a>
							</li>
						<?php } ?>
					</ul>

					<?php  

					/**
					 * Tabs contents
					 */
					if($e['street'] || $e['city'] || $e['country'] || $e['facebooklink'] || $e['email'] || $e['phone']){  ?>
						<div id="qt-details" class="qt-the-content qt-paper qt-card qt-paddedcontent">
							<h4 class="qt-caption-small"><?php esc_html_e("Event details", 'kentha'); ?></h4>
							<?php get_template_part('phpincludes/part-eventtable' ); ?>
							<?php if($e['coord']!== '' ){ ?>
								<h4 class="qt-caption-small"><?php esc_html_e("Location", 'kentha'); ?></h4>
								<div class="qt-map-event qt-spacer-s">
									<div class="qt_dynamicmaps" id="map<?php echo esc_attr($post->ID); ?>" data-colors="QT_map_dark" data-coord="<?php echo esc_attr($e['coord']); ?>" data-height="350">
									</div>
								</div>
							<?php } ?>
						</div>
					<?php 
					} 
					/**
					 * Artists lineup
					 */
					if($has_lineup){
						?>
						<div id="qt-lineup" class="qt-the-content qt-paper qt-card qt-paddedcontent">
							<h4 class="qt-caption-small"><?php esc_html_e("Line Up", 'kentha'); ?></h4>
							<div class="qt-lineup-full">
								<?php
								foreach($event_artists_lineup as $item){
									$artist_id =  $item['artist'][0];
									if($artist_id != ''){
										?>
										<a href="<?php echo get_the_permalink($artist_id); ?>" class="qt-lineup-item qt-content-primary-light qt-negative" data-bgimage="<?php echo get_the_post_thumbnail_url( $artist_id, 'large' ); ?>">
											<div class="qt-negative">
												<h4 class="qt-negative"><?php echo get_the_title( $artist_id); ?></h4>
												<h6 class="qt-negative"><?php echo esc_html($item['time']); ?></h6>
											</div>
										</a>
										<?php
									} else {

										if($item['manual_artist']){
											$img = wp_get_attachment_image_src($item['photo'],'medium');
											if($img){
												$photo_url = $img[0];
											}


											?>
											<a href="<?php echo get_the_permalink($artist_id); ?>" class="qt-lineup-item qt-content-primary-light qt-negative" data-bgimage="<?php echo esc_attr($photo_url); ?>">
												<div class="qt-negative">
													<h4 class="qt-negative"><?php echo esc_html($item['name']); ?></h4>
													<h6 class="qt-negative"><?php echo esc_html($item['time']); ?></h6>
												</div>
											</a>
											<?php
										}
									}


								}
								?>
							</div>
						</div>
						<?php
					}  
					/**
					 * Content
					 */
					if(get_the_content()){ 
						?>
						<div id="qt-description" class="qt-the-content qt-paper qt-card qt-paddedcontent">
							<h4 class="qt-caption-small"><?php esc_html_e("The event", 'kentha'); ?></h4>
							<div class="qt-content qt-spacer-s">
								<div class="qt-the-content">
									<?php the_content(); ?>
								</div>
							</div>
						</div>
						<?php 
					}
					?>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php if(has_post_thumbnail(  )){ ?>
					<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'full' ); ?>">
						<?php the_post_thumbnail("medium" ); ?>
					</a>
					<?php } ?>
					<?php get_template_part( 'phpincludes/part-buytickets' ); ?>
					<?php get_template_part( 'phpincludes/part-share' ); ?>
					<?php get_sidebar('event'); ?>
					<hr class="qt-spacer-s">
				</div>

			</div>
		</article>
		<?php get_template_part( 'phpincludes/part-related' ); ?>
		<hr class="qt-spacer-m">
	</div>
	<?php endwhile; ?>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_template_part('footer'); ?>