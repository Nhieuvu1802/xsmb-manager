<article <?php post_class("qt-part-archive-item qt-carditem qt-artist qt-card qt-paper qt-interactivecard qt-scrollbarstyle"); ?>>
	<div class="qt-iteminner">
		<div class="qt-imagelink" data-activatecard >
			<span class="qt-header-bg" data-bgimage="<?php echo get_the_post_thumbnail_url(null,'medium'); ?>" data-parallax="0" data-attachment="local">
			</span>
		</div>
		<header class="qt-header">
			<div class="qt-headings" data-activatecard>
				<h3 class="qt-title qt-ellipsis qt-t"><?php the_title(); ?></h3>
				<span class="qt-details qt-item-metas">
					<?php
					$nat = get_post_meta($post->ID, '_artist_nationality',true);
					$res = get_post_meta($post->ID, '_artist_resident',true); 
					if($res){
						echo esc_html( $res );
					}
					if($nat && $res){ ?>&nbsp;<?php }
					if($nat){
						echo esc_html( '['.$nat.']' );
					}
					?>
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
		<span class="qt-animation" data-color="<?php echo get_theme_mod( 'kentha_color_secondary', '#ff0d51' ); ?>" ></span>
		<div class="qt-content">
			<div class="qt-summary">
				<?php the_excerpt(); ?>
			</div>
			<footer class="qt-item-metas">
				<a href="<?php the_permalink(); ?>"><?php esc_html_e('Read more', 'kentha'); ?> <i class='material-icons'>arrow_forward</i></a>
			</footer>
		</div>
	</div>
</article>