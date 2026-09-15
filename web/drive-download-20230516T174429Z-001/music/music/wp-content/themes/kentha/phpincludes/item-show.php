<?php
/*
Package: kentha + qt-kentharadio
*/
?>
<a class="qt-kentharadio-show" href="<?php echo get_the_permalink( $show_id ); ?>">
	<?php 
	if (has_post_thumbnail($show_id)){ 
       	echo get_the_post_thumbnail( $show_id, 'medium' );
    }
	?>
	<div class="qt-kentharadio-show__header">
		<div class="qt-kentharadio-vc">
			<div class="qt-kentharadio-vi">
				<h6 class="qt-item-metas qt-kentharadio-nmt">
				<?php 
				$tags = get_the_terms( $show_id, 'qt-kentharadio-showgenre');
				if(is_array($tags)){
					echo $tags[0]->name;
				}
				?>
				</h6>
				<h4 class="qt-kentharadio-nmt"><?php echo get_the_title($show_id); ?></h4>
			</div>
		</div>
	</div>
</a>
