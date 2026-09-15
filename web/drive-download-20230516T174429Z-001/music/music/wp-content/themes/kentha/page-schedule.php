<?php
/*
Package: Kentha
Template Name: Radio Schedule 
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
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
					<?php 					
					/**
					 * Show genre tags
					 * Requires Kentha Radio Suite plugin
					 */
					if(shortcode_exists('qt-schedule')){
						echo do_shortcode("[qt-schedule]");
					} else {
						esc_attr_e('This template requires Kentha Radio Plugin', 'kentha');
					}
					?>
				</div>
			</div>
			<?php comments_template(); ?>
			<hr class="qt-spacer-l">
		</div>
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();