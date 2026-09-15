<article <?php post_class("qt-part-event-inline qt-part-event-inline__compact"); ?> >
	<div class="row">
		<div class="col s12 m2 l2 qt-d">
			<?php  
			$d_arr = explode( '-', get_post_meta($post->ID, 'eventdate',true) );
			?>
			<h3>
				<?php echo esc_html($d_arr[2]); ?>
				<span class="qt-item-metas"><?php echo date_i18n(  "M Y" , strtotime(get_post_meta($post->ID, 'eventdate',true))); ?></span>
			</h3>
		</div>
		<div class="col s12 m7 l8">
			<h3><a href="<?php the_permalink(); ?>" ><?php the_title(); ?></a>
			<span class="qt-item-metas">
				<?php
				$date = date( get_option( "date_format", "d M Y" ) , strtotime(get_post_meta($post->ID, 'eventdate',true)));
				$location = get_post_meta($post->ID, 'qt_location',true); 
				if($location){
					echo esc_html( $location );
				}
				if($date && $location){ ?> / <?php }
				if($date){
					echo esc_html($date);
				}
				?>
			</span>
			</h3>
		</div>
		<div class="col s12 m1 l1">
			<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-l qt-btn-primary"> <i class='material-icons'>arrow_forward</i></a>
		</div>
	</div>
</article>