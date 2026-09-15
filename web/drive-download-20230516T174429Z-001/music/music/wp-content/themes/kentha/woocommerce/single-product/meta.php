<?php
/**
 * Single Product Meta
 *
 * This template can be overridden by copying it to yourtheme/woocommerce/single-product/meta.php.
 *
 * HOWEVER, on occasion WooCommerce will need to update template files and you
 * (the theme developer) will need to copy the new files to your theme to
 * maintain compatibility. We try to do this as little as possible, but it does
 * happen. When this occurs the version of the template file will be bumped and
 * the readme will list any important changes.
 *
 * @see 	    https://docs.woocommerce.com/document/template-structure/
 * @author 		WooThemes
 * @package 	WooCommerce/Templates
 * @version     3.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

global $product;
?>
<div class="product_meta">

	<?php do_action( 'woocommerce_product_meta_start' ); ?>


	<?php 
	// Kentha: removed SKY (not useful fr normal shops)
	?>
	

	<?php 
	// kentha: removed following line
	//echo wc_get_product_category_list( $product->get_id(), ', ', '<span class="posted_in">' . _n( 'Category:', 'Categories:', count( $product->get_category_ids() ), 'kentha' ) . ' ', '</span>' ); 

	?>


	<?php 
	// kentha: added class qt-item-metas
	?>

	<!-- <span class="tagged_as qt-item-metas">SKU: <?php echo $product->get_sku(); ?></span> -->

	<?php echo wc_get_product_tag_list( $product->get_id(), ', ', '<span class="tagged_as qt-item-metas">' . _n( 'Tag:', 'Tags:', count( $product->get_tag_ids() ), 'kentha' ) . ' ', '</span>' ); ?>

	<?php do_action( 'woocommerce_product_meta_end' ); ?>

</div>


<?php  
/**
 * Kentha custom part
 * adding playlist from a release
 */
$id = $product->get_id();
$linked_release = get_post_meta(  $id, 'kentha_related_release', true );

if( $linked_release ){
	?>
	<div class="qt-playlist-large">
		<ul class="qt-playlist">
			<?php  get_template_part( 'woocommerce-helpers/part-playlist-product' ); ?>
		</ul>
	</div>
	<?php
}








