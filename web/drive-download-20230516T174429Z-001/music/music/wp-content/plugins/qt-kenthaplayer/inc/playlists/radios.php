<?php
/**
 * =================================================
 * KenthaRadio plugin support
 * =================================================
 * Since 1.7.0
 * List of radios in player from QT KenthaRadio Plugin
 * =================================================
 */
if(function_exists( 'qt_kentharadio_active' )){
	$args = array(
		'post_type' => 'radiochannel',
		'ignore_sticky_posts' => 1,
		'post_status' => 'publish',
		'orderby' => array ( 'menu_order' => 'ASC', 'date' => 'DESC'),
		'suppress_filters' => false,
		'posts_per_page' => -1,
		'paged' => 1,
		'meta_query' => array(
			array(
				'key' => 'qt-kentharadio-addtoplaylist',
				'value' => '1',
				'compare' => '='
			)
		)
	);
	$wp_query = new WP_Query( $args );
	if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
		$post = $wp_query->post;
		setup_postdata( $post );
		get_template_part('phpincludes/part-playlist-radio' );  
	endwhile; endif;
	wp_reset_postdata();
}
/**
 * =================================================
 * END OF KenthaRadio plugin support
 * =================================================
 */

?>