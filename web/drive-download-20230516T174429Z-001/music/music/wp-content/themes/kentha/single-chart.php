<?php
/*
Package: Kentha
@requires qt-kentharadio
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-artist qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents qt-single-members"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<span class="qt-tags">
						<?php  echo get_the_term_list( get_the_id(), 'chartcategory'); ?>
					</span>
					<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
					<?php  
					$nat = get_post_meta($post->ID, 'member_role',true);
					if($nat){ ?>
						<span class="qt-item-metas"><?php echo esc_html($nat);	?></span>
					<?php } ?>
					<hr class="qt-capseparator">
				</div>
			</header>
			<div class="row">
				<div class="col s12 m8 l8">
					<?php if(has_post_thumbnail(  )){ ?>
					<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'large' ); ?>">
						<?php the_post_thumbnail("large" ); ?>
					</a>
					<?php } ?>
					<div class="qt-paddedcontent qt-paper">
						<div class="qt-the-content">
							<?php 
							the_content(); 
							?>
							<hr class="qt-spacer-s">
							<?php
							if(shortcode_exists( 'qt-chart' )){
								echo do_shortcode('[qt-chart id="'.($post->ID).'"]' );
							}
							?>
						</div>
					</div>
					<hr class="qt-spacer-s">
				</div>
				<div class="col s12 m4 l4">
					<?php			
					get_template_part( 'phpincludes/part-share' ); 
					get_sidebar(); 
					?>
					<hr class="qt-spacer-s">
				</div>
			</div>
		</article>
		<?php get_template_part( 'phpincludes/part-related' ); ?>
		<hr class="qt-spacer-m">
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();