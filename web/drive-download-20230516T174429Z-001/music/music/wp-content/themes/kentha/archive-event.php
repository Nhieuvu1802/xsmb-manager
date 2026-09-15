<?php
/*
Package: Kentha
Template Name: Archive events
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
						'post_type' => 'event',
						'posts_per_page' => 9,
						'post_status' => 'publish',
						'orderby' => 'meta_value',
						'order'   => 'ASC',
						'meta_key' => 'eventdate',
						'suppress_filters' => false,
						'paged' => kentha_get_paged()
					);

					/**
					 *  For events we reorder by date and eventually hide past events
					 */
					if(get_theme_mod( 'kentha_events_hideold', 0 ) == '1'){
						$args['meta_query'] = array(
							array(
								'key' => 'eventdate',
								'value' => date('Y-m-d'),
								'compare' => '>=',
								'type' => 'date'
							 )
						);
					}
					$wp_query = new WP_Query( $args );
					if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
						$post = $wp_query->post;
						setup_postdata( $post );
						?><div class="col s12 m6 l4"><?php  
						get_template_part ('phpincludes/part-archive-item-event');
						?></div><?php  
					endwhile; else: ?>
						<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
					<?php endif;
					wp_reset_postdata();
				} else {
					if ( have_posts() ) : while ( have_posts() ) : the_post();
						setup_postdata( $post );
						?><div class="col s12 m6 l4"><?php  
						get_template_part ( 'phpincludes/part-archive-item-event' );
						?></div><?php  
					endwhile; else: ?>
						<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
					<?php endif;
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