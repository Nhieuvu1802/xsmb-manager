<!-- ARCHIVE ITEM -->
<?php  
$thumbnail = get_the_post_thumbnail_url(null,'medium');
$post_classes = 'qt-part-archive-item qt-part-archive-item-large';
if(is_sticky()){
	$post_classes = $post_classes.' qt-sticky';
}
/**
 * [$img_class classes for featured image]
 * @var array
 */
$img_class = array('class' => 'qt-feat-hor');
if(kentha_vertical_check()){
	$img_class = array('class' => 'qt-feat-ver');
}
?>
<article <?php post_class($post_classes); ?>>
	<?php if(has_post_thumbnail()){ ?>
		<a href="<?php the_permalink(); ?>" class="qt-thumbnail">
			<?php the_post_thumbnail('medium',  $img_class); ?>
		</a>
	<?php } ?>
	<div class="qt-paper qt-paddedcontent qt-card">
		<header class="qt-headings">
			<span class="qt-tags">
				<?php
				$category = get_the_category(); 
				$limit = 1;
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
		<footer class="qt-item-metas qt-spacer-s">
			<a href="<?php the_permalink(); ?>"><?php esc_html_e( 'Read more', 'kentha' ) ?> <i class='material-icons'>arrow_forward</i></a>
		</footer>
	</div>
	<hr class="qt-spacer-m">
</article>
<!-- ARCHIVE ITEM END -->