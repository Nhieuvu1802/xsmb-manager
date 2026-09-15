<?php
/*
Package: Kentha
*/
?>
<nav class="qt-menubar qt-menubar-default nav-wrapper hide-on-xl-and-down">
	<div class="qt-content-primary-dark qt-menubg-color">
		<?php
		/**
		 * This is an empty div needed to provide background color while scrolling
		 */
		 ?>
	</div>
	<div class="qt-container-l">
		<ul class="qt-menu-secondary">
			<?php get_template_part('phpincludes/part-social-and-count');  ?>
		</ul>
	</div>
	<ul class="qt-desktopmenu">
		<li class="qt-logo-link"><a href="<?php echo esc_url( home_url( '/' ) ); ?>" class="qt-logo-link">
			<?php
			/**  Logo or title
			 *  ============================================= */
			$logo = get_theme_mod("kentha_logo_header","");
			if($logo != ''){
				echo '<img src="'.esc_attr($logo).'" alt="'.esc_attr__("Home","kentha").'">';
			}else{
				echo get_bloginfo('name');
			}
			?>
		</a></li>
		<?php 
		/**
		*
		*  Primary menu
		*  =============================================
		*/
		if ( has_nav_menu( 'kentha_menu_primary' ) ) {
			wp_nav_menu( array(
				'theme_location' => 'kentha_menu_primary',
				'depth' => 3,
				'container' => false,
				'items_wrap' => '%3$s'
			));
		}
		?>
		<?php if(get_theme_mod( 'kentha_enable_secondlayer') || has_nav_menu( 'kentha_menu_offcanvas' )){ ?>
		<li class="right qt-3dswitch">
			<a href="#" id="qt3dswitch" data-3dfx class="qt-morphbtn right">
				<i>
					<span class="qt-top"></span>
					<span class="qt-middle"></span>
					<span class="qt-bottom"></span>
				</i>
			</a>
		</li>
		<?php } ?>
	</ul>
	<?php  
	if(get_theme_mod( 'kentha_breadcrumb')){
	?>
	<div class="qt-container-l">
		<?php get_template_part( 'phpincludes/breadcrumb' ); ?>
	</div>
	<?php } ?>
</nav>