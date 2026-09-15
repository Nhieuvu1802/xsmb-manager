<?php
/*
Package: Kentha
Template Name: Page WooCommerce
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent" class="kentha-woocommerce-content">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<div class="qt-pageheader-std <?php kentha_is_negative(); ?>">
				<hr class="qt-spacer-m">
				<h1 class="qt-caption"><?php the_title(); ?></h1>
				<hr class="qt-capseparator">
			</div>
			<div class="qt-the-content qt-paper qt-paddedcontent  qt-card">
				<div class="qt-the-content">
					<?php the_content(); ?>
					<hr class="qt-clearfix">
				</div>
			</div>
			<hr class="qt-spacer-m">
		</div>
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();