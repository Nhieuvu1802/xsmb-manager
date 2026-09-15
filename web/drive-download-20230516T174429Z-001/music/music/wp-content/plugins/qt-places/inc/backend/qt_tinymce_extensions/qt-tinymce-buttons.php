<?php
/**
 *
 *	The shortcodes tinymce buttons
 *
 * 
 */

/**
 *
 *	Adding the shortcode to the PHP
 *
 * 
 */
if(!function_exists('qtplaces_enqueue_plugin_scripts_tinymce')){
function qtplaces_enqueue_plugin_scripts_tinymce($plugin_array)
{
    $plugin_array["qtplaces_shortcodes_plugin"] =    plugins_url( '/assets/qt-js-tinymce.js', __FILE__) ;
    return $plugin_array;
}}

add_filter("mce_external_plugins", "qtplaces_enqueue_plugin_scripts_tinymce");


/**
 *
 *	Adding the button to the editor
 *
 * 
 */
if(!function_exists('qtplaces_register_buttons_editor')){
	function qtplaces_register_buttons_editor($buttons)
	{
	    //register buttons with their id.
	    array_push($buttons, "qtplaces");
	    return $buttons;
	}
	add_filter("mce_buttons", "qtplaces_register_buttons_editor");
}

