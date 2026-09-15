<article <?php post_class("qt-part-archive-item qt-release-featured qt-card qt-paper qt-scrollbarstyle"); ?>>
	<div class="row">
		<div class="col s12 m4">
			<?php the_post_thumbnail( 'kentha-squared' ); ?>
		</div>
		<div class="col s12 m8 l4">
			<div class="qt-scrl">
				<h4><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h4>
				<?php  
				$artist_id = get_post_meta( get_the_id(), 'releasetrack_artist', true );
				if(is_array($artist_id)){
					if(array_key_exists(0, $artist_id)) {
						$artist_id = $artist_id[0];
						?>
						<span class="qt-details qt-item-metas">
							<?php if($artist_id){ echo get_the_title($artist_id); } ?>
						</span>
						<?php
					}
				}
				?>
				<span class="qt-capseparator"></span>
				<?php 
				$content = get_the_excerpt(); 
				if ( has_shortcode( $content, 'playlist' ) && kentha_has_player()) { 
					$pattern = get_shortcode_regex(); 
					preg_match('/'.$pattern.'/s', $content, $matches);
					if ( isset($matches[2]) && is_array($matches) && $matches[2] == 'playlist') {
						$content = str_replace( $matches['0'], '', $content );
					}
				}
				if($content != ''){
					$content = apply_filters( 'the_content', $content );
					$content = str_replace( ']]>', ']]&gt;', $content );
					echo kentha_shorten($content, 280); 
				}
				?>
				<hr class="qt-spacer-s">
				<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-secondary qt-btn-l"><?php esc_html_e( 'More info', 'kentha' ); ?></a>
			</div>			
		</div>
		<div class="col s12 m12 l4">
			<div class="qt-plscr">
				<ul class="qt-playlist">
				<?php get_template_part( 'phpincludes/part-playlist' ); ?>
				</ul>
			</div>
		</div>
		
	</div>
</article>