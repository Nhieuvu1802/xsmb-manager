<?php
/*
Package: Kentha
Template Name: Shop single track products
*/

$layout = get_theme_mod( 'kentha_woocommerce_design', 'left-sidebar' );
get_header(); 

?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" class="qt-container qt-main-contents">
			<div class="qt-pageheader-std <?php kentha_is_negative(); ?>">
				<hr class="qt-spacer-m">
				<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
				<hr class="qt-spacer-m">
			</div>
			<div class="row">
				<?php 
				switch ($layout){
					case 'fullpage':
						?>
						<div class="qt-sidebar col s12 m12">
							<?php get_template_part( 'phpincludes/part-woocommerce-singletracks-loop' ); ?>
						</div>
						<?php
						break;
					case 'right-sidebar':
						?>	
						<div class="col s12 m8 l8">
							<?php get_template_part( 'phpincludes/part-woocommerce-singletracks-loop' ); ?>
						</div>
						<div class="qt-sidebar col s12 m4 l4">
							<?php get_sidebar('woocommerce'); ?>
						</div>
						<?php
						break;
					case 'left-sidebar':
					default:
						?>
						<div class="qt-sidebar col s12 m4 l4">
							<?php get_sidebar('woocommerce'); ?>
						</div>
						<div class="col s12 m8 l8">
							<?php get_template_part( 'phpincludes/part-woocommerce-singletracks-loop' ); ?>
						</div>
						<?php
						break;
				}
				?>
			</div>
		</div>
		<hr class="qt-spacer-m">
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();