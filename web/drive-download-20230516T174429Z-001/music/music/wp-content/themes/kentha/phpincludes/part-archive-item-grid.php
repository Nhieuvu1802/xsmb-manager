<article <?php post_class('qt-part-archive-item qt-grid-item qt-part-archive-item-grid qt-paper'); ?>>
		<?php if(has_post_thumbnail()){ ?>
			<a href="<?php the_permalink(); ?>">
				<?php the_post_thumbnail('medium'); ?>
			</a>
		<?php } ?>
		<header class="qt-headings">
			<span class="qt-tags">
				<?php
				$category = get_the_category(); 
				$limit = 3;
				foreach($category as $i => $cat){
					if($i > $limit){
						continue;
					}
					echo '<a href="'.get_category_link($cat->term_id ).'">'.$cat->cat_name.'</a>';  
				}
				?>
			</span>
			<h4><a href="<?php the_permalink(); ?>" ><?php the_title(); ?></a></h4>
			<span class="qt-item-metas"><?php the_author(); ?> | <?php kentha_international_date(); ?></span>
		</header>
		<div class="qt-summary">
			<?php the_excerpt(); ?>
		</div>
		<footer class="qt-item-metas">
			<a href="<?php the_permalink(); ?>"><?php esc_html_e( 'Read more', 'kentha' ) ?> <i class='material-icons'>arrow_forward</i></a>
		</footer>
</article>