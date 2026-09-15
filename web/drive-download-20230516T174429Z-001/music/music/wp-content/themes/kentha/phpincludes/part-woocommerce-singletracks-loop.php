<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0.0
 * 
 * Displays only single track products in a playlist format
 */
?>
<div class="qt-playlist-large qt-woocommerce-singletrack-loop qt-paper qt-card">
	<ul id="qtloop" class="qt-playlist">
		<?php 
		if(is_page()){
			
			$args = array(
				'post_type' => 'product',
				'ignore_sticky_posts' => 1,
				'post_status' => 'publish',
				'suppress_filters' => false,
				'posts_per_page' => 10,
				'paged' => kentha_get_paged()
			);

			/**
			 *  Extract only products marked as single track
			 */
			$args['meta_query'] = array(
				array(
					'key' => 'kentha_singletrack',
					'value' => '1',
					'compare' => '=',
				 )
			);
			$wp_query = new WP_Query( $args );
			if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
				$post = $wp_query->post;
				setup_postdata( $post );
				get_template_part ('phpincludes/part-archive-item-product-singletrack'); 
			endwhile; else: ?>
				<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
			<?php 
			endif;
			wp_reset_postdata();
		} else {
			if ( have_posts() ) : while ( have_posts() ) : the_post();
				setup_postdata( $post );
				get_template_part ( 'phpincludes/part-archive-item-product-singletrack' );
			endwhile; else: ?>
				<h3><?php esc_html_e("Sorry, nothing here","kentha")?></h3>
		<?php 
			endif;
		}
		?>
		<?php get_template_part ('phpincludes/part-pagination-tracklist'); ?>
	</ul>
</div>
