<?php
/*
Package: Kentha
*/
get_header(); 
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" class="qt-container qt-main-contents">
			<div class="<?php kentha_is_negative(); ?>">
				<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
				<hr class="qt-capseparator">
			</div>
			<div class="row">
				<div id="qtloop" class="col s12 m8 l8">
					<?php 
					if ( have_posts() ) : while ( have_posts() ) : the_post();
						setup_postdata( $post );
						get_template_part ( 'phpincludes/part-archive-item-search' );
					endwhile; else: ?>
						<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
					<?php endif;
					wp_reset_postdata();
					?>
					<?php get_template_part ('phpincludes/part-pagination'); ?>
				</div>
				<div class="qt-sidebar col s12 m4 l4">
					<?php get_sidebar(); ?>
				</div>
			</div>
			<hr class="qt-spacer-m">
		</div>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();