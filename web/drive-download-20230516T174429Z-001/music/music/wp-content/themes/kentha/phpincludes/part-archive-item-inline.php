<?php
/*
Package: Kentha
*/
?>
<div class="qt-part-archive-item qt-item-inline">
	<a class="qt-inlineimg" href="<?php the_permalink(); ?>">
		<img width="150" height="150" src="<?php echo get_the_post_thumbnail_url(null, 'thumbnail'); ?>" class="attachment-thumbnail size-thumbnail wp-post-image" alt="Thumbnail">
	</a>
	<span class="qt-details"><?php kentha_international_date(); ?></span>
	<h5 class="qt-tit qt-ellipsis-2 qt-t">
		<a class="" href="<?php the_permalink(); ?>">
			<?php the_title(); ?>
		</a>
	</h5>
</div>
