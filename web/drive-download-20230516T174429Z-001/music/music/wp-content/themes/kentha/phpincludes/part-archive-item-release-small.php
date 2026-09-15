<?php
/*
Package: Kentha
*/
?>
<!-- ITEM INLINE  ========================= -->
<div <?php post_class("qt-part-archive-item qt-carditem qt-release-small"); ?>>
	<?php if(has_post_thumbnail()) { ?>
	<span class="qt-thumbactions">
		<?php the_post_thumbnail( 'post-thumbnail', array('class' => "attachment-thumbnail size-thumbnail wp-post-image")); ?>
		<a href="<?php the_permalink(); ?>" class="noajax qt-playthis" data-kenthaplayer-addrelease="<?php echo add_query_arg('qt_json', '1',  get_the_permalink()); ?>" data-playnow="1">
			<i class="material-icons qt-icons-circle">play_arrow</i>
		</a>
		<?php  
		$eventslinks= get_post_meta( get_the_id() , 'track_repeatablebuylinks', true );   
		$url =  add_query_arg('qt_json', '1',  get_the_permalink());
		?>
		<a href="<?php the_permalink(); ?>" class="noajax qt-add qt-btn-secondary" data-clickonce="1" data-kenthaplayer-addrelease="<?php echo esc_url($url); ?>">
			<i class="material-icons">playlist_add</i>
		</a>
		<?php  
		if(is_array($eventslinks)){
			if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
				// WooCommerce integration 
				$buylink = $eventslinks[0]['cbuylink_url'];
				if(is_numeric($buylink)) {
					$prodid = $buylink;
					$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
					?>
					<a href="<?php echo esc_url( $buylink ); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="noajax qt-cartbt qt-btn-secondary product_type_simple add_to_cart_button ajax_add_to_cart">
						<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
					</a>
					<?php  
				} else {
					?>
					<a href="<?php the_permalink(); ?>" class="qt-cartbt qt-btn-secondary" rel="nofollow" target="_blank">
						<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
					</a>
					<?php
				}
			}
		}
		?>
	</span>
	<?php } ?>
	<span class="qt-details qt-small"></span>
	
	<h6 class="qt-tit">
		<a class="qt-ellipsis qt-t" href="<?php the_permalink(); ?>">
			<?php echo kentha_shorten(get_the_title(), 16); ?>
		</a>
	</h6>
	<span class="qt-item-metas qt-small">
		<?php 
		$tracks = get_post_meta(get_the_id(), 'track_repeatable');
		if(is_array($tracks)){ 
			$tracks = $tracks[0]; 
			echo count($tracks);  ?>&nbsp;<?php esc_html_e( 'Tracks', 'kentha' ); 
		} ?> | <?php 
			echo date( "Y", strtotime(get_post_meta(get_the_id(), 'general_release_details_release_date',true))); 
		?>
	</span>
</div>
<!-- ITEM INLINE END ========================= -->
