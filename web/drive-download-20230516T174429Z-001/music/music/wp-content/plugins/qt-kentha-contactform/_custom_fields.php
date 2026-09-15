<?php 
add_action('init', 'qt_kentha_contactform_fields');  
if(!function_exists('qt_kentha_contactform_fields')){
function qt_kentha_contactform_fields() {
	$contactform_fields = array(
		array(
			'label' => esc_html__( 'Contact form recipient email', "kentha" ),
			'desc'	=> esc_html__( 'Compile to enable contact form', 'kentha' ),
			'id'    => 'qt_contacts_recipient',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Privacy page URL', "kentha" ),
			'desc'	=> esc_html__( 'Privacy checkbox will appear if compiled', 'kentha' ),
			'id'    => 'qt_contacts_privacy',
			'type'  => 'text'
			),
	);
	if( class_exists('custom_add_meta_box')) {
		$artist_tab_data = new custom_add_meta_box( 'artist_contactform', 'Contact form', $contactform_fields, 'artist', true );
	}
}}