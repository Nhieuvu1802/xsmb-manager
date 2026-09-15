<?php global $product; ?>
<article <?php post_class('qt-part-archive-item qt-grid-item qt-part-archive-item-grid qt-paper'); ?>>
	<?php  
	do_action('woocommerce_before_shop_loop_item')
	?>
	<a href="<?php the_permalink(); ?>" class="qt-prod-thumb" <?php if(has_post_thumbnail()){ ?><?php } ?>  data-bgimage="<?php echo get_the_post_thumbnail_url(null,'medium'); ?>" data-parallax="0" data-attachment="local">
		<?php if(has_post_thumbnail()){ ?>
				<?php the_post_thumbnail('kentha-squared'); ?>
		<?php } ?>

		<?php  
		/** 
		 * Icon
		 * @since  2.0.3
		* =============================================================================*/
		kentha_software_icon($id);
		?>
	</a>
	<header class="qt-headings">
		
		<h4 class="qt-center qt-ellipsis qt-tit"><a href="<?php the_permalink(); ?>" ><?php the_title(); ?></a></h4>
	</header>
	<div class="qt-summary">
		<h4 class="qt-item-metas qt-center">
			<?php if ( $price_html = $product->get_price_html() ) : ?><span class="price"><?php echo $price_html; ?></span> <?php endif; ?> 
		</h4>
	</div>
	<footer class="qt-center">
		<?php  
		/**
		 * Hook: woocommerce_after_shop_loop_item.
		 *
		 * @hooked woocommerce_template_loop_product_link_close - 5
		 * @hooked woocommerce_template_loop_add_to_cart - 10
		 */
		do_action( 'woocommerce_after_shop_loop_item' );
		?>
	</footer>
</article>