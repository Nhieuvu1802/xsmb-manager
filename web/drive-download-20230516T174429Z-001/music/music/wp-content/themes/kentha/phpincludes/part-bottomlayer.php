<div id="qtLayerBottom" class="qt-layer-bottom qt-scrollbarstyle">
	<div class="qt-container qt-scrollbarstyle">
		<div class="row">
			<div class="col offset-s2 s10 offset-m4 m8 l6 offset-l6 <?php if(get_theme_mod( 'kentha_negative_secondlayer' )){ ?>qt-negative <?php } ?>">
				<?php


				/**
				 * Offcanvas menu
				 */
				if ( has_nav_menu( 'kentha_menu_offcanvas' ) ) {
					?>
					<ul class="qt-side-nav qt-menu-offc qt-dropdown-menu">
						<?php
						wp_nav_menu( array(
							'theme_location' => 'kentha_menu_offcanvas',
							'depth' => 3,
							'container' => false,
							'items_wrap' => '%3$s'
						));
						?>
					</ul>
					<?php  
				}
				

				/**
				 * Custom content set in customizer
				 */
				$content = get_theme_mod('kentha_secondlayer_content');
				if($content){
					if(isset($GLOBALS['wp_embed'])){
						$content = $GLOBALS['wp_embed']->autoembed($content);
					}
					echo wpautop (do_shortcode($content));
				}
				
				
				/**
				 * Widget area
				 */
				?>
				<div id="qtSidebarBottomlayer" class="qt-widgets qt-content-aside">
					<?php  
					if(is_active_sidebar( 'kentha-bottom-sidebar' ) ){
						dynamic_sidebar( 'kentha-bottom-sidebar' );
					}
					?>
				</div>
			</div>
		</div>
	</div>
</div>