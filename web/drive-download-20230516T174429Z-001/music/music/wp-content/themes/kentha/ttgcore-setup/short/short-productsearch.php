<?php
/*
Package: Kentha
*/

if(!function_exists('kentha_short_productsearch')) {
	function kentha_short_productsearch($atts){
		extract( shortcode_atts( array(
			'class' => ''
		), $atts ) );

		ob_start();
		?>
		<div class="<?php echo esc_attr( $class ); ?>">
		<form method="get" class="form-horizontal qw-searchform" action="<?php echo esc_url( home_url( '/' ) ); ?>" role="search">
			<input type="hidden" name="post_type" value="product" />
			<div class="input-field">
				<i class="material-icons prefix">search</i>
				<input value="<?php echo esc_attr(get_search_query()); ?>" name="s" class="qt-input-fullwidth" placeholder="<?php echo esc_attr_x( 'Search: type and hit enter &hellip;', 'placeholder', 'kentha' ); ?>" type="text" />
			</div>
		</form>
		</div>
		<?php  
		return ob_get_clean();
	}
}

if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-productsearch","kentha_short_productsearch");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_productsearch_vc' );
if(!function_exists('kentha_short_productsearch_vc')){
function kentha_short_productsearch_vc() {
	vc_map( array(
		"name" => esc_html__( "Product search", "kentha" ),
		"base" => "kentha-productsearch",
		"icon" => get_template_directory_uri(). '/img/wc-carousel.png',
		"category" => esc_html__( "Theme shortcodes", "kentha"),
		"params" 		=> array(
			array(
				"type" 			=> "textfield",
				"heading" 		=> esc_html__( "Class", "kentha" ),
				"param_name" 	=> "class",
				'value' 		=> '',
				'description' 	=> 'add an extra class for styling with CSS'
			)
		)
	));
}}


		



