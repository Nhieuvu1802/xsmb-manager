<?php
/*
Package: Kentha
*/

if(is_active_sidebar( 'kentha-footer-sidebar' ) ){
	$bg = get_theme_mod("kentha_footer_backgroundimage");
	?>
	<div id="qtFooterWidgets" class="qt-footer-widgets-container qt-negative qt-content-aside qt-relative" <?php if($bg){ ?>data-bgimage="<?php echo esc_url($bg); ?>"<?php } ?> data-parallax="<?php echo get_theme_mod('kentha_footer_parallax'); ?>">
		<div class="qt-footer-widgets qt-vertical-padding-l">
			<div class="qt-container-l">
				<div id="qtFwidgetsMasonry" class="row qt-masonry qt-widgets">
					<?php dynamic_sidebar( 'kentha-footer-sidebar' ); ?>
			    </div>
			</div>
		</div>
	</div>
	<?php  
}
?>
