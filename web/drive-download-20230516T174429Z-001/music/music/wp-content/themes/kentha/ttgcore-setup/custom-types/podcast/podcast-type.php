<?php
add_action('init', 'kentha_podcast_register_type');  
if(!function_exists('kentha_podcast_register_type')){
function kentha_podcast_register_type() {
	$labelspodcast = array(
		'name' => esc_attr__("Podcast",'kentha'),
		'singular_name' => esc_attr__("Podcast",'kentha'),
		'add_new' => esc_attr__("Add new",'kentha'),
		'add_new_item' => esc_attr__("Add new podcast",'kentha'),
		'edit_item' => esc_attr__("Edit podcast",'kentha'),
		'new_item' => esc_attr__("New podcast",'kentha'),
		'all_items' => esc_attr__("All podcasts",'kentha'),
		'view_item' => esc_attr__("View podcast",'kentha'),
		'search_items' => esc_attr__("Search podcast",'kentha'),
		'not_found' => esc_attr__("No podcasts found",'kentha'),
		'not_found_in_trash' => esc_attr__("No podcasts found in trash",'kentha'),
		'menu_name' => esc_attr__("Podcasts",'kentha')
	);

	$args = array(
		'labels' => $labelspodcast,
		'public' => true,
		'publicly_queryable' => true,
		'show_ui' => true, 
		'show_in_menu' => true, 
		'query_var' => true,
		'rewrite' => array( 'slug' => 'podcast' ),
		'capability_type' => 'page',
		'has_archive' => true,
		'hierarchical' => false,
		'menu_position' => 40,
		'page-attributes' => true,
		'show_in_nav_menus' => true,
		'show_in_admin_bar' => true,
		'show_in_menu' => true,
		'show_in_rest' => true,
		'menu_icon' => 'dashicons-megaphone',
		'supports' => array('title', 'thumbnail','editor' )
	); 

	if (function_exists('ttg_custom_post_type')){
		ttg_custom_post_type( "podcast" , $args );
	}

	/* ============= create custom taxonomy for the podcasts ==========================*/

	$labels = array(
		'name' => esc_attr__( 'Podcast filters','kentha' ),
		'singular_name' => esc_attr__( 'Filter','kentha' ),
		'search_items' =>  esc_attr__( 'Search by filter','kentha' ),
		'popular_items' => esc_attr__( 'Popular filters','kentha' ),
		'all_items' => esc_attr__( 'All Podcasts','kentha' ),
		'parent_item' => null,
		'parent_item_colon' => null,
		'edit_item' => esc_attr__( 'Edit Filter','kentha' ), 
		'update_item' => esc_attr__( 'Update Filter','kentha' ),
		'add_new_item' => esc_attr__( 'Add New Filter','kentha' ),
		'new_item_name' => esc_attr__( 'New Filter Name','kentha' ),
		'separate_items_with_commas' => esc_attr__( 'Separate Filters with commas','kentha' ),
		'add_or_remove_items' => esc_attr__( 'Add or remove Filters','kentha' ),
		'choose_from_most_used' => esc_attr__( 'Choose from the most used Filters','kentha' ),
		'menu_name' => esc_attr__( 'Filters','kentha' )
	); 

	$args = array(
		'hierarchical' => true,
		'labels' => $labels,
		'show_ui' => true,
		'update_count_callback' => '_update_post_term_count',
		'query_var' => true,
		'show_in_rest' => true,
		'rewrite' => array( 'slug' => 'podcastfilter' ),
	);
	if(function_exists('ttg_custom_taxonomy')){
		ttg_custom_taxonomy('podcastfilter','podcast',$args	);
	}






	$podcast_tab_custom = array(
		array(
			'label' => esc_attr__( 'Artist Name', 'kentha' ),
			'id'    => '_podcast_artist',
			'type'  => 'text'
			),
		array(
			'label' => esc_attr__( 'Date', 'kentha' ),
			'id'    => '_podcast_date',
			'type'  => 'date'
			),
		array(
			'label' => esc_attr__( 'Soundcloud/Mixcloud/Youtube/MP3', 'kentha' ),
			'id'    => '_podcast_resourceurl',
			'desc' => esc_attr__('To link an external podcast like Soundcloud, add the URL directly in the field. If uploading a file, you can have file size restrictions. Please contact your hosting provider to remove those limits','kentha'),
			'type'  => 'file'
			),
		array(
			'label' => esc_html__( 'Download icon (cart icon is default)','kentha' ),
			'id' 	=> 'icon_type',
			'type' 	=> 'select',
			'default' => 'cart',
			'options' => array(
				array('label' => 'cart','value' => 'cart'),
				array('label' => 'download','value' => 'download')
				)
			),
		array(
			'label' => esc_html__( 'Download or purchase link, or WooCommerce product ID','kentha' ),
			'desc'	=> esc_html__( 'External URL or WooCommerce product ID','kentha' ), // description
			'id' 	=> 'releasetrack_buyurl',
			'type' 	=> 'text'
		),
		array(
			'label' => esc_html__( 'Price','kentha' ),
			'desc'	=> esc_html__( 'Optional: podcast price','kentha' ), // description
			'id' 	=> 'price',
			'type' 	=> 'text'
		),
	);
	$podcast_tab_custom_box = new custom_add_meta_box( 'podcast_customtab', esc_attr__('Podcast details', 'kentha'), $podcast_tab_custom, 'podcast', true );





	$podcast_tracklist_fields = array(
		array( // Repeatable & Sortable Text inputs
			'label'	=>  esc_attr__( 'Podcast tracklist', 'kentha' ), // <label>
			'desc'	=>  esc_attr__( 'Add tracks information', 'kentha' ), // description
			'id'	=> 'podcast_tracklist', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'title' => array(
					'label' => esc_html__( 'Song title', 'kentha' ),
					'id' => 'title',
					'type' => 'text'
				),
				'artist' => array(
					'label' => esc_html__( 'Artist', 'kentha' ),
					'id' => 'artist',
					'type' => 'text'
				),
				'time' => array(
					'label' =>  esc_attr__( 'Time (HH:MM:SS)', 'kentha' ),
					'desc'	=>  esc_attr__( 'Hours, minutes and seconds', 'kentha' ), // description
					'id' => 'cue',
					'type' => 'timecue'
				)
			)
		)
	);
	$podcast_tab_tracklist = new custom_add_meta_box( 'podcast_tracklist', esc_attr__('Podcast tracklist', 'kentha'), $podcast_tracklist_fields, 'podcast', true );
}}
