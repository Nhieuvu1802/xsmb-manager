<?php
/*
Package: Kentha
*/

/**
 * Playable radio stream
 * 
 */
$mp3_stream_url = get_post_meta( get_the_id(), 'mp3_stream_url', true );
$subtitle = get_post_meta($post->ID, 'qt_radio_subtitle',true);
$tinythumb = get_the_post_thumbnail_url(null,'post-thumbnail');
$id = $post->ID;
if( $mp3_stream_url ){
	$icon = get_post_meta( $id, 'qt_player_icon', true );
	$thumb = get_the_post_thumbnail_url($id, 'medium' );
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
		data-qtmplayer-type="radio"
		data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" 
		data-qtmplayer-file="<?php echo esc_url( $mp3_stream_url ); ?>" 
		data-qtmplayer-title="<?php echo esc_attr( get_the_title() ); ?>" 
		data-qtmplayer-artist="<?php  echo esc_attr( $subtitle ); ?>" 
		data-qtmplayer-album="<?php echo esc_attr( $subtitle ); ?>" 
		data-qtmplayer-link="<?php the_permalink( get_the_id() ); ?>" 
		data-qtmplayer-buylink="" 
		data-qtmplayer-icon="<?php echo esc_attr($icon); ?>" 

		<?php  
		/**
		 * Radio feed reading
		 */
		?>
		data-radiochannel
		data-host="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedHost',true )); ?>"
		data-port="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedPort',true )); ?>"
		data-ssl="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedSSL',true )); ?>"
		data-icecasturl="<?php echo esc_attr(get_post_meta( $id, 'qticecasturl',true )); ?>"
		data-icecastmountpoint="<?php echo esc_attr(get_post_meta( $id, 'qticecastMountpoint',true )); ?>"
		data-radiodotco="<?php echo esc_attr(get_post_meta( $id, 'qtradiodotco',true )); ?>"
		data-airtime="<?php echo esc_attr(get_post_meta( $id, 'qtairtime',true )); ?>"
		data-radionomy="<?php echo esc_attr(get_post_meta( $id, 'qtradionomy',true )); ?>"
		data-textfeed="<?php echo esc_attr(get_post_meta( $id, 'qttextfeed',true )); ?>"
		data-channel="<?php echo esc_attr(get_post_meta( $id, 'qtradiofeedChannel',true )); ?>"

		><i class='material-icons'>play_circle_filled</i></span>
		<p>
			<span class="qt-tit"><?php echo esc_attr(get_the_title()); ?></span><br>
			<span class="qt-art"><?php echo esc_attr( $subtitle ); ?></span>
		</p>
	</li>
	<?php
}
?>
