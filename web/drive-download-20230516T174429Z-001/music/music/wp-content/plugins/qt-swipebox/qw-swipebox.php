<?php
/*
Plugin Name: QT Swipebox Photo And Video
Plugin URI: http://qantumthemes.com/
Description: Enable the swipebox for the galleries
Author: QantumThemes
Version: 2.1
*/

function qt_swipebox_loader(){
	wp_enqueue_script( 'swipebox',plugins_url( '/min/qt-swipebox-min.js' , __FILE__ ), $deps = array("jquery"), $ver = false, $in_footer = true );
	wp_enqueue_style( 'QtswipeStyle',plugins_url( '/swipebox/css/swipebox.min.css' , __FILE__ ),false);
}
add_action("wp_enqueue_scripts",'qt_swipebox_loader');

