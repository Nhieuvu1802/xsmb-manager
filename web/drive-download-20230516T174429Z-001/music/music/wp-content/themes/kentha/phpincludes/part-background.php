<?php
/*
Package: Kentha
*/


/**
 * [$fadeout defines if the background will go transparent on scroll. There are a global customizer setting and a single page override]
 * @var [bol]
 *
 *
 *	Important for ajax loading: if is same video, need to NOT replace this element
 *
 *
 *
 * 
 */

$disable_bg = false;
if( is_singular() || is_home() || is_page() || is_front_page() ){
	$disable_bg =  get_post_meta( get_the_id(), 'kentha_disable_bg', true );
}

if(!$disable_bg){
	$fadeout = get_theme_mod( 'kentha_sitebg_fadeout' );
	$page_fadeout = get_post_meta( get_the_id(), 'kentha_fadeout', true );
	if($page_fadeout == '1') {
		$fadeout = 1;
	} elseif ($page_fadeout == '0'){
		$fadeout = 0;
	}
	?>
	<div id="qtPageBg"  <?php if($fadeout){ ?> data-start="opacity:1" data-50p="opacity:0" <?php } ?>>
		<?php

		/**
		 * ============================================
		 * Image bg
		 * ============================================
		 */
		$bg = get_theme_mod("kentha_sitebg");


		if( is_singular() || is_home() || is_page() || is_front_page()  ){
			$pagebg = get_post_meta( get_the_id(), 'kentha_image_bg', true );
			if($pagebg){
				$bg = wp_get_attachment_url( $pagebg );
			}
		}



		if($bg){ 
			?>
			<div class="qt-pagebg-in" data-bgimage="<?php echo esc_url($bg); ?>"></div>
			<?php 
		} 

		/**
		 * ============================================
		 * Video bg
		 * ============================================
		 */
		
		$v = false;

		/**
		 * Special case: I have global video bg but local post background, I show the post background and NOT the global video
		 */
		if(!get_post_meta( get_the_id(), 'kentha_image_bg', true )){
			$v = get_theme_mod("kentha_sitebg_video");
		}

		/**
		 * Local post video
		 */
		if( is_singular() || is_home() || is_page() || is_front_page() ){
			$pagev = get_post_meta(get_the_id(),'kentha_video_bg', true);
			if($pagev){
				$v = $pagev;
			}
		}

		if($v){
			$s = get_post_meta(get_the_id(),'kentha_video_start', true);
			?>
			<div id="qtvideobg" class="qt-videobg hide-on-med-and-down" data-quality="small" data-id="<?php echo esc_attr($v); ?>" data-start="<?php echo esc_attr($s); ?>" data-mute="1"></div>
			<?php 
		} 
		?>
		<div class="qt-darken-bg-<?php echo get_theme_mod( 'qt_darken_background', '30' ) ?>"></div>
	</div>
<?php } // disable BG end ?>