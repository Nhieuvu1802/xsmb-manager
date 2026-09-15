<?php  

/**
 * @package Kentha Ajax Pageload
 * @since  1.3.1
 * @author  QantumThemes
 * 
 * 
 */

if(!function_exists('qt_ajax_pageload_wc_endpoint_output')){
	add_action( 'wp_footer', 'qt_ajax_pageload_wc_endpoint_output' );
	function qt_ajax_pageload_wc_endpoint_output(){
		if ( class_exists( 'WooCommerce' ) ) {
			if ( function_exists( 'wc_get_endpoint_url' ) ) {
				$endpoints = array(
					'order-pay',
					'view-order',
					'edit-account',
					'edit-address',
					'lost-password',
					'customer-logout',
					'add-payment-method'
				);
				$urls = array();
				foreach ( $endpoints as $endpoint ){
					$urls[$endpoint] = wc_get_endpoint_url( $endpoint );
				}

				/**
				 * Shop page url
				 */
				$urls['shop'] = get_permalink( wc_get_page_id( 'shop' ) );
				?>
				<!-- QT AJAX PAGELOAD WOOCOMMERCE ENDPOINTS -->
				<div class="qt-hidden" id="qt-ajax-pageload-woocommerce-urls" style="display: none;" <?php  
					foreach( $urls as $key => $url ){
						echo ' data-endpoint-'.esc_attr( $key ).'="'.esc_attr( $url ).'"';
					}
					?> ></div>
				<!-- END OF QT AJAX PAGELOAD WOOCOMMERCE ENDPOINTS -->
				<?php

			}
		}
	}
}

/**
 * @since 1.3.1 [2019 12 02]
 * Reload scripts
 */

if(!function_exists('qt_ajax_pageload_wc_script_reload')){
	add_action( 'wp_footer', 'qt_ajax_pageload_wc_script_reload', 9999999 );
	function qt_ajax_pageload_wc_script_reload(){
		if ( class_exists( 'WooCommerce' ) ) {
			$wc_scripts_to_reload = array(
				'flexslider',
				'js-cookie',
				'jquery-blockui',
				'jquery-cookie',
				'jquery-payment',
				'photoswipe',
				'photoswipe-ui-default',
				'prettyPhoto',
				'prettyPhoto-init',
				'select2',
				'selectWoo',
				// 'wc-address-i18n',
				// 'wc-add-payment-method',
				'wc-cart',
				'wc-cart-fragments',
				// 'wc-checkout',
				// 'wc-country-select',
				// 'wc-credit-card-form',
				'wc-add-to-cart',
				'wc-add-to-cart-variation',
				// 'wc-geolocation',
				// 'wc-lost-password',
				// 'wc-password-strength-meter',
				'wc-single-product',
				'wc-price-slider',
				'kentha-price-slider',
				'woocommerce',
				'zoom',
			);

			// MAKE ARRAY
			$scripts_urls 	= array();
			$wp_scripts 	= wp_scripts(); 

			foreach ( $wc_scripts_to_reload as $wc_script ){
				$script = $wp_scripts->registered[ $wc_script ]; 
				$scripts_urls[ $wc_script ] = $script->src;
			}

			?>
			<!-- QT AJAX PAGELOAD WOOCOMMERCE SCRIPTS TO RELOAD -->
			<div class="qt-hidden" id="qt-ajax-pageload-woocommerce-scripts" style="display: none;" <?php  
				foreach( $scripts_urls as $key => $url ){
					echo ' data-script-'.esc_attr( $key ).'="'.esc_attr( $url ).'"';
				}
				?> ></div>
			<!-- END OF QT AJAX PAGELOAD WOOCOMMERCE SCRIPTS TO RELOAD -->
			<?php

		}
	}
}

