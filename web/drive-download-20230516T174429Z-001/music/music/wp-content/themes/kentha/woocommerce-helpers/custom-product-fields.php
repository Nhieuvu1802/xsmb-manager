<?php
/*
* Package: Kentha
* This is a WooCommerce support file to add custom fields to products
*/




if(!function_exists('kentha_woocommerce_associated_release_fields')){
	add_action('init', 'kentha_woocommerce_associated_release_fields');  
	function kentha_woocommerce_associated_release_fields() {
		$fields_release = array(
			array(
				'label' => esc_html__('Connect album playlist', "kentha"),
				'id' => 'kentha_related_release',
				'type' => 'post_chosen',
				'posttype' => 'release'
			),
			
		);
		if( post_type_exists( 'product' ) && class_exists('custom_add_meta_box') ){
			$details_box = new custom_add_meta_box( 'associated_release_fields', 'Connect album release', $fields_release, 'product', true );
		}
	}
}




/**
 * =======================================================
 * @since  2.0
 * // NEW MUSIC SHOP FIELDS
 * =======================================================
 */
if(!function_exists('kentha_woocommerce_singletrack_fields')){
	add_action('init', 'kentha_woocommerce_singletrack_fields');  
	function kentha_woocommerce_singletrack_fields() {
		$fields_release = array(
			// 2019 OCT 07
			// @since 2.0
			array(
				'label' => esc_html__('Single track product', 'kentha'),
				'desc' => esc_html__('This product is a single song.', 'kentha'),
				'id' => 'kentha_singletrack',
				'type' => 'checkbox'
			),
			array(
				'label' => esc_html__('Hide information details', 'kentha'),
				'desc' => esc_html__('Hide the box with Description, Additional Information and Reviews. The product text will appear under the track details.', 'kentha'),
				'id' => 'kentha_hideinfo',
				'type' => 'checkbox'
			),
			array(
				'label' => esc_html__('Artist', "kentha"),
				'id' => 'kentha_artist',
				'type' => 'post_chosen', // important: we use a post chosen to avoid conflicts with accents and strange names
				'posttype' => 'artist'
				),
			array(
				'label' => esc_html__( 'BPM', "kentha" ),
				'id'    => 'kentha_bpm',
				'type'  => 'text'
				),
			array(
				'label' => esc_html__( 'Track duration', "kentha" ),
				'id'    => 'kentha_duration',
				'type'  => 'text'
				),
			array(
					'label' => esc_html__( 'MP3 Demo','kentha' ),
					'desc'	=> esc_html__( 'Is recommended to upload cropped 128 or 96Kbps mp3 demos','kentha' ), // description
					'id' => 'releasetrack_mp3_demo',
					'type' => 'file',
				),
		);
		if( post_type_exists( 'product' ) && class_exists('custom_add_meta_box') && get_theme_mod('kentha_woocommerce_singletrack_enable') ){
			$details_box = new custom_add_meta_box( 'kentha_track_details', 'Track details', $fields_release, 'product', true );
		}

		/**
		 * Product Royalty Types
		 * WHY A TAXONOMY?
		 * To create archives and allow a drop down in the product settings.
		 */
		if(  post_type_exists( 'product' ) && function_exists( 'ttg_custom_taxonomy' )){
			$labels = array(
				'name' => esc_html__( 'Royalty type',"kentha" ),
				'singular_name' => esc_html__( 'Royalty type',"kentha" ),
				'search_items' =>  esc_html__( 'Search by royalty type',"kentha" ),
				'popular_items' => esc_html__( 'Popular royalty types',"kentha" ),
				'all_items' => esc_html__( 'All royalty types',"kentha" ),
				'parent_item' => null,
				'parent_item_colon' => null,
				'edit_item' => esc_html__( 'Edit royalty type',"kentha" ), 
				'update_item' => esc_html__( 'Update royalty type',"kentha" ),
				'add_new_item' => esc_html__( 'Add new royalty type',"kentha" ),
				'new_item_name' => esc_html__( 'New royalty type',"kentha" ),
				'separate_items_with_commas' => esc_html__( 'Separate royalty types with commas',"kentha" ),
				'add_or_remove_items' => esc_html__( 'Add or remove royalty type',"kentha" ),
				'choose_from_most_used' => esc_html__( 'Choose from the most used royalty types',"kentha" ),
				'menu_name' => esc_html__( 'Royalty types',"kentha" )
			); 
			$args = array(
				'hierarchical' => true,
				'labels' => $labels,
				'show_ui' => true,
				'update_count_callback' => '_update_post_term_count',
				'query_var' => true,
				'show_in_rest' => true,
				'rewrite' => array( 'slug' => 'royalty-types' )
			);
			ttg_custom_taxonomy('royalty-types','product',$args	);
		} 


		/**
		 * Custom product genre taxonomy
		 * @var array
		 */
		if(  post_type_exists( 'product' ) && function_exists('ttg_custom_taxonomy' )  ){
			$labels = array(
				'name' => esc_html__( 'Music genres',"kentha" ),
				'singular_name' => esc_html__( 'Genres',"kentha" ),
				'search_items' =>  esc_html__( 'Search by genre',"kentha" ),
				'popular_items' => esc_html__( 'Popular genres',"kentha" ),
				'all_items' => esc_html__( 'All genres',"kentha" ),
				'parent_item' => null,
				'parent_item_colon' => null,
				'edit_item' => esc_html__( 'Edit genre',"kentha" ), 
				'update_item' => esc_html__( 'Update genre',"kentha" ),
				'add_new_item' => esc_html__( 'Add New genre',"kentha" ),
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
				'rewrite' => array( 'slug' => 'track-genre' )
			);
			ttg_custom_taxonomy('trackgenre','product',$args	);
		} 

		/**
		 * Custom product software taxonomy
		 * @var array
		 */
		if(  post_type_exists( 'product' ) && function_exists('ttg_custom_taxonomy' )  ){
			$labels = array(
				'name' => esc_html__( 'Software',"kentha" ),
				'singular_name' => esc_html__( 'Software',"kentha" ),
				'search_items' =>  esc_html__( 'Search by software',"kentha" ),
				'popular_items' => esc_html__( 'Popular softwares',"kentha" ),
				'all_items' => esc_html__( 'All softwares',"kentha" ),
				'parent_item' => null,
				'parent_item_colon' => null,
				'edit_item' => esc_html__( 'Edit software',"kentha" ), 
				'update_item' => esc_html__( 'Update software',"kentha" ),
				'add_new_item' => esc_html__( 'Add New software',"kentha" ),
				'new_item_name' => esc_html__( 'New software name',"kentha" ),
				'separate_items_with_commas' => esc_html__( 'Separate softwares with commas',"kentha" ),
				'add_or_remove_items' => esc_html__( 'Add or remove software',"kentha" ),
				'choose_from_most_used' => esc_html__( 'Choose from the most used softwares',"kentha" ),
				'menu_name' => esc_html__( 'Softwares',"kentha" )
			); 
			$args = array(
				'hierarchical' => true,
				'labels' => $labels,
				'show_ui' => true,
				'update_count_callback' => '_update_post_term_count',
				'query_var' => true,
				'show_in_rest' => true,
				'rewrite' => array( 'slug' => 'track-software' )
			);
			ttg_custom_taxonomy('tracksoftware','product',$args	);
		} 
	}
}




















