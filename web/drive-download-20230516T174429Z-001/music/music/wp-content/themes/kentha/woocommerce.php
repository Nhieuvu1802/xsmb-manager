<?php
/*
Package: Kentha
Description: Woocommerce template page
*/

if( is_shop() && get_theme_mod('kentha_woocommerce_design_shop' ) == 'tracklist' ){
	get_template_part( 'archive-singletracks' );
	
} else if(  is_tax( 'product_cat'  ) && get_theme_mod('kentha_woocommerce_design_shop' ) == 'tracklist'){
	get_template_part( 'archive-singletracks' );

} else if(  is_tax( 'product_tag'  ) && get_theme_mod('kentha_woocommerce_design_shop' ) == 'tracklist'){
	get_template_part( 'archive-singletracks' );

} else if ( is_tax( 'product_tag'  ) && get_theme_mod('kentha_woocommerce_design_shop' ) == 'tracklist'){
	get_template_part( 'archive-singletracks' );

} else if ( is_tax( 'trackgenre' ) && get_theme_mod('kentha_woocommerce_design_genres' ) == 'tracklist'){
	get_template_part( 'archive-singletracks' );

} else if ( is_tax( 'tracksoftware' ) && get_theme_mod('kentha_woocommerce_design_genres' ) == 'tracklist'){
	get_template_part( 'archive-singletracks' );

} else if ( get_theme_mod( 'kentha_woocommerce_design_genres') == 'tracklist' && ( is_tax( 'trackgenre' ) || is_tax( 'royalty-types' ) || is_tax( 'tracksoftware' )  ) ){
	get_template_part( 'archive-singletracks' );

} else {
	get_header();
	if ( is_shop() || is_tax( 'product_cat' ) ){
		$layout = get_theme_mod( 'kentha_woocommerce_design', 'left-sidebar' );
	} else {
		$layout = 'fullpage'; // seems we have to force it again for some reason
	}
	?>
	<div id="maincontent" class="kentha-woocommerce-content">
		<div class="qt-main qt-clearfix qt-3dfx-content">
			<?php get_template_part( 'phpincludes/part-background' ); ?>
			<div id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
				<div class="row">
					<?php 
					switch ($layout){
						case 'fullpage':
							?>
							<div class="qt-sidebar col s12 m12">
								<?php woocommerce_content(); ?>
							</div>
							<?php
							break;
						case 'right-sidebar':
							?>
							<div class="col s12 m8 l8">
								<?php woocommerce_content(); ?>
							</div>
							<div class="qt-sidebar col s12 m4 l4">
								<hr class="qt-spacer-m">
								<?php get_sidebar('woocommerce'); ?>
							</div>
							<?php
							break;
						case 'left-sidebar':
						default:
							?>
							<div class="qt-sidebar col s12 m4 l4">
								<hr class="qt-spacer-m">
								<?php get_sidebar('woocommerce'); ?>
							</div>
							<div class="col s12 m8 l8">
								<?php woocommerce_content(); ?>
							</div>
							<?php
							break;
					}
					?>
				</div>
				<hr class="qt-spacer-l">
			</div>
		</div>
	</div>
	<?php get_footer();
}