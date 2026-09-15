<?php
/*
Package: Kentha
*/
?>
<?php if ( has_nav_menu( 'kentha_menu_primary' ) ) { ?>
<span id="qwMenuToggle" data-activates="qt-mobile-menu" class="qt-menuswitch button-collapse qt-btn qt-btn-xl left">
	<i class='material-icons'>
	  menu
	</i>
</span>
<?php } ?>
<a class="qt-logo-text" href="<?php echo esc_url( home_url( '/' ) ); ?>"><?php
	/**  Logo or title
	 *  ============================================= */
	$logo = get_theme_mod("kentha_logo_header", '');
	if($logo != ''){
		echo '<img src="'.esc_url($logo).'" alt="'.esc_attr__("Home","kentha").'">';
	}else{
		?><h2><?php echo get_bloginfo('name');?></h2><?php  
	}
?></a>
<?php if(get_theme_mod( 'kentha_enable_secondlayer') || has_nav_menu( 'kentha_menu_offcanvas' )){ ?>
<span id="qt3dswitchmob" data-3dfx class="qt-btn qt-btn-xl right">
	<i class='material-icons'>
	  chevron_right
	</i>
</span>
<?php } ?>