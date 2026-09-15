<?php  
$img = get_theme_mod( 'kentha_bottomlayer_bg', false );
if($img){
	?>
	<div class="qt-bodybg qt-bottomlayer-bg" data-bgimage="<?php echo esc_url(get_theme_mod( 'kentha_bottomlayer_bg', false )); ?>" data-parallax="0"></div>
	<?php
}