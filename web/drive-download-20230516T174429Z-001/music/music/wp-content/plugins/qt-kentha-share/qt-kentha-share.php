<?php
/*
Plugin Name: QT Kentha Share
Plugin URI: http://qantumthemes.com
Description: Add sharing icons
Version: 1.1.0
Author: QantumThemes
Author URI: http://qantumthemes.com
*/


function qt_kentha_share(){
	ob_start();
	$revert = array('%21'=>'!', '%2A'=>'*', '%27'=>"'", '%28'=>'(', '%29'=>')');

	$id = get_the_ID();

    $pageurl = strtr(rawurlencode( get_permalink( $id )  ), $revert);



	// Get the featured image.
	if ( has_post_thumbnail() ) {
		$thumbnail_id = get_post_thumbnail_id( $id );
		$thumbnail    = $thumbnail_id ? current( wp_get_attachment_image_src( $thumbnail_id, 'large', true ) ) : '';
	} else {
		$thumbnail = null;
	}

	// Generate the Twitter URL.
	$twitter_url = 'http://twitter.com/share?text=' . get_the_title() . '&url=' . get_the_permalink() . '';

	// Generate the Facebook URL.
	$facebook_url = 'https://www.facebook.com/sharer/sharer.php?u=' . get_the_permalink() . '&title=' . get_the_title() . '';

	// Generate the LinkedIn URL.
	$linkedin_url = 'https://www.linkedin.com/shareArticle?mini=true&url=' . get_the_permalink() . '&title=' . get_the_title() . '';

	// Generate the Pinterest URL.
	$pinterest_url = 'https://pinterest.com/pin/create/button/?media=' . esc_url( $thumbnail ) . '&url=' . get_the_permalink() . '&description=' . get_the_title() . '&';

	// Generate the Tumblr URL.
	$tumblr_url = 'https://tumblr.com/share/link?url=' . get_the_permalink() . '&name=' . get_the_title() . '';

	$email_url = 'subject='. get_the_title().'&amp;body=' . esc_html__('Check out this site', 'ttg-reaktions'). ' '.get_the_permalink()  ;
	?>
	<div class="qt-part-share qt-content-primary qt-card qt-negative">	
		<a class="qt-btn-fb qt-popupwindow" data-name="Share" data-width="600" data-height="500" target="_blank" href="<?php echo esc_url($facebook_url); ?>"><i class="qt-socicon-facebook"></i></a>
		<a class="qt-btn-tw qt-popupwindow" data-name="Share" data-width="600" data-height="500" target="_blank" href="<?php echo esc_url($twitter_url); ?>"><i class="qt-socicon-twitter"></i></a>
		<a class="qt-btn-pi qt-popupwindow" data-name="Share" data-width="600" data-height="500" target="_blank" href="<?php echo esc_url($pinterest_url); ?>"><i class="qt-socicon-pinterest"></i></a>
		<a class="qt-btn-wu qt-popupwindow" data-name="Share" data-width="600" data-height="500" target="_blank" href="https://wa.me/?text=<?php echo urlencode( get_the_title().' - ' ).get_the_permalink(); ?>"><i class="qt-socicon-whatsapp"></i></a>
	</div>
	<?php  
	echo ob_get_clean();
}




add_shortcode( 'qt-kentha-share', 'qt_kentha_share' );