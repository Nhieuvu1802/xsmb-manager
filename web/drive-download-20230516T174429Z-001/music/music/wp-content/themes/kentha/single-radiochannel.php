<?php
/*
Package: Kentha
@requires qt-kentharadio
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-artist qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents qt-single-members"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					

					<?php  
					/**
					 * Playable radio stream
					 * 
					 */
					$id = get_the_id();
					$mp3_stream_url = get_post_meta( $id, 'mp3_stream_url', true );
					$subtitle = get_post_meta($post->ID, 'qt_radio_subtitle',true);
					if( $mp3_stream_url ){
						$icon = get_post_meta($id, 'qt_player_icon', true );
						$thumb = get_the_post_thumbnail_url( $id, 'medium' );

						?>
						<ul class="qt-mplayer__header-play">
							<li class="qtmusicplayer-trackitem">
								<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
								data-qtmplayer-type="radio"
								data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" 
								data-qtmplayer-file="<?php echo esc_url( $mp3_stream_url ); ?>" 
								data-qtmplayer-title="<?php echo esc_attr( get_the_title() ); ?>" 
								data-qtmplayer-artist="<?php  echo esc_attr( $subtitle ); ?>" 
								data-qtmplayer-album="<?php echo esc_attr(get_the_title()); ?>" 
								data-qtmplayer-link="<?php the_permalink(); ?>" 
								data-qtmplayer-buylink="" 
								data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" 

								<?php  
								/**
								 * Radio feed reading
								 */
								?>
								data-radiochannel
								data-host="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedHost',true )); ?>"
								data-port="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedPort',true )); ?>"
								data-ssl="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedSSL',true )); ?>"
								data-icecasturl="<?php echo esc_attr(get_post_meta( $id, 'qticecasturl',true )); ?>"
								data-icecastmountpoint="<?php echo esc_attr(get_post_meta( $id, 'qticecastMountpoint',true )); ?>"
								data-radiodotco="<?php echo esc_attr(get_post_meta( $id, 'qtradiodotco',true )); ?>"
								data-airtime="<?php echo esc_attr(get_post_meta( $id, 'qtairtime',true )); ?>"
								data-radionomy="<?php echo esc_attr(get_post_meta( $id, 'qtradionomy',true )); ?>"
								data-textfeed="<?php echo esc_attr(get_post_meta( $id, 'qttextfeed',true )); ?>"
								data-channel="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedChannel',true )); ?>"

								><i class='material-icons'>play_circle_filled</i></span>
							</li>
						</ul>
						<?php
					}
					?>




					<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
					<!-- <h4 class="qt-kentharadio-feed"><span class="qt-kentharadio-feed__author"></span> - <span class="qt-kentharadio-feed__title"></span></h4> -->
					<?php  
					
					if($subtitle){ ?>
						<span class="qt-item-metas"><?php echo esc_html($subtitle);	?></span>
					<?php } ?>
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
					<div class="qt-paddedcontent qt-paper">
						<div class="qt-the-content">
							<?php 
							the_content(); 
							?>
							<hr class="qt-spacer-s">
							<?php
							if(shortcode_exists( 'qt-chart' )){
								echo do_shortcode('[qt-chart id="'.($post->ID).'"]' );
							}
							?>
						</div>
					</div>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php			
					get_template_part( 'phpincludes/part-share' ); 
					get_sidebar(); 
					?>
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