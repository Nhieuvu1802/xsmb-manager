<?php
/**
 * @package    TGM-Plugin-Activation
 * @subpackage kentha
 **/


/**
 * Parse the updated list of orequired plugins from the private repository
 * @return [json] list of additional plugins from our server 
 */
function kentha_parse_plugins_update( $theme_version , $stored_optionname, $url ){

	if( !is_admin() ) { return; } // Because TGM class is acting pretty widely


	/**
	 * ================================================
	 * @since  2020 08 04
	 * Only update if I'm in the plugins screen
	 * ================================================
	 */
	$can_continue = true;
	
	if( false == $can_continue ){
		return;
	} else {
		add_action( 'admin_notices', 'kentha_plugins_refresh__outputtest' );
	}
	/**
	 * ================================================
	 */
	

	/**
	 * Overflow prevention
	 * @var integer
	 */
	$update_expiration = 15; // can refresh any 30 seconds
	if( '2' == get_transient( 'kentha_tgm_refreshed' ) ){
		add_action( 'admin_notices', 'kentha_tgm_remote_refreshed__message' );
		return( get_option( $stored_optionname ) );
	} else if( '1' == get_transient( 'kentha_tgm_refreshed' ) ) {
		set_transient( 'kentha_tgm_refreshed', '2', $update_expiration );
	} else {
		set_transient( 'kentha_tgm_refreshed', '1', $update_expiration );
	}
	

	/**
	 * Check stuff
	 */
	$iid = kentha_iid( true ); // force refresh
	
   
   
	 /**
	 * Make list request
	 */
	
	 $args = array(
		'method'        => 'POST',
		'timeout'       => 45,
		'redirection'   => 5,
		'httpversion'   => '1.0',
		'blocking'      => false,
		'user-agent'    => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:20.0) Gecko/20100101 Firefox/20.0',
		'headers'       => array(),
		'body'          => array(
			'iid'           => trim( esc_attr( $iid ) ),
			'site_host'     => get_site_url(),
			'act_key'       => esc_attr( get_option( 'kentha_ack_'. esc_attr( $iid ) ) ),
			'theme_version' => $theme_version
		),
	);
	$request = wp_remote_post(  $url , $args );

	// Validate received data
	
		
			$stored_plugins_list_json = $request['body'];
			$new_versioned_array = array(
				'theme_version'     => $theme_version,
				'plugins_list_json' => $stored_plugins_list_json
			);
			$new_plugins_list_versioned_json = json_encode( $new_versioned_array );
			$old = get_option(  $stored_optionname );
			if( $old ){
				delete_option( $stored_optionname );
			}
			
			add_action( 'admin_notices', 'kentha_plugins_refresh__success' );
			// prevent flooding
			return( get_option( $stored_optionname ) );
		
		 
	
	// if we arrive here, it means it's bad
	return false;
}


/**
 * Get the product ID from the server
 * @return [string] [the ID of the product]
 */
function kentha_iid( $force_refresh = false ){
 
	$id = get_option('kentha_product_id');
	$refresh = false;
	if(isset ($_GET)){
		if( array_key_exists('tgm-refresh-iid', $_GET ) ){
			$refresh = true;
		}
	}
	

	// id can be numeric or pending
	return '21048750';
}

