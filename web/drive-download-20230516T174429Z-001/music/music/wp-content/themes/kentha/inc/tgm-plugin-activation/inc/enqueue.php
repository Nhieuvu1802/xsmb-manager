<?php
/**
 * @package    TGM-Plugin-Activation
 * @subpackage kentha
 **/

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}
/* ADMIN CSS and Js loading
=============================================*/
if(!function_exists('kentha_tgm_admin_files_inclusion')){
function kentha_tgm_admin_files_inclusion() {
	wp_enqueue_style( 'kentha-tgm-admin', get_theme_file_uri('/inc/tgm-plugin-activation/css/kentha-tgm-admin.css' ), false, '1.0.0' );
}}
add_action( 'admin_enqueue_scripts', 'kentha_tgm_admin_files_inclusion', 999999 );