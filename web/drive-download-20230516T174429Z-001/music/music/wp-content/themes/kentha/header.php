<?php
/*
Package: Kentha
*/
?>
<!doctype html>
<html class="no-js" <?php language_attributes(); ?>>
	<head>
		<meta charset="<?php bloginfo( 'charset' ); ?>">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">		
		<?php wp_head(); ?>
	</head>
	<body id="qtBody" <?php body_class(); ?> data-start>
		<?php get_template_part( 'phpincludes/part-bottomlayer-bg' ); ?>
		<?php $qt_header_transparent = true; ?>

		<?php  
		/**
		 * Mobile side nav
		 */
		?>
		<div id="qt-mobile-menu" class="side-nav qt-content-primary">
			<?php get_template_part( 'phpincludes/menu-sidenav' ) ?>
		</div>

		
		<div id="qtMasterContainter" class="qt-parentcontainer">

			<?php 
			switch (get_theme_mod( 'kentha_menu_style', '0' )) {
				case '1':
					get_template_part('phpincludes/menu-center/menu-center'); 
					break;
				default:
					get_template_part('phpincludes/menu-default/menu-default'); 
					break;
			}
			?>

			<?php  
			/**
			 * Mobile top bar
			 */
			?>
			<div id="qt-mob-navbar" class="qt-mobilemenu hide-on-xl-only qt-center qt-content-primary">
				<?php get_template_part('phpincludes/menu-mobile');  ?>
			</div>
			