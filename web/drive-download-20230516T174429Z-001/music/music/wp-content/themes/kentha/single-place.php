<?php
/*
Package: Kentha
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<div class="<?php kentha_is_negative(); ?>">
				<h1 class="qt-caption"><?php the_title(); ?></h1>
				<hr class="qt-capseparator">
			</div>
			<?php if(has_post_thumbnail()){ ?>
			<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url("full"); ?>">
				<?php the_post_thumbnail("large" ); ?>
			</a>
			<?php } ?>
			<div class="qt-the-content qt-content-primary-dark qt-paddedcontent  qt-card">
				<div class="qt-the-content">

					<?php get_template_part('phpincludes/part-eventtable' ); ?>
					<?php
					$coord = get_post_meta($id,  'qt_coord',true);
					 if($coord!== '' ){ ?>
						<h4 class="qt-caption-small"><?php esc_html_e("Location", 'kentha'); ?></h4>
						<div class="qt-map-event qt-spacer-s">
							<div class="qt_dynamicmaps" id="map<?php echo esc_attr($post->ID); ?>" data-colors="QT_map_dark" data-coord="<?php echo esc_attr($coord); ?>" data-height="350">
							</div>
							<hr class="qt-spacer-s">
						</div>
					<?php } ?>
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