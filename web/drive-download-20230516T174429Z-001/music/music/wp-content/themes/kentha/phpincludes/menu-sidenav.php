<?php
/*
Package: Kentha
*/
?>
<ul class="qt-side-nav  qt-dropdown-menu">
	<li>
		<span class="qt-closesidenav">
			<i class='material-icons'>close</i> <?php esc_html_e('Close', 'kentha'); ?>
		</span>
	</li>
	<?php get_template_part('phpincludes/part-social'); ?>
	<li class="qt-clearfix">
	</li>
	<?php
		if ( has_nav_menu( 'kentha_menu_primary' ) ) {
			wp_nav_menu( array(
				'theme_location' => 'kentha_menu_primary',
				'depth' => 3,
				'container' => false,
				'items_wrap' => '%3$s'
			));
		}
	?>
</ul>