<?php
/**
* @package Kentha
* @since 1.3.6
*/

$id = $post->ID;
$resource_url = get_post_meta(  $post->ID, '_podcast_resourceurl', true );
$tinythumb = get_the_post_thumbnail_url(null,'post-thumbnail');
if($resource_url !=''){              
	$regex_mp3 = "/.mp3/";
	if (preg_match ( $regex_mp3 , $resource_url ) ) {
		$subtitle = get_post_meta( get_the_id(), '_podcast_artist', true );
		?>
		<li class="qtmusicplayer-trackitem">
			<?php
			if($tinythumb){
				?>
				<img src="<?php echo esc_url($tinythumb); ?>" alt="cover">
				<?php
			}
			?>
			<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
			data-qtmplayer-cover="<?php echo get_the_post_thumbnail_url(); ?>" 
			data-qtmplayer-file="<?php echo esc_url( $resource_url ); ?>" 
			data-qtmplayer-title="<?php echo esc_attr( get_the_title() ); ?>" 
			data-qtmplayer-artist="<?php  echo esc_attr( $subtitle ); ?>" 
			data-qtmplayer-album="" 
			data-qtmplayer-link="<?php the_permalink( get_the_id() ); ?>" 
			data-qtmplayer-buylink="" 
			data-qtmplayer-icon="open_in_browser" 
			><i class='material-icons'>play_circle_filled</i></span>
			<p>
				<span class="qt-tit"><?php echo esc_attr(get_the_title()); ?></span><br>
				<span class="qt-art"><?php echo esc_attr( $subtitle ); ?></span>
			</p>
		</li>
		<?php
	}
}