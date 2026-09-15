<?php  

/*
*	Page special attributes
*	=============================================================
*/

if(!function_exists("kentha_add_special_fields")){
function kentha_add_special_fields() {
	$qt_global_design_settings = array (

		array (
			'label' => esc_html__('Disable Page Background',"kentha"),
			'id' => 'kentha_disable_bg',
			'class' => 'qw-conditional-fields',
			'type' => 'select',
			'options' => array(
			  	array(
			   		'label' => __('Show background','kentha'),
					'value' => '',
					'revealfields'=>array('#kentha_image_bg','#kentha_video_bg','#kentha_video_start','#kentha_fadeout'),
					'hidefields'=>array()
				),
			    array(
			   		'label' => __('Hide background','kentha'),
					'value' => '1',
					'hidefields'=>array('#kentha_image_bg','#kentha_video_bg','#kentha_video_start','#kentha_fadeout'),
					'revealfields'=>array()
				),
			)
		),

		array (
			'label' => esc_html__('Background image',"kentha"),
			'id' =>  'kentha_image_bg',
			'desc'  => esc_html__('Override global background', 'kentha'),
			'type' => 'image'
		),
		array (
			'label' => esc_html__('Video background YouTube ID',"kentha"),
			'id' =>  'kentha_video_bg',
			'desc'  => esc_html__('Not the full youtube URL, only the ID', 'kentha'),
			'type' => 'text'
		),
		array (
			'label' => esc_html__('Video start cue (seconds)',"kentha"),
			'id' =>  'kentha_video_start',
			'desc'  => esc_html__('Integer number', 'kentha'),
			'type' => 'text'
		),
		array (
			'label' =>  esc_html__('Fade out background image or video on scroll',"kentha"),
			'id' =>  'kentha_fadeout',
			'desc'  => esc_html__('Override customizer defaults', 'kentha'),
			'type' 	=> 'select',
			'options' => array (
				array('label' => __('No',"kentha"),'value' => '0'),	
				array('label' => __('Yes',"kentha"),'value' => '1')
			)
		),
		array( // Repeatable & Sortable Text inputs
			'label'	=> esc_html__('Vertical Menu', 'kentha'), // <label>
			'desc'	=> esc_html__('Link to page sections', 'kentha') ,// description
			'pagetemplate' => 'page-visualcomposer.php',
			'id'	=> 'kentha_vertical_menu', // field id and name
			'type'	=> 'repeatable', // type of field
			'sanitizer' => array( // array of sanitizers with matching kets to next array
				'featured' => 'meta_box_santitize_boolean',
				'title' => 'sanitize_text_field',
				'desc' => 'wp_kses_data'
			),
			'repeatable_fields' => array ( // array of fields to be repeated
				'text' => array(
					'label' => esc_html__('Label', "kentha"),
					'id' => 'text',
					'type' => 'text',
				),
				'sectionid' => array(
					'label' => esc_html__('Section ID', 'kentha'),
					'id' => 'sectionid',
					'desc' => esc_html__( 'Edit a row in Visual Composer to add its ID', 'kentha' ),
					'type' => 'text'
				)
			)
		)
	);
	
	if(class_exists('custom_add_meta_box')){
		if(post_type_exists('page')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'page', true );
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'post', true );
		}
		if(post_type_exists('artist')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'artist', true );
		}
		if(post_type_exists('release')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'release', true );
		}
		if(post_type_exists('event')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'event', true );
		}
		if(post_type_exists('podcast')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'podcast', true );
		}
		if(post_type_exists('radiochannel')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'radiochannel', true );
		}

		if(post_type_exists('members')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'members', true );
		}
		if(post_type_exists('chart')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'chart', true );
		}
		if(post_type_exists('shows')){
			$main_box = new custom_add_meta_box('kentha_design_settings', 'Page settings', $qt_global_design_settings, 'shows', true );
		}

	}

}}

add_action('init', 'kentha_add_special_fields');  