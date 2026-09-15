<?php
add_action('init', 'kentha_podcast_genres');  
if(!function_exists('kentha_podcast_genres')){
function kentha_podcast_genres() {
	
	/* ============= create custom taxonomy for the releases ==========================*/
	 $labels = array(
		'name' => __( 'Podcast genres','kentha' ),
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
		ttg_custom_taxonomy('genre','podacst',$args	);
	}
	
}}



