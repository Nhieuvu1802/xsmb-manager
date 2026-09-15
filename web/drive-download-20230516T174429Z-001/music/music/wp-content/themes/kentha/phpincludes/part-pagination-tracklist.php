<?php
/*
Package: Sonido
Description: pagination numbering
Version: 0.0.0
Author: QantumThemes
Author URI: http://qantumthemes.com
*/
?>
<!-- PAGINATION ========================= -->

	<?php
	if(get_theme_mod( 'kentha_loadmore' )){
		$link =  get_next_posts_page_link();
		$callback = ( isset($callback) ) ? $callback : "";
		global $wp_query;
		$max = $wp_query->max_num_pages;
		$paged = kentha_get_paged(); 
		if ( get_query_var('paged') ) {
			$paged = get_query_var('paged');
		} elseif ( get_query_var('page') ) {
			$paged = get_query_var('page');
		} else {
		   $paged = 1;
		}
		if(!empty($link) && ($paged < $max)): ?>
			<li id="qtpagination" class="qt-container qt-wp-pagination qt-wp-pagination--tracklist">
			<div class="qt-center">
				<a id="qtloadmore" href="<?php echo esc_url( $link ); ?>"  class="qt-btn qt-btn-l qt-btn-primary qt-center noajax">
				   <span><?php esc_html_e("Load more", "kentha"); ?></span><i class='material-icons'>sync</i>
				</a>
			</div>
			</li>
		<?php  
		endif; 
	} else {
		$args = array(
			'type' => 'list',
			'prev_text'          => "<i class='material-icons'>navigate_before</i>",
			'next_text'          => "<i class='material-icons'>navigate_next</i>",
		);
		?><li id="qtpagination" class="qt-container qt-wp-pagination qt-wp-pagination--tracklist"><?php 
		echo paginate_links( $args ); 
		?></li><?php  
	}
	?>

<!-- PAGINATION END ========================= -->