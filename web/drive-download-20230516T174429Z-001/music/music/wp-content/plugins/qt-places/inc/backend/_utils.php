<?php  
/**
 *	Utility functions
 * 
 */



if(!function_exists('qtHexToRGBA')){
function qtHexToRGBA($hex){
	$hex = str_replace('#', '', $hex);
    if (strlen($hex) == 3) {
        $hex = str_repeat(substr($hex,0,1), 2).str_repeat(substr($hex,1,1), 2).str_repeat(substr($hex,2,1), 2);
    }
    $r = hexdec(substr($hex,0,2));
    $g = hexdec(substr($hex,2,2));
    $b = hexdec(substr($hex,4,2));
    return $r.','.$g.','.$b;
}
}