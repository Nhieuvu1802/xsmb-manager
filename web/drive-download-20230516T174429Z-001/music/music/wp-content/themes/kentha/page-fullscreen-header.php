<?php
/*
Package: Kentha
Template Name: Page with fullscreen header
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<h1 class="qt-caption"><?php the_title(); ?></h1>
					<hr class="qt-capseparator">
				</div>
			</header>
			<?php if(has_post_thumbnail()){ ?>
			<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url("full"); ?>">
				<?php the_post_thumbnail("large" ); ?>
			</a>
			<?php } ?>
			<div class="qt-the-content qt-paper qt-paddedcontent  qt-card">
				<div class="qt-the-content">
					<?php the_content(); ?>
				</div>
			</div>
			<?php if ( comments_open() ){ comments_template(); } ?>
			<hr class="qt-spacer-l">
		</div>
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();