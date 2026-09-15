<?php
add_action('init', 'kentha_artist_register_type');  
if(!function_exists('kentha_artist_register_type')){
function kentha_artist_register_type() {
	$labels = array(
		'name' => esc_html__("Artist","kentha"),
		'singular_name' => esc_html__("Artist","kentha"),
		'add_new' => esc_html__("Add new","kentha"),
		'add_new_item' => esc_html__("Add new artist","kentha"),
		'edit_item' => esc_html__("Edit artist","kentha"),
		'new_item' => esc_html__("New artist","kentha"),
		'all_items' => esc_html__("All artists","kentha"),
		'view_item' => esc_html__("View artist","kentha"),
		'search_items' => esc_html__("Search artist","kentha"),
		'not_found' => esc_html__("No artists found","kentha"),
		'not_found_in_trash' => esc_html__("No artists found in trash","kentha"),
		'menu_name' => esc_html__("Artists","kentha")
	);
	$args = array(
		'labels' => $labels,
		'singular_label' =>  esc_html__("Artist","kentha"),
		'public' => true,
		'show_ui' => true,
		'capability_type' => 'page',
		'has_archive' => true,
		'publicly_queryable' => true,
		'rewrite' => true,
		'menu_position' => 40,
		'query_var' => true,
		'exclude_from_search' => false,
		'can_export' => true,
		'hierarchical' => false,
		'page-attributes' => true,
		'show_in_rest' => true,
		'menu_icon' => 'dashicons-star-filled',
		'supports' => array('title', 'thumbnail','editor', 'page-attributes' )
	);  
	if (function_exists('ttg_custom_post_type')){
		ttg_custom_post_type( "artist" , $args );
	}
	$labels = array(
		'name' => esc_html__( 'Artist genres',"kentha" ),
		'singular_name' => esc_html__( 'Genres',"kentha" ),
		'search_items' =>  esc_html__( 'Search by genre',"kentha" ),
		'popular_items' => esc_html__( 'Popular genres',"kentha" ),
		'all_items' => esc_html__( 'All genres',"kentha" ),
		'parent_item' => null,
		'parent_item_colon' => null,
		'edit_item' => esc_html__( 'Edit genre',"kentha" ), 
		'update_item' => esc_html__( 'Update genre',"kentha" ),
		'add_new_item' => esc_html__( 'Add new genre',"kentha" ),
		'new_item_name' => esc_html__( 'New genre Name',"kentha" ),
		'separate_items_with_commas' => esc_html__( 'Separate genres with commas',"kentha" ),
		'add_or_remove_items' => esc_html__( 'Add or remove genres',"kentha" ),
		'choose_from_most_used' => esc_html__( 'Choose from the most used genres',"kentha" ),
		'menu_name' => esc_html__( 'Genres',"kentha" )
	); 
	$args = array(
		'hierarchical' => true,
		'labels' => $labels,
		'show_ui' => true,
		'update_count_callback' => '_update_post_term_count',
		'query_var' => true,
		'show_in_rest' => true,
		'rewrite' => array( 'slug' => 'artistgenre' )
	);
	if(function_exists('ttg_custom_taxonomy')){
		ttg_custom_taxonomy('artistgenre','artist',$args	);
	} 
	$artist_tab_data_arr = array(
		array(
			'label' => esc_html__( 'Logo', "kentha" ),
			'id'    => 'qt_page_logo',
			'desc'	=> esc_html__( 'It will replace the page title', 'kentha' ),
			'type'  => 'image'
			),
		array(
			'label' => esc_html__( 'Agency', "kentha" ),
			'id'    => '_artist_booking_contact_name',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Phone', "kentha" ),
			'id'    => '_artist_booking_contact_phone',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Public email', "kentha" ),
			'id'    => '_artist_booking_contact_email',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Nationality', "kentha" ),
			'id'    => '_artist_nationality',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Resident in', "kentha" ),
			'id'    => '_artist_resident',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 1', "kentha" ),
			'id'    => '_artist_youtubevideo1',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 2', "kentha" ),
			'id'    => '_artist_youtubevideo2',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 3', "kentha" ),
			'id'    => '_artist_youtubevideo3',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 4', "kentha" ),
			'id'    => '_artist_youtubevideo4',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 5', "kentha" ),
			'id'    => '_artist_youtubevideo5',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Youtube Video 6', "kentha" ),
			'id'    => '_artist_youtubevideo6',
			'type'  => 'text'
			),
	);
	$artist_tab_data = new custom_add_meta_box( 'artist_tab_data', 'Artist data', $artist_tab_data_arr, 'artist', true );
	$social_icons = array(
		array(
			'label' => esc_html__( 'Website', "kentha" ),
			'id'    => '_artist_website',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Facebook', "kentha" ),
			'id'    => '_artist_facebook',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Beatport', "kentha" ),
			'id'    => '_artist_beatport',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Soundcloud', "kentha" ),
			'id'    => '_artist_soundcloud',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Mixcloud', "kentha" ),
			'id'    => '_artist_mixcloud',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Myspace', "kentha" ),
			'id'    => '_artist_myspace',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Resident Advisor', "kentha" ),
			'id'    => '_artist_residentadv',
			'type'  => 'text'
			),

		array(
			'label' => esc_html__( 'Twitter', "kentha" ),
			'id'    => '_artist_twitter',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'HearThis', "kentha" ),
			'id'    => '_artist_hearthis',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Instagram', "kentha" ),
			'id'    => '_artist_instagram',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Snapchat', "kentha" ),
			'id'    => '_artist_snapchat',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Whatpeopleplay', "kentha" ),
			'id'    => '_artist_whatpeopleplay',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'LastFM', "kentha" ),
			'id'    => '_artist_lastfm',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Vimeo', "kentha" ),
			'id'    => '_artist_vimeo',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Pinterest', "kentha" ),
			'id'    => '_artist_pinterest',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Google+', "kentha" ),
			'id'    => '_artist_googleplus',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Trackitdown+', "kentha" ),
			'id'    => '_artist_trackitdown',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Android app+', "kentha" ),
			'id'    => '_artist_android',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'iTunes', "kentha" ),
			'id'    => '_artist_itunes',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Amazon', "kentha" ),
			'id'    => '_artist_amazon',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'DjTunes', "kentha" ),
			'id'    => '_artist_djtunes',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Reddit', "kentha" ),
			'id'    => '_artist_reddit',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Beatmusic', "kentha" ),
			'id'    => '_artist_beatmusic',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'VK', "kentha" ),
			'id'    => '_artist_vk',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Reverbnation', "kentha" ),
			'id'    => '_artist_reverbnation',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__( 'Kuvo', "kentha" ),
			'id'    => '_artist_kuvo',
			'type'  => 'text'
			),
	);
	$artist_social_custom_box = new custom_add_meta_box( 'artist_social', 'Social Icons', $social_icons, 'artist', true );
	$fields_links = array(
		array(
			'label' => esc_html__('Custom links title','kentha'),
			'id' => 'qt_custom_links_title',
			'type'  => 'text'
			),
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__('Custom external links','kentha'), // <label>
			'desc'	=> esc_html__('Add one for each link to external websites','kentha'), // description
			'id'	=> 'repeatablebuylinks', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'custom_buylink_anchor' => array(
					'label' => esc_html__( 'Text', 'kentha' ),
					'desc'	=> esc_html__( 'example: Itunes, Beatport, Trackitdown', 'kentha' ),
					'id' => 'cbuylink_anchor',
					'type' => 'text'
				),
				'custom_buylink_url' => array(
					'label' => esc_html__( 'URL', 'kentha' ),
					'desc'	=> esc_html__( 'Including http://...', 'kentha' ),
					'id' => 'cbuylink_url',
					'type' => 'text'
				)
			)
		)
	);
	$artist_tab_custom_box = new custom_add_meta_box( 'artist_links', 'Custom links', $fields_links, 'artist', true );
	$artist_tab_custom = array(
		array(
			'label' => esc_html__('Add a custom tab content here','kentha'),
			'id' => false,
			'type'  => 'chapter'
			),
		array(
			'label' => esc_html__('Custom tab title','kentha'),
			'id'    => 'custom_tab_title',
			'type'  => 'text'
			),
		array(
			'label' => esc_html__('Custom tab content','kentha'),
			'id'    => 'custom_tab_content',
			'type'  => 'editor'
			)
	);
	$artist_tab_custom_box = new custom_add_meta_box( 'artist_customtab', 'Tabs Customizer', $artist_tab_custom, 'artist', true );
}}
?>