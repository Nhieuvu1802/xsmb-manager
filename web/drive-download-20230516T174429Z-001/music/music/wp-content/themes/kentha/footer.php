<?php
/*
Package: Kentha
*/
?>

			
		<div class="qt-footercontainer qt-content-primary-light">
			<?php 
			if(get_theme_mod('kentha_footer_widgets')){
				get_template_part('phpincludes/footerwidgets'); 
			}
			?>
			<div class="qt-footer-bottom qt-content-primary qt-content-aside qt-negative">
		    	<div class="qt-container-l">
		    		<div class="row">
						<div class="col s12 m12 l6">
							<?php 
							/**
							 * This function is in the kentha music player plugin
							 */
							if(function_exists('qt_musicplayer')){
								?><span class="qt-mplayer__btnspacer qt-btn qt-btn-xl hide-on-med-and-down"><i></i></span><?php
							}
							?>
							<ul class="qt-menu-social">
								<?php get_template_part('phpincludes/part-social'); ?>
						    </ul>
						</div>
						<div class="col s12 m12 l6">
						    <h5 class="qt-copyright-text"><?php echo html_entity_decode(wp_kses( get_theme_mod('kentha_footer_text') , array('a')) ); ?></h5>
							<ul class="qt-menu-footer qt-small">
								<?php
								if(has_nav_menu( 'kentha_menu_footer' )){
									wp_nav_menu( 
										array(
											'theme_location' => 'kentha_menu_footer',
											'depth' => 1,
											'container' => false,	
											'items_wrap' => '%3$s'
										)
									);
								}
								?>
							</ul>
						</div>
		    		</div>
		    	</div>
		    </div>
		</div>
	</div>

	<?php 

	/**
	 * Bottom secondary layer
	 */
	if(get_theme_mod( 'kentha_enable_secondlayer') ||  has_nav_menu( 'kentha_menu_offcanvas' )){
		get_template_part('phpincludes/part-bottomlayer' ); 
	}

	/**
	 * This function is in qt-musicplayer.php.
	 * Will need to go in a plugin probably
	 */
	if(function_exists('qt_musicplayer')){
		qt_musicplayer();
	}; 

	/**
	 * wp_footer function
	 */
	wp_footer(); 

	?>
	</body>
</html>
