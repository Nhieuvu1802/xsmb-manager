<?php
/*
Package: Kentha
*/
?>
<div <?php post_class("qt-part-archive-item qt-carditem qt-release-small qtmusicplayer-trackitem"); ?>>
	<span class="qt-thumbactions">
		<?php if(has_post_thumbnail()) { ?>
			<?php the_post_thumbnail( 'post-thumbnail', array('class' => "attachment-thumbnail size-thumbnail wp-post-image")); ?>
		
		<?php } ?>

		<?php
		$resource_url = get_post_meta( get_the_id(), '_podcast_resourceurl', true );
		$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
		$date = date(  "Y" , strtotime(get_post_meta($post->ID, '_podcast_date',true)));
		if($resource_url !=''){
			$regex_mixcloud = "/mixcloud.com/"; 
			$regex_soundcloud = "/soundcloud.com/";                  
			$regex_mp3 = "/.mp3/";
			$regex_youtube = "/youtube.com/";
			if (preg_match ( $regex_mp3 , $resource_url ) ) {
				if(kentha_has_player()){
				$link = get_post_meta(get_the_id(), 'releasetrack_buyurl', true);
				if ( !$link || $link == '' ){
					$link = get_post_meta(get_the_id(), '_podcast_link', true);
				}
				$icon = 'file_download';
				$price = false;
					?>
						<a href="<?php the_permalink(); ?>" class="noajax qt-playthis qt-play qt-link-sec qtmusicplayer-play-btn" 
							data-qtmplayer-cover="<?php echo get_the_post_thumbnail_url(); ?>"
							data-qtmplayer-buylink="<?php echo esc_attr( $link ); ?>"
							data-qtmplayer-icon="<?php echo esc_attr( $icon ); ?>"
							data-qtmplayer-price="" 
							data-qtmplayer-file="<?php echo esc_attr( $resource_url ); ?>" 
							data-qtmplayer-title="<?php echo esc_attr(get_the_title( get_the_id() )); ?>" 
							data-qtmplayer-artist="<?php echo esc_attr( $artist ); ?>" 
							data-qtmplayer-album="<?php echo esc_attr( $date ); ?>" 
							data-qtmplayer-link="<?php the_permalink( get_the_id() ); ?>">
							<i class="material-icons qt-icons-circle">play_arrow</i>
						</a> 
					<?php
				}
			} else {
				?>
				<a href="<?php the_permalink(); ?>" class="qt-playthis qt-play qt-link-sec" ><i class="material-icons qt-icons-circle">play_arrow</i></a>
				<?php 
			}
		}
		?>
	</span>
	
	
	<h6 class="qt-tit">
		<a class="qt-ellipsis qt-t" href="<?php the_permalink(); ?>">
			<?php echo kentha_shorten(get_the_title(), 30); ?>
		</a>
	</h6>
	<?php  
	
	if($artist || $date){
		?>
		<span class="qt-details qt-item-metas" data-activatecard>
			<?php 
			echo esc_html($artist); 
			if($artist && $date){ ?> | <?php }
			echo esc_html($date);
			?>
		</span>
		<?php
	}
	?>	
</div>
