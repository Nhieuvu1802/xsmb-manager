<?php
add_action('init', 'kentha_event_register_type');  
if(!function_exists('kentha_event_register_type')){
function kentha_event_register_type() {
	$labelsevent = array(
        'name' => esc_html__("Event",'kentha'),
        'singular_name' => esc_html__("Event",'kentha'),
        'add_new' => esc_html__("Add new",'kentha'),
        'add_new_item' => esc_html__("Add new event",'kentha'),
        'edit_item' => esc_html__("Edit event",'kentha'),
        'new_item' => esc_html__("New event",'kentha'),
        'all_items' => esc_html__("All events",'kentha'),
        'view_item' => esc_html__("View event",'kentha'),
        'search_items' => esc_html__("Search event",'kentha'),
        'not_found' => esc_html__("No events found",'kentha'),
        'not_found_in_trash' => esc_html__("No events found in trash",'kentha'),
        'menu_name' => esc_html__("Events",'kentha')
    );
  	$args = array(
        'labels' => $labelsevent,
        'public' => true,
        'publicly_queryable' => true,
        'show_ui' => true, 
        'show_in_menu' => true, 
        'query_var' => true,
        'rewrite' => true,
        'capability_type' => 'page',
        'has_archive' => true,
        'hierarchical' => false,
        'menu_position' => 40,
        'menu_icon' => 'dashicons-calendar-alt',
    	'page-attributes' => true,
    	'show_in_nav_menus' => true,
    	'show_in_admin_bar' => true,
    	'show_in_menu' => true,
    	'show_in_rest' => true,
        'supports' => array('title','thumbnail','editor','page-attributes'/*,'post-formats'*/)
  	); 
  	if (function_exists('ttg_custom_post_type')){
    	ttg_custom_post_type( "event" , $args );
    }
	$labels = array(
		'name' => esc_html__( 'Event type','kentha' ),
		'singular_name' => esc_html__( 'Types','kentha' ),
		'search_items' =>  esc_html__( 'Search by genre','kentha' ),
		'popular_items' => esc_html__( 'Popular genres','kentha' ),
		'all_items' => esc_html__( 'All events','kentha' ),
		'parent_item' => null,
		'parent_item_colon' => null,
		'edit_item' => esc_html__( 'Edit Type','kentha' ), 
		'update_item' => esc_html__( 'Update Type','kentha' ),
		'add_new_item' => esc_html__( 'Add New Type','kentha' ),
		'new_item_name' => esc_html__( 'New Type Name','kentha' ),
		'separate_items_with_commas' => esc_html__( 'Separate Types with commas','kentha' ),
		'add_or_remove_items' => esc_html__( 'Add or remove Types','kentha' ),
		'choose_from_most_used' => esc_html__( 'Choose from the most used Types','kentha' ),
		'menu_name' => esc_html__( 'Event types','kentha' ),
	); 
	$args =array(
		'hierarchical' => true,
		'labels' => $labels,
		'show_ui' => true,
		'update_count_callback' => '_update_post_term_count',
		'query_var' => true,
		'show_in_rest' => true,
		'rewrite' => array( 'slug' => 'eventtype' ),
	);
	if(function_exists('ttg_custom_taxonomy')){
		ttg_custom_taxonomy('eventtype','event',$args	);
	}

	$event_meta_boxfields = array(
		array(
			'label' => esc_html__( 'Logo', "kentha" ),
			'id'    => 'qt_page_logo',
			'desc'	=> esc_html__( 'It will replace the page title', 'kentha' ),
			'type'  => 'image'
			),
	    array(
			'label' => esc_html__('Date', 'kentha'),
			'id'    =>  'eventdate',
			'type'  => 'date'
		),
		array(
			'label' => esc_html__('Time (24h format)', "kentha"),
			'id'    =>  'eventtime',
			'type'  => 'time'
		),
		array(
			'label' => esc_html__('Facebook Event Link', 'kentha'),
			'id'    => 'eventfacebooklink',
			'type'  => 'text'
		),
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__('Ticket Buy Links', 'kentha'), // <label>
			'desc'	=> 'Add one for each link to external websites',esc_html__('Street', 'kentha') ,// description
			'id'	=> 'eventrepeatablebuylinks', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'custom_buylink_anchor' => array(
					'label' => esc_html__('Ticket buy text', 'kentha'),
					'desc'	=> '(example: This website, or Ticket One, or something else)',
					'id' => 'cbuylink_anchor',
					'type' => 'text'
				),
				'custom_buylink_url' => array(
					'label' => esc_html__('Ticket buy link ', 'kentha'),
					'id' => 'cbuylink_url',
					'type' => 'text'
				)
			)
		),
	);
	$event_lineup = array(
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__('Lineup', 'kentha'), // <label>
			'desc'	=> esc_html__('Choose among existing artists', 'kentha') ,// description
			'id'	=> 'event_lineup', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'artist' => array(
					'label' => esc_html__('Artist', "kentha"),
					'id' => 'artist',
					'type' => 'post_chosen',
					'posttype' => 'artist'
				),
				'time' => array(
					'label' => esc_html__('Time', 'kentha'),
					'id' => 'time',
					'type' => 'time'
				),
				'manual_artist' => array(
					'label' => esc_html__('Manually add new artist', 'kentha'),
					'desc' => esc_html__('Compile the fields below instead of choosing an existing artist. No artist will be created in artist post type.', 'kentha'),
					'id' => 'manual_artist',
					'type' => 'checkbox'
				),
				'name' => array(
					'label' => esc_html__('Name', 'kentha'),
					'id' => 'name',
					'type' => 'text'
				),
				'link' => array(
					'label' => esc_html__('Link', 'kentha'),
					'id' => 'link',
					'type' => 'text'
				),
				'photo' => array(
					'label' => esc_html__('Photo', 'kentha'),
					'id' => 'photo',
					'type' => 'image'
				)
			)
		)
	);
	
	$event_meta_box = new custom_add_meta_box( 'event_customtab', esc_html__('Event details', 'kentha'), $event_meta_boxfields, 'event', true );
	$event_meta_box_lineup = new custom_add_meta_box( 'event_lineup_tab', esc_html__('Event line-up', 'kentha'), $event_lineup, 'event', true );

}}
