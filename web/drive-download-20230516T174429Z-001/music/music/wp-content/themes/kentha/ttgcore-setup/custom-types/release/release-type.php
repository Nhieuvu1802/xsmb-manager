<?php
add_action('init', 'kentha_release_register_type');  
if(!function_exists('kentha_release_register_type')){
function kentha_release_register_type() {
	$labelsrelease = array(
		'name' => esc_html__("Release",'kentha'),
		'singular_name' => esc_html__("Release",'kentha'),
		'add_new' => esc_html__("Add new",'kentha'),
		'add_new_item' => esc_html__("Add new release",'kentha'),
		'edit_item' => esc_html__("Edit release",'kentha'),
		'new_item' => esc_html__("New release",'kentha'),
		'all_items' => esc_html__("All releases",'kentha'),
		'view_item' => esc_html__("View release",'kentha'),
		'search_items' => esc_html__("Search release",'kentha'),
		'not_found' => esc_html__("No releases found",'kentha'),
		'not_found_in_trash' => esc_html__("No releases found in trash",'kentha'),
		'menu_name' => esc_html__("Album releases",'kentha')
	);
	$args = array(
		'labels' => $labelsrelease,
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
		'page-attributes' => true,
		'show_in_nav_menus' => true,
		'show_in_admin_bar' => true,
		'show_in_menu' => true,
		'show_in_rest' => true,
		'menu_icon' => 'dashicons-controls-play',
		'supports' => array('title', 'thumbnail','editor', 'page-attributes' )
	); 
	if (function_exists('ttg_custom_post_type')){
		ttg_custom_post_type( "release" , $args );
	}
	/* ============= create custom taxonomy for the releases ==========================*/
	 $labels = array(
		'name' => __( 'Release genres','kentha' ),
		'singular_name' => esc_html__( 'Genre','kentha' ),
		'search_items' =>  esc_html__( 'Search by genre','kentha' ),
		'popular_items' => esc_html__( 'Popular genres','kentha' ),
		'all_items' => esc_html__( 'All releases','kentha' ),
		'parent_item' => null,
		'parent_item_colon' => null,
		'edit_item' => esc_html__( 'Edit genre','kentha' ), 
		'update_item' => esc_html__( 'Update genre','kentha' ),
		'add_new_item' => esc_html__( 'Add New genre','kentha' ),
		'new_item_name' => esc_html__( 'New genre Name','kentha' ),
		'separate_items_with_commas' => esc_html__( 'Separate genres with commas','kentha' ),
		'add_or_remove_items' => esc_html__( 'Add or remove genres','kentha' ),
		'choose_from_most_used' => esc_html__( 'Choose from the most used genres','kentha' ),
		'menu_name' => esc_html__( 'Music genres','kentha' ),
	); 
  	$args = array(
		'hierarchical' => true,
		'labels' => $labels,
		'show_ui' => true,
		'update_count_callback' => '_update_post_term_count',
		'query_var' => true,
		'show_in_rest' => true,
		'rewrite' => array( 'slug' => 'genre' ),
 	);
  	if(function_exists('ttg_custom_taxonomy')){
		ttg_custom_taxonomy('genre','release',$args	);
	}
	$fields = array(
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__( 'Release Tracks','kentha' ), // <label>
			'desc'	=> esc_html__( 'Add one for each track in the release','kentha' ), // description
			'id'	=> 'track_repeatable', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			
			'repeatable_fields' => array ( // array of fields to be repeated
				'releasetrack_mp3_demo' => array(
					'label' => esc_html__( 'MP3 Demo','kentha' ),
					'desc'	=> esc_html__( '(Never upload your full quality tracks, someone can steal them)','kentha' ), // description
					'id' => 'releasetrack_mp3_demo',
					'type' => 'file',
				),
				
				'releasetrack_track_title' => array(
					'label' => esc_html__( 'Title','kentha' ),
					'id' => 'releasetrack_track_title',
					'type' => 'text'
				),
				'releasetrack_artist_name' => array(
					'label' => esc_html__( 'Artists','kentha' ),
					'desc'	=> esc_html__( '(All artists separated bu comma)','kentha' ), // description
					'id' => 'releasetrack_artist_name',
					'type' => 'text'
				),
				'releasetrack_buy_url' => array(
					'label' => esc_html__( 'Track Buy link','kentha' ),
					'desc'	=> esc_html__( 'External URL or WooCommerce product ID','kentha' ), // description
					'id' 	=> 'releasetrack_buyurl',
					'type' 	=> 'text'
				),
				'price' => array(
					'label' => esc_html__( 'Price','kentha' ),
					'desc'	=> esc_html__( 'Optional: track price','kentha' ), // description
					'id' 	=> 'price',
					'type' 	=> 'text'
				),
				'icon_type' => array(
					'label' => esc_html__( 'Track icon (cart icon is default)','kentha' ),
					'id' 	=> 'icon_type',
					'type' 	=> 'select',
					'default' => 'cart',
					'options' => array(
						array('label' => 'cart','value' => 'cart'),
						array('label' => 'download','value' => 'download')
					)
				),
		
			)
		)
	);


	$fields_links = array(
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__( 'Custom Buy Links','kentha' ), // <label>
			'desc'	=> esc_html__( 'Add one for each link to external websites','kentha' ), // description
			'id'	=> 'track_repeatablebuylinks', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'custom_buylink_anchor' => array(
					'label' => esc_html__( 'Custom Buy Text','kentha' ),
					'desc'	=> esc_html__( '(example: Itunes, Beatport, Trackitdown)','kentha' ),
					'id' => 'cbuylink_anchor',
					'type' => 'text'
				),
				'custom_buylink_url' => array(
					'label' => esc_html__('Custom Buy URL','kentha' ),
					'desc'	=> esc_html__( 'External URL or WooCommerce product ID','kentha' ), // description
					'id' => 'cbuylink_url',
					'type' => 'text'
				)
			)
		)
	);
	$fields_release = array(
		array(
			'label' => esc_html__('Main artist', "kentha"),
			'id' => 'releasetrack_artist',
			'type' => 'post_chosen',
			'posttype' => 'artist'
			),
		array(
			'label' => esc_html__( 'Label','kentha' ),
			'id'    => 'general_release_details_label',
			'type'  => 'text'
			),
		array(
			'label' =>esc_html__( 'Release date (YYYY-MM-DD)','kentha' ) ,
			'id'    => 'general_release_details_release_date',
			'type'  => 'date'
			),
		array(
			'label' => esc_html__( 'Catalog Number','kentha' ),
			'id'    => 'general_release_details_catalognumber',
			'type'  => 'text'
			)
	);
	$details_box = new custom_add_meta_box( 'release_details', 'Release Details', $fields_release, 'release', true );
	$sample_box = new custom_add_meta_box( 'release_tracks', 'Release Tracks', $fields, 'release', true );
	$buylinks_box = new custom_add_meta_box( 'release_buylinkss', 'Custom Buy Links', $fields_links, 'release', true );
}}



