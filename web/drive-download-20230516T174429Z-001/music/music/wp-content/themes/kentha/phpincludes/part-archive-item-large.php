<?php  
$thumbnail = get_the_post_thumbnail_url(null,'medium');
$post_classes = 'qt-part-archive-item qt-part-archive-item-large qt-card';
if(is_sticky()){
	$post_classes = $post_classes . ' qt-sticky';
}
if(has_post_thumbnail()){
	$post_classes = $post_classes . ' qt-hovertitles';
}
$img_classes = array('class' => 'qt-feat-hor');
if(kentha_vertical_check()){
	$img_classes = array('class' => 'qt-feat-ver');
}
?>
<article <?php post_class($post_classes); ?>>
	<?php if(is_sticky()){ ?>
		<i class='qt-sticky-bookmark material-icons qt-negative'>bookmark</i>
		<span class="qt-sticky-bg qt-content-accent"></span>
	<?php } ?>
	<?php if(has_post_thumbnail()){ ?>
		<a href="<?php the_permalink(); ?>" class="qt-thumbnail">
			<?php the_post_thumbnail('medium',  $img_classes); ?>
		</a>
	<?php } ?>
	<div class="qt-contents qt-paper qt-paddedcontent ">
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
			<?php if(is_sticky()){ ?>
				<h2 class="qt-tit"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
			<?php } else { ?>
				<h3 class="qt-tit"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
			<?php } ?>
			<span class="qt-item-metas"><?php the_author(); ?> | <?php kentha_international_date(); ?></span>
		</header>
		<div class="qt-summary qt-the-content">
			<?php the_excerpt(); ?>
		</div>
		<footer class="qt-spacer-s">
			<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-l qt-btn-secondary"><?php esc_html_e( 'Read more', 'kentha' ) ?> <i class='material-icons'>arrow_forward</i></a>
		</footer>
	</div>
</article>
<hr class="qt-spacer-m">