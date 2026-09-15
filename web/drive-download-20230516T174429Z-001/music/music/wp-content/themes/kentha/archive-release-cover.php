<?php
/*
Package: Kentha
Template Name: Archive releases cover
*/
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
				<hr class="qt-capseparator">
			</div>
			<div id="qtloop" class="row">
				<?php 
				if(is_page()){
					/**
					 * [$args Query arguments]
					 * @var array
					 */
					$args = array(
						'post_type' => 'release',
						'ignore_sticky_posts' => 1,
						'post_status' => 'publish',
						'suppress_filters' => false,
						'posts_per_page' => 12,
						'paged' => kentha_get_paged()
					);
					/**
					 * [$wp_query execution of the query]
					 * @var WP_Query
					 */
					$wp_query = new WP_Query( $args );
					if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
						$post = $wp_query->post;
						setup_postdata( $post );
						?><div class="col s6 m3"><?php  
						get_template_part ('phpincludes/part-archive-item-release-med');
						?></div><?php  
					endwhile; else: ?>
						<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
					<?php endif;
					wp_reset_postdata();
				}
				?>
				<?php get_template_part ('phpincludes/part-pagination'); ?> 
			</div>
		</div>
		<hr class="qt-spacer-m">
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();