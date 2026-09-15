<?php  
/**
 * Create customizer fields for the kirki framework.
 * @package Kirki
 */



/* = Global section
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_events_hideold',
	'label'       => esc_html__( 'Hide past events', "kentha" ),
	'section'     => 'kentha_global_settings',
	'description' => esc_html__( 'Based on the event date attribute', "kentha" ),
	'priority'    => 10,
   
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_loadmore',
	'label'       => esc_html__( '"Load More" pagination', "kentha" ),
	'section'     => 'kentha_global_settings',
	'description' => esc_html__( 'Display load more instead of pagination', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_introfx',
	'label'       => esc_html__( 'Intro effect header single pages', "kentha" ),
	'section'     => 'kentha_global_settings',
	'description' => esc_html__( 'use an intro effect while opening single pages in header', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_hq_parallax',
	'label'       => esc_html__( 'Hi-quality parallax', "kentha" ),
	'section'     => 'kentha_global_settings',
	'description' => esc_html__( 'Replace Page Builder parallax with Kentha hi quality parallax', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_breadcrumb',
	'label'       => esc_html__( 'Display breadcrumb', "kentha" ),
	'section'     => 'kentha_global_settings',
	'description' => esc_html__( 'Add a navigation breadcrumb to header', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_enable_debug',
	'label'       => esc_html__( 'Enable debug settings', "kentha" ),
	'description' => esc_html__( 'Load separated JS instead of minified version. Use in case of issues or custom javascript files', "kentha" ),
	'section'     => 'kentha_global_settings',
	'default'     => 0,
	'priority'    => 100
));

/* = Header section
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'image',
	'settings'    => 'kentha_logo_header',
	'label'       => esc_html__( 'Logo header', "kentha" ),
	'section'     => 'kentha_header_section',
	'description' => esc_html__( 'Height: 65px', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'radio',
	'settings'    => 'kentha_menu_style',
	'label'       => esc_html__( 'Menu style', "kentha" ),
	'section'     => 'kentha_header_section',
	'description' => esc_html__( 'Design for the menu and logo', "kentha" ),
	'priority'    => 10,
	'default'     => '0',
	'choices'     => array(
		'0'   => esc_attr__( 'Default', 'kentha' ),
		'1' => esc_attr__( 'Centered', 'kentha' ),
	),
));

/* = Website background
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'image',
	'settings'    => 'kentha_sitebg',
	'label'       => esc_html__( 'Default page background', "kentha" ),
	'section'     => 'kentha_website_bg_section',
	'description' => esc_html__( 'Global background. Suggested size 1600 x 900px', "kentha" ),
	'priority'    => 10
));

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'text',
	'settings'    => 'kentha_sitebg_video',
	'label'       => esc_html__( 'Default YouTube background (ID)', "kentha" ),
	'section'     => 'kentha_website_bg_section',
	'description' => esc_html__( 'Overwritten by single page\'s video background', "kentha" ),
	'priority'    => 10
));

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'checkbox',
	'settings'    => 'kentha_sitebg_fadeout',
	'label'       => esc_html__( 'Fade out background on scroll', "kentha" ),
	'section'     => 'kentha_website_bg_section',
	'description' => esc_html__( 'Background photo or video disappears on scroll.', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'slider',
	'settings'    => 'qt_darken_background',
	'label'       => esc_attr__( 'Darken page background', 'kentha' ),
	'section'     => 'kentha_website_bg_section',
	'default'     => '30',
	'priority'    => 12,
	'choices'     => array(
		'min'  => '0',
		'max'  => '90',
		'step' => '10',
	),
));
/* = Bottom layer
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_enable_secondlayer',
	'label'       => esc_html__( 'Enable second layer', "kentha" ),
	'section'     => 'kentha_bottomlayer_section',
	'description' => esc_html__( 'Add a secondary layer accessible from the menu icon', "kentha" ),
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_negative_secondlayer',
	'label'       => esc_html__( 'Negative colors', "kentha" ),
	'section'     => 'kentha_bottomlayer_section',
	'description' => esc_html__( 'Use for dark background or picture', "kentha" ),
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'image',
	'settings'    => 'kentha_bottomlayer_bg',
	'label'       => esc_html__( 'Bottom layer background', "kentha" ),
	'section'     => 'kentha_bottomlayer_section',
	'description' => esc_html__( 'Used for bottom layer if enabled. Suggested size 1600 x 900px', "kentha" ),
	'priority'    => 10
));
Kirki::add_field( 'kentha_config', array(
   	'type'        => 'editor',
   	'section'     => 'kentha_bottomlayer_section',
	'settings'    => 'kentha_secondlayer_content',
	'label'       => esc_html__( 'Second layer content', "kentha" ),
	'description' => esc_html__("Use html, images or shortcodes. No javascript! You can add widgets in Appearance > Wdgets","kentha"),
	'priority'    => 10,
));




/* = Footer section
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'text',
	'settings'    => 'kentha_footer_text',
	'label'       => esc_html__( 'Footer text', "kentha" ),
	'section'     => 'kentha_footer_section',
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'toggle',
	'settings'    => 'kentha_footer_widgets',
	'label'       => esc_html__( 'Show footer widgets', "kentha" ),
	'section'     => 'kentha_footer_section',
	'default'     => '1',
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'image',
	'settings'    => 'kentha_footer_backgroundimage',
	'label'       => esc_html__( 'Footer widgets background image', "kentha" ),
	'section'     => 'kentha_footer_section',
	'description' => esc_html__( 'JPG 1600x500px', "kentha" ),
	'priority'    => 10
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'checkbox',
	'settings'    => 'kentha_footer_parallax',
	'label'       => esc_html__( 'Footer background parallax effect', "kentha" ),
	'section'     => 'kentha_footer_section',
	'priority'    => 10
));


/* = Social section
=============================================*/
$qt_socicons_array = kentha_qt_socicons_array(); // functions.php
ksort($qt_socicons_array);
foreach ( $qt_socicons_array as $var => $val ){
	Kirki2_Kirki::add_field( 'kentha_config', array( 'settings' => 'kentha_social_'.$var, 'type' => 'text', 'label' => $val, 'section' => 'kentha_social_section',));
}




/* = Typography section
=============================================*/

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'typography',
	'settings'    => 'kentha_typography_text',
	'label'       => esc_html__( 'Basic ', "kentha" ),
	'section'     => 'kentha_typography',
	'default'     => array(
		'font-family'    => 'Open Sans',
		'variant'        => 'regular',
		'subsets'        => array( 'latin-ext' ),
	),
	'priority'    => 10,
	'output'      => array(
		array(
			'element' => 'body, html, .qt-side-nav.qt-menu-offc ul',
			'property' => 'font-family'
		),
	),
) );

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'typography',
	'settings'    => 'kentha_typography_text_bold',
	'label'       => esc_html__( 'Bold texts ', "kentha" ),
	'section'     => 'kentha_typography',
	'default'     => array(
		'font-family'    => 'Open Sans',
		'variant'        => '700',
		'subsets'        => array( 'latin-ext' ),
	),
	'priority'    => 10,
	'output'      => array(
		array(
			'element' => 'p strong, li strong, table strong',
			'property' => 'font-family'
		),
	),
) );

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'typography',
	'settings'    => 'kentha_typography_headings',
	'label'       => esc_html__( 'Headings', "kentha" ),
	'section'     => 'kentha_typography',
	'default'     => array(
		'font-family'    => 'Montserrat',
		'variant'        => '700',
		'letter-spacing' => '-0.03em',
		'subsets'        => array( 'latin-ext' ),
		'text-transform' => 'uppercase'
	),
	'priority'    => 10,
	'output'      => array(
		array(
			'element' => 'h1, h2, h3, h4, h5, h6, .qt-txtfx ',
			'property' => 'font-family'
		),
	),
) );

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'typography',
	'settings'    => 'kentha_typography_logo',
	'label'       => esc_html__( 'Website title', "kentha" ),
	'section'     => 'kentha_typography',
	'default'     => array(
		'font-family'    => 'Montserrat',
		'variant'        => '700',
		'letter-spacing' => '-0.03em',
		'subsets'        => array( 'latin-ext' ),
		'text-transform' => 'uppercase'
	),
	'priority'    => 10,
	'output'      => array(
		array(
			'element' => '.qt-logo-link',
			'property' => 'font-family'
		),
	),
) );


Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'typography',
	'settings'    => 'kentha_typography_menu',
	'label'       => esc_html__( 'Menu, buttons and metas', "kentha" ),
	'section'     => 'kentha_typography',
	'default'     => array(
		'font-family'    => 'Montserrat',
		'variant'        => '400',
		'letter-spacing' => '0.03em',
		'subsets'        => array( 'latin-ext' ),
		'text-transform' => 'uppercase'
	),
	'priority'    => 10,
	'output'      => array(
		array(
			'element' => '.woocommerce #respond input#submit, .woocommerce a.button, .woocommerce button.button, .woocommerce input.button, .qt-desktopmenu, .qt-side-nav, .qt-menu-footer, .qt-capfont, .qt-details, .qt-capfont-thin, .qt-btn, a.qt-btn,.qt-capfont strong, .qt-item-metas, button, input[type="button"], .button',
			'property' => 'font-family'
		),
	),
));




/* = Colors section
=============================================*/

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_primary_color',
	'label'       => esc_html__( 'Primary', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#454955',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_primary_color_light',
	'label'       => esc_html__( 'Primary light', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#565c68',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_primary_color_dark',
	'label'       => esc_html__( 'Primary dark', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#101010',
	'priority'    => 0
));

Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_textcolor_primary',
	'label'       => esc_html__( 'Text color on primary', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#fff',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_accent',
	'label'       => esc_html__( 'Accent', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#00ced0',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_accent_hover',
	'label'       => esc_html__( 'Accent hover', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#00fcff',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_secondary',
	'label'       => esc_html__( 'Secondary', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#ff0d51',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_secondary_hover',
	'label'       => esc_html__( 'Secondary hover', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#c60038',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_textcolor_on_buttons',
	'label'       => esc_html__( 'Text color on accent and secondary (as buttons)', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#fff',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_background',
	'label'       => esc_html__( 'Page background', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#444',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_color_paper',
	'label'       => esc_html__( 'Paper background', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#131617',
	'priority'    => 0,
	'choices'     => array(
        'alpha' => true,
    ),
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_textcolor_original',
	'label'       => esc_html__( 'Text', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#fff',
	'priority'    => 0
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'color',
	'settings'    => 'kentha_textcolor_menu',
	'label'       => esc_html__( 'Menu text', "kentha" ),
	'section'     => 'kentha_colors_section',
	'default'     => '#fff',
	'priority'    => 0
));





/* = WooCommerce section
=============================================*/
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'radio',
	'settings'    => 'kentha_woocommerce_design',
	'label'       => esc_html__( 'Shop layout', "kentha" ),
	'section'     => 'kentha_woocommerce',
	'description' => esc_html__( 'Design for the shop page', "kentha" ),
	'priority'    => 10,
	'default'     => 'left-sidebar',
	'choices'     => array(
		'left-sidebar'   => esc_attr__( 'Left sidebar', 'kentha' ),
		'right-sidebar' => esc_attr__( 'Right sidebar', 'kentha' ),
		'fullpage' => esc_attr__( 'Full width', 'kentha' ),

	),
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'switch',
	'settings'    => 'kentha_woocommerce_singletrack_enable',
	'label'       => esc_html__( 'Enable the single track shop features', "kentha" ),
	'section'     => 'kentha_woocommerce',
	'description' => esc_html__( 'Will enable the custom fields for single products, royalty taxonomy, and genres features. This feature is to create a royalty free music shop, a music samples shop or a shadow producer shop.', "kentha" ),
	'priority'    => 10,
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'radio',
	'settings'    => 'kentha_woocommerce_design_genres',
	'label'       => esc_html__( 'Genres and royalty archive layout', "kentha" ),
	'section'     => 'kentha_woocommerce',
	'description' => esc_html__( 'If set to tracklist, your "products genre" and "product royalty" archives will display only the products with the "single track" attribute enabled. Every other product will be hidden.', "kentha" ),
	'priority'    => 10,
	'default'     => '',
	'choices'     => array(
		''   => esc_attr__( 'Default', 'kentha' ),
		'tracklist' => esc_attr__( 'Tracklist', 'kentha' ),
	),
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'radio',
	'settings'    => 'kentha_woocommerce_design_shop',
	'label'       => esc_html__( 'Global shop layout', "kentha" ),
	'section'     => 'kentha_woocommerce',
	'description' => esc_html__( 'If set to tracklist, any shop archive will display as tracklist. Every other product not marked as "single track" will be hidden.', "kentha" ),
	'priority'    => 10,
	'default'     => '',
	'choices'     => array(
		''   => esc_attr__( 'Default', 'kentha' ),
		'tracklist' => esc_attr__( 'Tracklist', 'kentha' ),
	),
));




/* = Player section // Products "single track" 

REQUIRES THE SINGLE TRACK OPTION TO BE ENABLED 

=============================================*/
if ( class_exists( 'WooCommerce' ) ) {
	if( get_theme_mod('kentha_woocommerce_singletrack_enable') ){
		Kirki::add_field( 'kentha_config', array(
			'type'     => 'text',
			'settings' => 'kentha_player_prodfeatured',
			'label'    => __( 'Featured products by ID', 'kentha' ),
			'section'  => 'kentha_player_products',
			'description'  => esc_attr__( 'Add one or more products to the player by ID, comma separated (34,56,92).', 'kentha' ),
			'priority' => 10,
		));
		Kirki2_Kirki::add_field( 'kentha_config', array(
			'type'        => 'slider',
			'settings'    => 'kentha_player_prodamount',
			'label'       => esc_attr__( 'Max products preload amount', 'kentha' ),
			'section'     => 'kentha_player_products',
			'default'     => '1',
			'priority'    => 10,
			'description'  => esc_attr__( 'Minimum 1 including the featured products', 'kentha' ),
			'choices'     => array(
				'min'  => '1',
				'max'  => '30',
				'step' => '1',
			),
		));
	}
}

/* = Player section // Album releases
=============================================*/
Kirki::add_field( 'kentha_config', array(
	'type'     => 'text',
	'settings' => 'kentha_player_releasefeatured',
	'label'    => __( 'Featured albums by ID', 'kentha' ),
	'section'  => 'kentha_player_albums',
	'description'  => esc_attr__( 'Add one or more album to the player by ID, comma separated (34,56,92).', 'kentha' ),
	'priority' => 10,
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'slider',
	'settings'    => 'kentha_player_releaseamount',
	'label'       => esc_attr__( 'Max album preload amount', 'kentha' ),
	'section'     => 'kentha_player_albums',
	'default'     => '1',
	'priority'    => 10,
	'description'  => esc_attr__( 'A large number of items may slow down your website.', 'kentha' ),
	'choices'     => array(
		'min'  => '0',
		'max'  => '10',
		'step' => '1',
	),
));



/* = Player section // Podcasts
=============================================*/
Kirki::add_field( 'kentha_config', array(
	'type'     => 'text',
	'settings' => 'kentha_player_podcastfeatured',
	'label'    => __( 'Featured podcasts by ID [ONLY MP3 PODCAST]', 'kentha' ),
	'section'  => 'kentha_player_podcasts',
	'description'  => esc_attr__( 'Add one or more podcasts to the player by ID, comma separated (34,56,92).', 'kentha' ),
	'priority' => 10,
));
Kirki2_Kirki::add_field( 'kentha_config', array(
	'type'        => 'slider',
	'settings'    => 'kentha_player_podcastamount',
	'label'       => esc_attr__( 'Max podcast preload amount [ONLY MP3 PODCAST]', 'kentha' ),
	'section'     => 'kentha_player_podcasts',
	'default'     => '1',
	'priority'    => 10,
	'description'  => esc_attr__( 'A large number of items may slow down your website.', 'kentha' ),
	'choices'     => array(
		'min'  => '0',
		'max'  => '30',
		'step' => '1',
	),
));

/* = Player section // Custom playlist
=============================================*/


Kirki::add_field( 'kentha_config', array(
	'type'        => 'repeater',
	'label'       => esc_attr__( 'Custom playlist tracks', 'kentha' ),
	'section'     => 'kentha_player_playlist',
	'priority'    => 10,
	'row_label' => array(
		'type'  => 'field',
		'value' => esc_attr__('Track', 'kentha' ),
		'field' => 'title',
	),
	'button_label' => esc_attr__('Add new track', 'kentha' ),
	'settings'     => 'kentha_custom_playlist',
	'fields' => array(
		'title' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Title', 'kentha' ),
		),
		'artist' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Artist', 'kentha' ),
		),
		'album' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Album name', 'kentha' ),
		),
		'buylink' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Purchase link or WooCommerce ID', 'kentha' ),
		),
		'price' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Price', 'kentha' ),
		),
		'icon' => array(
			'type'        => 'radio',
			'label'       => esc_attr__( 'Icon', 'kentha' ),
			'default'     => 'download',
			'choices'     => array(
				'download'   => esc_attr__( 'download', 'kentha' ),
				'cart' => esc_attr__( 'cart', 'kentha' ),
			),
		),
		'link' => array(
			'type'        => 'text',
			'label'       => esc_attr__( 'Album link', 'kentha' ),
		),
		'sample' => array(
			'type'        => 'upload',
			'label'       => esc_attr__( 'Track mp3', 'kentha' ),
			'mime_type'	  => array('audio/mpeg','audio/mpeg','audio/mpg','audio/x-mpeg','audio/mp3','application/force-download','application/octet-stream')
		),
		'art' => array(
			'type'        => 'image',
			'label'       => esc_attr__( 'Artwork cover', 'kentha' ),
		),
	)
) );



