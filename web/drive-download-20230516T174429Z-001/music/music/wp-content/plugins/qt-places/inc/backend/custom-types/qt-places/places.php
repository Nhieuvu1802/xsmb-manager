<?php

/* = main function 
=========================================*/
if(!function_exists('qt_place_register_type')){
function qt_place_register_type() {
	if(post_type_exists('place')){
		return;
	}
	$labelsevent = array (
        'name' => esc_attr__("Place","qt-places"),
        'singular_name' => esc_attr__("Place","qt-places"),
        'add_new' => esc_attr__("Add new","qt-places"),
        'add_new_item' => esc_attr__("Add new place","qt-places"),
        'edit_item' => esc_attr__("Edit place","qt-places"),
        'new_item' => esc_attr__("New place","qt-places"),
        'all_items' => esc_attr__("All places","qt-places"),
        'view_item' => esc_attr__("View place","qt-places"),
        'search_items' => esc_attr__("Search place","qt-places"),
        'not_found' => esc_attr__("No places found","qt-places"),
        'not_found_in_trash' => esc_attr__("No places found in trash","qt-places"),
        'menu_name' => esc_attr__("Places","qt-places")
    );

    $args = array (
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
        'menu_icon' => 'dashicons-location-alt',
    	'page-attributes' => true,
    	'show_in_nav_menus' => true,
    	'show_in_admin_bar' => true,
    	'show_in_menu' => true,
        'supports' => array('title','thumbnail','editor','page-attributes')
    ); 

    register_post_type( 'place' , $args );
	 $labels = array (
		'name' => esc_attr__( 'Place category',"qt-places" ),
		'singular_name' => esc_attr__( 'Place categories',"qt-places" ),
		'search_items' =>  __( 'Search by category',"qt-places" ),
		'popular_items' => esc_attr__( 'Popular categories',"qt-places" ),
		'all_items' => esc_attr__( 'All categories',"qt-places" ),
		'parent_item' => null,
		'parent_item_colon' => null,
		'edit_item' => esc_attr__( 'Edit category',"qt-places" ), 
		'update_item' => esc_attr__( 'Update category',"qt-places" ),
		'add_new_item' => esc_attr__( 'Add New category',"qt-places" ),
		'new_item_name' => esc_attr__( 'New category name',"qt-places" ),
		'separate_items_with_commas' => esc_attr__( 'Separate categories with commas',"qt-places" ),
		'add_or_remove_items' => esc_attr__( 'Add or remove categories',"qt-places" ),
		'choose_from_most_used' => esc_attr__( 'Choose from the most used categories',"qt-places" ),
		'menu_name' => esc_attr__( 'Place categories',"qt-places" ),
	  ); 

	  register_taxonomy ('pcategory','place',array(
		'hierarchical' => true,
		'labels' => $labels,
		'show_ui' => true,
		'update_count_callback' => '_update_post_term_count',
		'query_var' => true,
		'rewrite' => array ( 'slug' => 'pcategory' ),
	  ));
}}
add_action('init', 'qt_place_register_type');  



/*
*   Add location capabilities to post types
*   =============================================================
*/

if(!function_exists('qt_add_places_capabilities')){
function qt_add_places_capabilities(){
    $fields = array (
        array (
            'label' => esc_attr__('Location name',"qt-places"),
            'id'    => 'qt_location',
            'type'  => 'text'
        ),
        array (
            'label' => esc_attr__('Address',"qt-places"),
            'id'    => 'qt_address',
            'type'  => 'text'
        ),
        array (
            'label' => esc_attr__('City',"qt-places"),
            'id'    => 'qt_city',
            'type'  => 'text'
        ),
         array (
            'label' => esc_attr__('Country',"qt-places"),
            'id'    => 'qt_country',
            'type'  => 'text'
        ),
         array (
            'label' => esc_attr__('Coordinates',"qt-places"),
            'desc'  => esc_attr__('Coords must be written like this: 38.900867,1.419283', "qt-places"),
            'id'    => 'qt_coord',
            'type'  => 'coordinates'
        ),
        array (
            'label' => esc_attr__('Link',"qt-places"),
            'id'    => 'qt_link',
            'type'  => 'text'
        ),
         array (
            'label' => esc_attr__('Phone',"qt-places"),
            'id'    => 'qt_phone',
            'type'  => 'text'
        ),
         array (
            'label' => esc_attr__('Email address',"qt-places"),
            'id'    => 'qt_email',
            'type'  => 'text'
        ),
        array (
            'label' => esc_attr__('Marker icon class FontAwesome',"qt-places"),
            'id'    => 'qt_placeicon',
            'desc'  => __('Class of the FontAwesome icon', "qt-places"). ' https://fortawesome.github.io/Font-Awesome/cheatsheet/',
            'type'  => 'text'
        ),
        array (
            'label' => esc_attr__('Marker style',"qt-places"),
            'id'    => 'qt_placeicondesign',
            'default' => 'image',
            'type'  => 'radio',
            'options' => array (
                array (  'label' => 'Show image',
                        'value' => 'image'),
                array (  'label' => 'Show icon',
                        'value' => 'icon')
            )
        ),
        array (
            'label' => esc_attr__('Marker color',"qt-places"),
            'id'    => 'qt_placeiconcolor',
            'type'  => 'color'
        ),         
    );
    $args = array (
       'public'   => true,
       '_builtin' => false
    );


    $associate_place = array (
        array(
            'label' => esc_html__('Associate location', "qt-places"),
            'posttype' => 'place',
            'id' => 'qt_places_associated_place',
            'type' => 'post_chosen'
            ),
    );



    $post_types = get_post_types( $args, 'names' ); 
    $post_types[] = 'post';
    $post_types[] = 'page';


    if(function_exists('custom_meta_box_field')){
        foreach ( $post_types as $post_type ) {

             $active_extraposts = ( ( get_option( 'qtmaps_typeselect_'.$post_type) == 1  || $post_type == 'event') &&  $post_type !== 'place' )? true : false;
            if( $active_extraposts ){
                $assoc_location = new custom_add_meta_box("associatedplace", esc_html__('Associate location', "qt-places"), $associate_place, $post_type, true );
            }
            $active = ( get_option( 'qtmaps_typeselect_'.$post_type) == 1  || $post_type == 'place'  || $post_type == 'event' )? true : false;
            if( $active ){
                $place_fields = new custom_add_meta_box("placesdetails", esc_html__('Place details', "qt-places"), $fields, $post_type, true );
            }           
        }
    }

}}
add_action('wp_loaded', 'qt_add_places_capabilities');  


