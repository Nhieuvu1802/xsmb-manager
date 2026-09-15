<article <?php post_class("qt-part-event-inline"); ?> >
	<div class="row">
		<div class="col s12 m2 l1 qt-d">
			<?php  
			$d_arr = explode( '-', get_post_meta($post->ID, 'eventdate',true) );
			?>
			<h3>
				<?php echo esc_html($d_arr[2]); ?>
				<span class="qt-item-metas"><?php echo date_i18n(  "M Y" , strtotime(get_post_meta($post->ID, 'eventdate',true))); ?></span>
			</h3>
		</div>
		<div class="col s12 m7 l9">
			<h3><a href="<?php the_permalink(); ?>" ><?php the_title(); ?></a>
			<span class="qt-item-metas">
				<?php
				$date = date_i18n( get_option( "date_format", "d M Y" ) , strtotime(get_post_meta($post->ID, 'eventdate',true)));
				$location = get_post_meta($post->ID, 'qt_location',true); 
				if($location){
					echo esc_html( $location );
				}

				/**
				 * If you want to display city and country in the list, uncomment the following block
				 */
				/*$city = get_post_meta($post->ID, 'qt_city',true); 
				if($city){
					echo ' '.esc_html( $city ).' ';
				}

				$country = get_post_meta($post->ID, 'qt_country',true); 
				if($city){
					echo ' ('.esc_html( $country ).') ';
				}*/



				if($date && $location){ ?> / <?php }
				if($date){
					echo esc_html($date);
				}
				?>
			</span>
			</h3>
		</div>
		<div class="col s12 m3 l2">
			<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-l qt-btn-primary"><?php esc_html_e('More info', 'kentha'); ?> <i class='material-icons'>arrow_forward</i></a>
		</div>
	</div>
</article>