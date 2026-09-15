<?php  
/**
 * @package QT Chartvote
 * 
 */

/**
* A piece of script is in this plugin (qt-chartvote-sript.js) for the ajax update,
* while for the click there is a piece in qt-main.js because it needs to be executed before the collapsible
 */

if(!function_exists('qt_chartvote_buttons')){
	function qt_chartvote_buttons($chartid, $position, $vote){
		ob_start();
		?>
				<div id="chartvoting<?php echo esc_attr($position); ?>" class="qt-chartvote">
					<a class="qt-chartvote-link not-collapse qt-up" 	data-ip="<?php echo esc_attr($_SERVER['REMOTE_ADDR']); ?>" data-move="1" data-chartid="<?php echo esc_attr($chartid); ?>" data-position="<?php echo esc_attr($position); ?>" ><i class=" dripicons-chevron-up"></i></a>
					<span class="qt-chartvote-number"><?php echo esc_html($vote); ?></span>
					<a class="qt-chartvote-link not-collapse qt-down"  	data-ip="<?php echo esc_attr($_SERVER['REMOTE_ADDR']); ?>" data-move="-1" data-chartid="<?php echo esc_attr($chartid); ?>" data-position="<?php echo esc_attr($position); ?>" ><i class=" dripicons-chevron-down"></i></a>
				</div>
		<?php
		return ob_get_clean();
	}
}