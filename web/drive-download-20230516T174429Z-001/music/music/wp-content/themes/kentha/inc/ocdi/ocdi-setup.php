<?php
/**
 * 
 * @package WordPress
 * @subpackage One Click Demo Import
 * @subpackage kentha
 * @version 1.0.0
 * Settings for the demo import
 * https://wordpress.org/plugins/one-click-demo-import/
 * 
*/

add_filter( 'pt-ocdi/regenerate_thumbnails_in_content_import', '__return_false' );
add_filter( 'pt-ocdi/disable_pt_branding', '__return_true' );


/**
 * Disable thumbnail generation during import or it takes ages
 */
add_filter( 'pt-ocdi/regenerate_thumbnails_in_content_import', '__return_false' );

/**
 * Customize the popup width
 */
function kentha_ocdi_confirmation_dialog_options ( $options ) {
    return array_merge( $options, array(
        'width'       => 400,
        'dialogClass' => 'wp-dialog',
        'resizable'   => false,
        'height'      => 'auto',
        'modal'       => true,
    ) );
}
add_filter( 'pt-ocdi/confirmation_dialog_options', 'kentha_ocdi_confirmation_dialog_options', 10, 1 );

/**
 * Customize the popup width
 */
function kentha_ocdi_plugin_intro_text( $default_text ) {
    $default_text .= '<h2>Welcome to the Kentha Demo Import.</h2>';
     $default_text .= '<p style="font-size:19px;">Please remember that <strong style="color: red">WooCommerce demos 9 and 10</strong>  will appear only after installing the WooCommerce plugin.</p><br><br><br>';
    return $default_text;
}
add_filter( 'pt-ocdi/plugin_intro_text', 'kentha_ocdi_plugin_intro_text' );






function kentha_ocdi_import_files() {
	$url = 'https://qantumthemes.xyz/t2gconnector-comm/kentha/demodata-20190626/';
	$demos = array(
		array(
			'import_file_name'           => 'Demo 0 Music multipurpose',
			'categories'                 => array( 'Electronic', 'Multi artist', 'Music Mag', 'EDM' ),
			'import_file_url'            => $url.'demo0/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo0/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo0/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 0.1 Music Multipurpose, 0.2 Music Artist, 0.3 Magazine, 0.4 EDM', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo0/',
			'import_preview_image_url'	 => $url.'demo0/preview.jpg',
		),
		// Demo 1
		array(
			'import_file_name'           => 'Demo 1 Retrowave',
			'categories'                 => array( 'Electronic', 'RetroWave', '80s', 'Multi artist', 'Music Mag', 'DJ' ),
			'import_file_url'            => $url.'demo1/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo1/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo1/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 1.1 Neon 80s, 1.2 80s Mag, 1.3 80s RetroWave Label', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo1/',
			'import_preview_image_url'	 => $url.'demo1/preview.jpg',
		),
		// Demo 2
		array(
			'import_file_name'           => 'Demo 2 Underground',
			'categories'                 => array( 'Electronic', 'Underground', 'DJ', 'Techno', 'Music Mag', 'Tour', 'Producer', 'Promo album'),
			'import_file_url'            => $url.'demo2/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo2/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo2/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 2.1 Underground DJ, 2.2 Techno, 2.3 Underground Mag', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo2/',
			'import_preview_image_url'	 => $url.'demo2/preview.jpg',
		),
		// Demo 3
		array(
			'import_file_name'           => 'Demo 3 Classical',
			'categories'                 => array( 'Classic music', 'Tour', 'Musician', 'Single artist', 'Promo album' ),
			'import_file_url'            => $url.'demo3/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo3/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo3/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 3.1 Classical, 3.2 Classic Album, 3.3 Classic Tour', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo3/',
			'import_preview_image_url'	 => $url.'demo3/preview.jpg',
		),
		
		// Demo 4
		array(
			'import_file_name'           => 'Demo 4 Hipster',
			'categories'                 => array( 'Single artist', 'Musician', 'Tour', 'Blog', 'Promo album', 'Hipster' ),
			'import_file_url'            => $url.'demo4/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo4/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo4/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 4.1 Hipster, 4.2 Hipster musician, 4.3 Hipster blog', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo4/',
			'import_preview_image_url'	 => $url.'demo4/preview.jpg',
		),


		// Demo 5
		array(
			'import_file_name'           => 'Demo 5 Metal',
			'categories'                 => array( 'Metal', 'Band', 'Rock', 'Single artist','Multi artist', 'Tour', 'Promo album' ),
			'import_file_url'            => $url.'demo5/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo5/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo5/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 5.1 Metal Band, 5.2 Metal Tour, 5.3 Metal Album Promo', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo5/',
			'import_preview_image_url'	 => $url.'demo5/preview.jpg',
		),
		// Demo 6
		array(
			'import_file_name'           => 'Demo 6 Club and Festival',
			'categories'                 => array( 'Electronic', 'EDM', 'Festival', 'Multi artist', 'Event' ),
			'import_file_url'            => $url.'demo6/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo6/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo6/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 6.1 Club & Festival, 6.2 Festival Blog, 6.3 Festival Alternative', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo6/',
			'import_preview_image_url'	 => $url.'demo6/preview.jpg',
		),
		// Demo 7
		array(
			'import_file_name'           => 'Demo 7 Country',
			'categories'                 => array( 'Country', 'Single artist', 'Promo album', 'Tour' ),
			'import_file_url'            => $url.'demo7/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo7/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo7/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages ', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo7/',
			'import_preview_image_url'	 => $url.'demo7/preview.jpg',
		),
		// Demo 8
		array(
			'import_file_name'           => 'Demo 8 Album Landing Page',
			'categories'                 => array( 'Single artist', 'Promo album', 'Electronic', 'EDM', 'Hipster' ),
			'import_file_url'            => $url.'demo8/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo8/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo8/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo page 8.0 Album Landing Page', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo8/',
			'import_preview_image_url'	 => $url.'demo8/preview.jpg',
		),	
	);
	
	if ( class_exists( 'WooCommerce' ) ) {
		// Demo 9, only if WooCommerce is active
		$demos[] = array(
			'import_file_name'           => 'Demo 9 Shop',
			'categories'                 => array( 'Shop', 'Promo album', 'Electronic', 'EDM', 'Hipster','Single artist', 'Festival', 'Multi artist', 'Event', 'Metal', 'Band', 'Rock',  'Classic music', 'Electronic', 'Underground', 'DJ', 'Techno', 'Music Mag', 'Tour', 'Producer'  ),
			'import_file_url'            => $url.'demo9/kentha.WordPress.xml',
			'import_widget_file_url'     => $url.'demo9/kentha.qantumthemes.xyz-installer-widgets.wie',
			'import_customizer_file_url' => $url.'demo9/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains the demo pages 9.0 WooCommerce Shop, 9.1 Music Shop, 9.2 Artist Shop', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo9/',
			'import_preview_image_url'	 => $url.'demo9/preview.jpg',
		);

		$demos[] = array(
			'import_file_name'           => 'Demo 10 Ghost Tracks',
			'categories'                 => array( 'Shop', 'ghost tracks','royalty free','loops','samples','Promo album', 'Electronic', 'EDM', 'Hipster','Single artist', 'Festival', 'Multi artist', 'Event', 'Metal', 'Band', 'Rock',  'Classic music', 'Electronic', 'Underground', 'DJ', 'Techno', 'Music Mag', 'Tour', 'Producer'  ),
			'import_file_url'            => $url.'demo10/kentha.WordPressC.xml',
			'import_widget_file_url'     => $url.'demo10/qantumthemes.xyz-kentha-demo10-widgets.wie',
			'import_customizer_file_url' => $url.'demo10/kentha-child-export.json', // dat extension triggers security restrictions
			'import_notice'              => esc_html__( 'Contains HOME 01 – AUDIO JUNGLA, HOME 02 – GHOST TRACKS, HOME 03 – PREMIUM BEAT, HOME 04 – ROYALTY FREE, HOME 05 – SHOP GENERIC, HOME 06 – SAMPLES', 'kentha' ),
			'preview_url'                => 'https://qantumthemes.xyz/kentha/demo10/',
			'import_preview_image_url'	 => $url.'demo10/preview.jpg',
		);
	}
	return $demos;
}
add_filter( 'pt-ocdi/import_files', 'kentha_ocdi_import_files' );





function kentha_ocdi_after_import_setup( $selected_import ) {

	// use the name of the selected import
	$demo_name =  $selected_import['import_file_name'];

	if ( 'Demo 0 Music multipurpose' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home' );
	}
	elseif ( 'Demo 1 Retrowave' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Primary', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Homepage' );
	}
	elseif ( 'Demo 2 Underground' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$offcanvas_menu = get_term_by( 'name', 'Off', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home v1' );
	}
	elseif ( 'Demo 3 Classical' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home V1' );
	}
	elseif ( 'Demo 4 Hipster' === $demo_name ) {
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$offcanvas_menu = get_term_by( 'name', 'Nav', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home' );
	}
	elseif ( 'Demo 5 Metal' === $demo_name ) {
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$offcanvas_menu = get_term_by( 'name', 'Primary', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Homepage' );
	}
	elseif ( 'Demo 6 Club and Festival' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home' );
	}
	elseif ( 'Demo 7 Country' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Primary', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Homepage' );
	}
	elseif ( 'Demo 8 Album Landing Page' === $demo_name ) {
		$front_page_id = get_page_by_title( 'Homepage' );
	}
	elseif ( 'Demo 9 Shop' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home Shop V1' );
	}
	elseif ( 'Demo 10 Ghost Tracks' === $demo_name ) {
		$primary_menu = get_term_by( 'name', 'Main Menu', 'nav_menu' );
		$footer_menu = get_term_by( 'name', 'Footer', 'nav_menu' );
		$front_page_id = get_page_by_title( 'Home 01' );
	}

	

	/**
	 * 
	 * Set the home
	 * 
	 */
	update_option( 'show_on_front', 'page' );
	update_option( 'page_on_front', $front_page_id->ID );

	/**
	 * 
	 * Set the menus
	 * 
	 */
	$menus = array();
	if( isset( $primary_menu ) ){
		echo '<h1>primary_menu</h1>';
		print_r($primary_menu);
		$menus['kentha_menu_primary'] = $primary_menu->term_id;
	}
	if( isset( $footer_menu ) ){
		echo '<h1>footer_menu</h1>';
		print_r($footer_menu);
		$menus['kentha_menu_footer'] = $footer_menu->term_id;
	}
	if( isset( $offcanvas_menu ) ){
		echo '<h1>offcanvas_menu</h1>';
		print_r($offcanvas_menu);
		$menus['kentha_menu_offcanvas'] = $offcanvas_menu->term_id;
	}

	if( count( $menus ) >= 1 ){ // If my array has items, set them
		set_theme_mod( 'nav_menu_locations', $menus );
	}

}
add_action( 'pt-ocdi/after_import', 'kentha_ocdi_after_import_setup' );