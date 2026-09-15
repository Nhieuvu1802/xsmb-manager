<?php
/**
 * @package    TGM-Plugin-Activation
 * @subpackage kentha
 **/

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

add_action( 'tgmpa_register', 'kentha_register_required_plugins' );
function kentha_register_required_plugins() {


	if(!is_admin()){
		return;
	}

	$plugins = kentha_default_plugins_list();

	$additional_plugins = kentha_get_pluginslist( kentha_additional_plugins_url() );
	if( $additional_plugins ){
		$plugins = array_merge (
			$additional_plugins,
			$plugins
		);
	}

	if( is_array( $plugins ) ) {

		if( count( $plugins ) > 0 ) {
			$config = array(
				'id'           => 'kentha',
				'default_path' => '',
				'menu'         =>  kentha_tgmpa_page(),
				'parent_slug'  => 'themes.php',
				'capability'   => 'edit_theme_options',
				'has_notices'  => true,
				'dismissable'  => true,
				'dismiss_msg'  => '',
				'is_automatic' => true,
				'message'      => kentha_message_tgm()
			);
			tgmpa( $plugins, $config );
		} else {
			// It seems that something is wrong, let's display a link to refresh this
			add_action( 'admin_notices', 'kentha_plugins_notice__refresh' );
		}
	} else {
		 add_action( 'admin_notices', 'kentha_plugins_notice__nolist' );
	}

}