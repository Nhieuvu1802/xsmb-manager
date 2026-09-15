<?php  
$post_classes = 'qt-part-archive-item qt-part-archive-item__chart qt-post qt-carditem qt-card qt-paper qt-interactivecard qt-scrollbarstyle';
if(is_sticky()){
	$post_classes = $post_classes . ' qt-sticky';
}
?>
<article <?php post_class($post_classes); ?>>
	<div class="qt-iteminner">
		<div class="qt-imagelink" data-activatecard>
			<span class="qt-header-bg" data-bgimage="<?php echo get_the_post_thumbnail_url(null,'medium'); ?>" data-parallax="0" data-attachment="local">
			</span>
		</div>
		<header class="qt-header">
			<div class="qt-headings" data-activatecard>
				<h3 class="qt-title"><?php  echo kentha_shorten(get_the_title(), 64, true);  ?></h3>
				<span class="qt-details qt-item-metas">
					<?php kentha_international_date(); ?>
				</span>
				<span class="qt-capseparator"></span>
				<i class="material-icons qt-close">close</i>
			</div>

			<div class="qt-actionbtn fixed-action-btn horizontal click-to-toggle">
				<a href="<?php the_permalink(); ?>" class="btn-floating btn-large qt-btn-primary">
					<i class="material-icons">add</i>
				</a>
			</div>
			<i class="material-icons qt-ho" data-activatecard>keyboard_arrow_down</i>
		</header>
		<span data-color="<?php echo get_theme_mod( 'kentha_color_secondary', '#ff0d51' ); ?>" class="qt-animation"></span>
		<div class="qt-content">
			<div class="qt-summary">
				<?php  
				$events= get_post_meta(get_the_ID(), 'track_repeatable', true);   
				$total = count($events);
				$pos = 1;
				$counter = 0;
				if(is_array($events)){
					foreach($events as $e){ 
						$counter = $counter +1;
						$pos = sprintf("%02d", $pos);
						?>
						<div class="qt-track-mini">
							<span class="qt-pos"><?php echo esc_html($pos); ?></span>
							<?php if(array_key_exists('releasetrack_track_title', $e)) { ?>
							<h5 class="qt-ellipsis qt-t"><?php echo esc_attr($e['releasetrack_track_title']); ?></h5>
							<?php } ?>
							<?php if(array_key_exists('releasetrack_artist_name', $e)) { ?>
							<small><?php echo esc_attr($e['releasetrack_artist_name']); ?></small>
							<?php } ?>
						</div>
						<?php
						$pos = $pos+1;
					}
				}
				?>
			</div>
			<footer class="qt-item-metas">
				<a href="<?php the_permalink(); ?>"><?php esc_html_e('Listen', 'kentha'); ?> <i class='material-icons'>arrow_forward</i></a>
			</footer>
		</div>
	</div>
</article>