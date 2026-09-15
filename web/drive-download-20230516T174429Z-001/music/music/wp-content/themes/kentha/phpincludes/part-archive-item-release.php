<article <?php post_class("qt-part-archive-item qt-carditem qt-release qt-card qt-paper qt-interactivecard qt-scrollbarstyle"); ?>>
	<div class="qt-iteminner">
		<div class="qt-imagelink" data-activatecard >
			<span class="qt-header-bg" data-bgimage="<?php echo get_the_post_thumbnail_url(null,'kentha-squared'); ?>" data-parallax="0" data-attachment="local">
			</span>
		</div>
		<header class="qt-header">
			<div class="qt-headings" data-activatecard>
				<h3 class="qt-title qt-ellipsis qt-t"><?php the_title(); ?></h3>
				<?php  
				$artist_id = get_post_meta( get_the_id(), 'releasetrack_artist', true );
				if(is_array($artist_id)){
					if(array_key_exists(0, $artist_id)) {
						$artist_id = $artist_id[0];
						?>
						<span class="qt-details qt-item-metas" data-activatecard>
							<?php if($artist_id){ echo get_the_title($artist_id); } ?>
						</span>
						<?php
					}
				}
				?>
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
		<span class="qt-animation" data-color="<?php echo get_theme_mod( 'kentha_color_secondary', '#ff0d51' ); ?>" ></span>
		<div class="qt-content">
			<div class="qt-summary ">
				<ul class="qt-playlist">
				<?php get_template_part( 'phpincludes/part-playlist' ); ?>
				</ul>
			</div>
		</div>
	</div>
</article>