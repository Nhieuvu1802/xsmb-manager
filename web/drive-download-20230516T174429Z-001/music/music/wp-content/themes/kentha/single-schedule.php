<?php
/*
Package: Kentha
Version: 0.0.0
Author: QantumThemes
Author URI: http://qantumthemes.com
Requires Kentha Radio Suite Plugin
*/
get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content qt-single-show">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-main-contents"); ?>>
			<div class="qt-container">
				<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
					<div class="qt-pageheader__in">
						<h1 class="qt-caption qt-nomargin"><?php the_title(); ?></h1>
						<hr class="qt-capseparator">
					</div>
				</header>
			</div>
			<div class="qt-container">
				<?php if(has_post_thumbnail()){ ?>
					<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url("full"); ?>">
						<?php the_post_thumbnail("large" ); ?>
					</a>
				<?php } ?>
				<div class="qt-the-content qt-paper qt-paddedcontent  qt-card">
					<div class="qt-the-content">
						<?php 
						/**
						 * Show social icons
						 * Requires Kentha Radio Suite plugin
						 */
						if(function_exists('qt_kentharadio_scheduleday')){
							echo qt_kentharadio_scheduleday(get_the_id()); // requires echo because this function is made mainly for shortcodes. Templates can be overridden [check manual]
						}
						?>
						<?php the_content(); ?>
					</div>
				</div>
			</div>
			<hr class="qt-spacer-l">
		</div>
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();



























