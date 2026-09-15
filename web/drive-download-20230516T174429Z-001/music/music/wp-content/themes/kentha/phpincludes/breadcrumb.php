<?php  

$items = array(
	array( 'release', 'Releases', 'genre'),
	array( 'podcast', 'Podcast', 'podcastfilter'),
	array( 'artist', 'Artists', 'artistgenre'),
	array( 'event', 'Events', 'eventtype'),
);
?>
<ul id="qtBreadcrumb" class="qt-breadcrumb qt-item-metas qt-clearfix">

	<?php 
	if (!is_home() && !is_front_page()) { 
		?>
		<li><a href="<?php echo esc_url(home_url("/")); ?>"><?php esc_html_e('Home', 'kentha'); ?></a></li>
		<?php  
		if (is_category() ) {
			?>
			<li><?php the_category(' </li><li>/'); ?></li>
			<?php
		}
		elseif (is_single()) {
			$id = $post->ID;

			if(get_post_type( $id ) == 'post'){
				?>
				<li>/<?php the_category(' </li><li>/'); ?></li>
				<?php
			}
			foreach($items as $item){
				if(get_post_type( $id ) == $item[0]){
					?>
					<li>/<a href="<?php echo get_post_type_archive_link( $item[0] ); ?>"><?php echo esc_html($item[1]); ?></a></li>
					<?php
					echo get_the_term_list( $post->ID, $item[2], '<li>/','</li><li>/', '</li>' );
				}
			}
			?>
			<li>/<span><?php echo kentha_shorten(get_the_title(), 16); ?></span></li>
			<?php  
		} 
		elseif (is_page() && !is_home() && !is_front_page()) {
			?>
			<li>/<span><?php the_title(); ?></span></li>
			<?php  
		} elseif (is_post_type_archive( 'release' ) || is_tax('genre')) {
			if(get_post_type( $id ) == 'release'){
				?>
				<li>/<a href="<?php echo get_post_type_archive_link( 'release' ); ?>"><?php esc_html_e("Releases", "kentha") ?></a></li>
				<?php
			}
			echo get_the_term_list( $post->ID, 'genre', '<li>/', '</li><li>/', '</li>' );
		} elseif (is_post_type_archive( 'event' ) || is_tax('eventtype')) {
			if(get_post_type( $id ) == 'event'){
				?>
				<li>/<a href="<?php echo get_post_type_archive_link( 'event' ); ?>"><?php esc_html_e("Events", "kentha") ?></a></li>
				<?php
			}
			echo get_the_term_list( $post->ID, 'eventtype', '<li>/', '</li><li>/', '</li>' );
		} elseif (is_post_type_archive( 'artist' ) || is_tax('artistgenre')) {
			if(get_post_type( $id ) == 'artist'){
				?>
				<li>/<a href="<?php echo get_post_type_archive_link( 'artist' ); ?>"><?php esc_html_e("Artists", "kentha") ?></a></li>
				<?php
			}
			echo get_the_term_list( $post->ID, 'artistgenre', '<li>/', '</li><li>/', '</li>' );
		} elseif (is_post_type_archive( 'podcast' ) || is_tax('podcastfilter')) {
			if(get_post_type( $id ) == 'podcast'){
				?>
				<li>/<a href="<?php echo get_post_type_archive_link( 'podcast' ); ?>"><?php esc_html_e("Podcasts", "kentha") ?></a></li>
				<?php
			}
			echo get_the_term_list( $post->ID, 'podcastfilter', '<li>/', '</li><li>/', '</li>' );
		}
		elseif (is_tag()) {
			single_tag_title();
		}
		elseif (is_day()) { ?>
			<li>/<?php esc_html_e('Archive for',"kentha"); the_time('F jS, Y'); ?></li>
			<?php
		}
		elseif (is_month()) { ?>
			<li>/<?php esc_html_e('Archive for',"kentha"); the_time('F, Y'); ?></li>
			<?php
		}
		elseif (is_year()) { ?>
			<li>/<?php esc_html_e('Archive for',"kentha"); the_time('Y'); ?></li>
			<?php
		}
		elseif (is_author()) { ?>
			<li>/<?php esc_html_e('Author archive',"kentha"); the_time('Y'); ?></li>
			<?php
		}
		elseif (isset($_GET['paged']) && !empty($_GET['paged'])) {
			?>
			<li>/<span><?php esc_html_e('Blog archive',"kentha"); ?></span></li>
			<?php 
		}
		elseif (is_search()) {
			?>
			<li>/<?php
			printf( 
				esc_attr__( 'Search Results for: %s', "kentha" ), 
				esc_attr(get_search_query())
			); 
			?></li><?php
		}
	} 
	?>
</ul>

