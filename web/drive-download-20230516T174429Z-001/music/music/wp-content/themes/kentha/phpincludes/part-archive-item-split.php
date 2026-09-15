<article <?php post_class('qt-part-archive-item qt-grid-item qt-grid-item-split qt-paper'); ?>>
	<div class="row">
		<?php if(has_post_thumbnail()){ ?>
			<div class="col s12 m6 l6">
				<a href="<?php the_permalink(); ?>" class="qt-fi">
					<?php the_post_thumbnail('medium'); ?>
				</a>
			</div>
		<?php } ?>
		<div class="col qt-cont s12 <?php if(has_post_thumbnail()){ ?> m6 l6 <?php } else { ?> m12 l12 <?php } ?>">
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
			
			<footer class="qt-item-metas">
				<a href="<?php the_permalink(); ?>"><?php esc_html_e( 'Read more', 'kentha' ) ?> <i class='material-icons'>arrow_forward</i></a>
			</footer>
		</div>
	</div>
</article>