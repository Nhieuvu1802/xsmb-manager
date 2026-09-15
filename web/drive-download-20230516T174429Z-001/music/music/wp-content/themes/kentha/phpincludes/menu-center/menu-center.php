<?php
/*
Package: Kentha
*/
?>
<nav class="qt-menubar qt-menubar-center nav-wrapper hide-on-xl-and-down" >
	<?php
	if ( has_nav_menu( 'kentha_menu_primary' ) ) {
		?>
	<div class="qt-content-primary-dark qt-menubg-color">
		<?php
		/**
		 * This is an empty div needed to provide background color while scrolling
		 */
		 ?>
	</div>
	<?php } ?>
	<div class="qt-container-l">
		<ul class="qt-menu-secondary">
			<li class="qt-3dswitch">
				<?php if(get_theme_mod( 'kentha_enable_secondlayer') || has_nav_menu( 'kentha_menu_offcanvas' )){ ?>
				<a href="#" id="qt3dswitch" data-3dfx class="qt-morphbtn">
					<i>
						<span class="qt-top"></span>
						<span class="qt-middle"></span>
						<span class="qt-bottom"></span>
					</i>
				</a>
				<?php } ?>
			</li>
			<li class="qt-centerlogo">
				<span>
					<a href="<?php echo esc_url( home_url( '/' ) ); ?>" class="qt-logo-link qt-fontsize-h3"><?php
						/**  Logo or title
						 *  ============================================= */
						$logo = get_theme_mod("kentha_logo_header","");
						if($logo != ''){
							echo '<img src="'.esc_attr($logo).'" alt="'.esc_attr__("Home","kentha").'">';
						}else{
							?><?php echo get_bloginfo('name');?><?php
						}
					?></a>
				</span>
			</li>
			<?php get_template_part('phpincludes/part-social-and-count');  ?>
		</ul>
	</div>
	<?php
	if ( has_nav_menu( 'kentha_menu_primary' ) ) {
		?>
		<ul class="qt-desktopmenu">
		<?php 
		wp_nav_menu( array(
			'theme_location' => 'kentha_menu_primary',
			'depth' => 3,
			'container' => false,
			'items_wrap' => '%3$s'
		));
		?>
		</ul>
		<?php  
	}
	?>
	<?php  
	if(get_theme_mod( 'kentha_breadcrumb')){
	?>
	<div class="qt-container-l">
		<?php get_template_part( 'phpincludes/breadcrumb' ); ?>
	</div>
	<?php } ?>
</nav>