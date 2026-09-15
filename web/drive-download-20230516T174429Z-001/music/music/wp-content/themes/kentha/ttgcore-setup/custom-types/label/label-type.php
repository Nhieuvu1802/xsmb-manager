<?php

if(!function_exists('kentha_label_register_type')){
	add_action('init', 'kentha_label_register_type');  
	function kentha_label_register_type() {
		$labels = array(
			'name' => esc_html__("Label","kentha"),
			'singular_name' => esc_html__("Label","kentha"),
			'add_new' => esc_html__("Add new","kentha"),
			'add_new_item' => esc_html__("Add new label","kentha"),
			'edit_item' => esc_html__("Edit label","kentha"),
			'new_item' => esc_html__("New label","kentha"),
			'all_items' => esc_html__("All labels","kentha"),
			'view_item' => esc_html__("View label","kentha"),
			'search_items' => esc_html__("Search label","kentha"),
			'not_found' => esc_html__("No labels found","kentha"),
			'not_found_in_trash' => esc_html__("No labels found in trash","kentha"),
			'menu_name' => esc_html__("Labels","kentha")
		);
		$args = array(
			'labels' => $labels,
			'singular_label' =>  esc_html__("Label","kentha"),
			'public' => true,
			'show_ui' => true,
			'capability_type' => 'page',
			'has_archive' => true,
			'publicly_queryable' => true,
			'rewrite' =>  array( 'slug' => 'musiclabel' ),
			'menu_position' => 40,
			'query_var' => true,
			'exclude_from_search' => false,
			'can_export' => true,
			'hierarchical' => false,
			'page-attributes' => true,
			'show_in_rest' => true,
			'menu_icon' => 'dashicons-tag',
			'supports' => array('title', 'thumbnail','editor', 'page-attributes' )
		);  
		if (function_exists('ttg_custom_post_type')){
			ttg_custom_post_type( "music_label" , $args );
		}
		$labels = array(
			'name' => esc_html__( 'Label genres',"kentha" ),
			'singular_name' => esc_html__( 'Genres',"kentha" ),
			'search_items' =>  esc_html__( 'Search by genre',"kentha" ),
			'popular_items' => esc_html__( 'Popular genres',"kentha" ),
			'all_items' => esc_html__( 'All genres',"kentha" ),
			'parent_item' => null,
			'parent_item_colon' => null,
			'edit_item' => esc_html__( 'Edit genre',"kentha" ), 
			'update_item' => esc_html__( 'Update genre',"kentha" ),
			'add_new_item' => esc_html__( 'Add new genre',"kentha" ),
			'new_item_name' => esc_html__( 'New genre name',"kentha" ),
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
			'rewrite' => array( 'slug' => 'labelgenre' )
		);
		if(function_exists('ttg_custom_taxonomy')){
			ttg_custom_taxonomy('labelgenre','label',$args	);
		} 
		
	}
}
?>