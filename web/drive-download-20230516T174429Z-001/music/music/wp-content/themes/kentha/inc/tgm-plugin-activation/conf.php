<?php  
if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

add_action( 'vc_before_init', 'qtt_vcSetAsTheme' );
function qtt_vcSetAsTheme() {
  vc_set_as_theme();
}


function kentha_additional_plugins_url(){
	return 'http://qantumthemes.xyz/t2gconnector-comm/kentha/tgm-json/';
}
function kentha_tgm_iid_url(){
	return 'http://qantumthemes.xyz/t2gconnector-comm/kentha/iid/';
}
function kentha_connector_url(){
	return 'http://qantumthemes.xyz/t2gconnector-comm/connector-proxy/';
}
function kentha_connector_documentation_url(){
	return 'https://qantumthemes.xyz/manuals/kentha/';
}
function kentha_support_message(){
	return 'Please contact us via <a href="https://qantumthemes.xyz/manuals/kentha/knowledge-base/support/" target="_blank">HelpDesk</a> https://qantumthemes.xyz/manuals/kentha/knowledge-base/support/';
}
function kentha_tgmpa_page(){
	return 'kentha-install-plugins';
}
/**
 * This is the list of plugins used by TGM
 * It can be extended by our repository list which can be fetched dynamically.
 */
function kentha_default_plugins_list(){
	return array(
		array(
	        'name'     			 => esc_html__('Theme Core Plugin', 'kentha' ),
	        'slug'     			 => 'ttg-core',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/ttg-core.zip',
	        'version'			 => '1.3.5'
		),
		array(
	        'name'     			 => esc_html__('WPbakery Page Builder', 'kentha' ),
	        'slug'     			 => 'js_composer',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/js_composer.zip',
	        'version'			 => '6.4.0'
		),
		array(
	        'name'     			 => esc_html__('Envato Market', 'kentha' ),
	        'slug'     			 => 'envato-market',
	        'required'           => false,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/envato-market.zip',
	        'version'			 => '2.0.5'
		),
		array(
	        'name'     			 => esc_html__('MailChimp for WordPress', 'kentha' ),
	        'slug'     			 => 'mailchimp-for-wp',
	        'required'           => false,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/mailchimp-for-wp.zip',
	        'version'			 => '4.8.1'
		),
		array(
	        'name'     			 => esc_html__('One Click Demo Import', 'kentha' ),
	        'slug'     			 => 'one-click-demo-import',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/one-click-demo-import.zip',
	        'version'			 => '2.6.1'
		),
		array(
	        'name'     			 => esc_html__('QT Chart Voting', 'kentha' ),
	        'slug'     			 => 'qt-chartvote',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-chartvote.zip',
	        'version'			 => '1.2'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha Ajax page loading for nonstop music', 'kentha' ),
	        'slug'     			 => 'qt-kentha-ajax-pageload',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-kentha-ajax-pageload.zip',
	        'version'			 => '1.3.3'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha ContactForm', 'kentha' ),
	        'slug'     			 => 'qt-kentha-contactform',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-kentha-contactform.zip',
	        'version'			 => '1.0.3'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha Player', 'kentha' ),
	        'slug'     			 => 'qt-kenthaplayer',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-kenthaplayer.zip',
	        'version'			 => '2.2.7'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha Share', 'kentha' ),
	        'slug'     			 => 'qt-kentha-share',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-kentha-share.zip',
	        'version'			 => '1.1.0'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha Website Preloader', 'kentha' ),
	        'slug'     			 => 'qt-kentha-preloader',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-kentha-preloader.zip',
	        'version'			 => '1.0.0'
		),
		array(
	        'name'     			 => esc_html__('QT Kentha Widgets', 'kentha' ),
	        'slug'     			 => 'kentha-widgets',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/kentha-widgets.zip',
	        'version'			 => '1.0.7'
		),
		array(
	        'name'     			 => esc_html__('QT Places', 'kentha' ),
	        'slug'     			 => 'qt-places',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-places.zip',
	        'version'			 => '1.8.2'
		),
		array(
	        'name'     			 => esc_html__('QT Swipebox', 'kentha' ),
	        'slug'     			 => 'qt-swipebox',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/qt-swipebox.zip',
	        'version'			 => '2.1'
		),
		array(
	        'name'     			 => esc_html__('Slider Revolution', 'kentha' ),
	        'slug'     			 => 'revslider',
	        'required'           => true,
	        'source'			 => get_template_directory_uri() . '/inc/tgm-plugin-activation/plugins/revslider.zip',
	        'version'			 => '5.4.8.2.1'
		),
	);
}