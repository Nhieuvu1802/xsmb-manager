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
		<article id="qtarticle" <?php post_class("qt-container qt-main-contents"); ?>>
			<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
				<div class="qt-pageheader__in">
					<span class="qt-tags">
						<?php
						$category = get_the_category(); 
						$limit = 20;
						foreach($category as $i => $cat){
							if($i > $limit){
								continue;
							}
							echo '<a href="'.get_category_link($cat->term_id ).'">'.$cat->cat_name.'</a>';  
						}
						?>
					</span>
					<h1 class="qt-caption"><?php the_title(); ?></h1>
					<span class="qt-item-metas"><?php get_template_part( 'phpincludes/part-item-metas' ); ?></span>
					<hr class="qt-capseparator">
				</div>
			</header>
			<div class="row">
				<div class="col s12 m12 l8">
					<?php if(has_post_thumbnail()){ ?>
					<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url("full"); ?>">
						<?php the_post_thumbnail("large" ); ?>
					</a>
					<?php } ?>

					<?php
					if($post->post_content != ''){
					?>
					<div class="qt-the-content qt-paper qt-paddedcontent qt-card">
						<div class="qt-the-content">
							<?php 
							the_content();
							wp_link_pages();
							the_tags('<div class="qt-posttags qt-item-metas"><hr><span class="qt-title">'.esc_html__("Tagged as ", "kentha").'</span>', ', ', '.</div>' );
							get_template_part( 'phpincludes/part-post-author'); 
							?>
						</div>
					</div>
					<?php  
					}
					?>
					<?php comments_template(); ?>
					<hr class="qt-spacer-m">
				</div>
				<div class="qt-sidebar col s12 m12 l4">
					<?php get_template_part( 'phpincludes/part-share' );  ?>
					<?php get_sidebar(); ?>
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