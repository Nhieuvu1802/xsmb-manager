<?php
/*
Package: kentha
*/

if (!function_exists('kentha_short_textfx')){
function kentha_short_textfx($atts){
	extract( shortcode_atts( array(
		'text' => false,
		'fx' => 'tokyo',
		'color1' => '#dedede',
		'color2' => '#999',
		'color3' => '#f00',
	), $atts ) );


	$id = preg_replace('/[0-9]+/', '', uniqid('qttabs').'-'.kentha_slugify(esc_html($text))); 
	

	
	
	if($text){
		
		ob_start();
		?>
		<h2 id="<?php echo esc_attr($id); ?>" class="qt-center qt-<?php echo esc_attr($id); ?> qt-textfx-wrap qt-fontsize-h1">
			<?php  
			switch($fx){
				case "paris": 
					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--paris { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--paris span::before, .qt-'.$id.' .qt-txtfx--paris span::after { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--paris::before, .qt-'.$id.' .qt-txtfx--paris::after { background: '.esc_attr($color3).'}
					';
					$length = strlen($text);
					if ($length > 2){
						$splitted = str_split($text, round($length / 2));
						?>
						<span class="qt-txtfx qt-txtfx--paris"><span data-letters-l="<?php echo esc_html($splitted[0]); ?>" data-letters-r="<?php echo esc_html($splitted[1]); ?>"><?php echo esc_html($text); ?></span></span>
						<?php
					} else {
						esc_html_e("Warning: insert at least 2 letters for this effect", 'kentha');
					}
					break;
				case "oslo": 
					$length = strlen($text);
					$splitted = str_split($text, 1);
					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--oslo, .qt-'.$id.' .qt-'.$id.' .qt-txtfx--oslo::before { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--oslo.qt-txtfxstart span  { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--oslo::before { border-color: '.esc_attr($color3).'}
					';
					?>
					<span class="qt-txtfx qt-txtfx--oslo">
						<?php
						foreach($splitted as $letter){
							?><span><?php echo esc_html($letter); ?></span><?php 
						}
						?>
					</span>
					<?php
					break;
				case "ibiza": 

					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--ibiza, .qt-'.$id.' .qt-txtfx--ibiza.qt-txtfxstart { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--ibiza span::before { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--ibiza::after { background: '.esc_attr($color3).'}
					';
					?>
					<span class="qt-txtfx qt-txtfx--ibiza"><span  data-letters="<?php echo esc_html($text); ?>"><?php echo esc_html($text); ?></span></span>
					<?php
					break;
				case "newyork": 
					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--newyork { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--newyork span::before { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--newyork::before { background: '.esc_attr($color3).'}
					';
					?>					
					<span class="qt-txtfx qt-txtfx--newyork"><?php echo esc_html($text); ?><span data-letters="<?php echo esc_html($text); ?>"></span><span data-letters="<?php echo esc_html($text); ?>"></span></span>
					<?php 
					break;
				case "london": 
					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--london { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--london.qt-txtfxstart { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--london::before { background: '.esc_attr($color3).'}
					';
					?>
					<span class="qt-txtfx qt-txtfx--<?php echo esc_attr($fx); ?>" data-letters="<?php echo esc_html($text); ?>"><?php echo esc_html($text); ?></span>
					<?php
					break;
				case "tokyo":
				default:
					$style = '
					/* Shortcode dynamically generated CSS */
					.qt-'.$id.' .qt-txtfx--tokyo, .qt-'.$id.' .qt-txtfx--tokyo.qt-txtfxstart { color: '.esc_attr($color1).'}
					.qt-'.$id.' .qt-txtfx--tokyo::before { color: '.esc_attr($color2).'}
					.qt-'.$id.' .qt-txtfx--tokyo::after { background: '.esc_attr($color3).'}
					';
					?>
					<span class="qt-txtfx qt-txtfx--<?php echo esc_attr($fx); ?>" data-letters="<?php echo esc_html($text); ?>"><?php echo esc_html($text); ?></span>
					<?php
					break;
			}
			?>
		</h2>
		<?php
		

		wp_register_style( 'kentha-textfx', false ); // perfectly legit to avoid inline styling: https://www.cssigniter.com/late-enqueue-inline-css-wordpress/
		wp_enqueue_style( 'kentha-textfx' );
		wp_add_inline_style( 'kentha-textfx', wp_strip_all_tags($style) );

		return ob_get_clean();
	}
}}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode('kentha-shorttxtfx', 'kentha_short_textfx' );
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_short_textfx_vc' );
if(!function_exists('kentha_short_textfx_vc')){
function kentha_short_textfx_vc() {
  vc_map( array(
	"name" => esc_html__( "Text FX", "kentha" ),
	"base" => "kentha-shorttxtfx",
	"icon" => get_template_directory_uri(). '/img/caption-vc-shortcode.png',
	"description" => esc_html__( "Customizable full size card with photo background", "kentha" ),
	"category" => esc_html__( "Theme shortcodes", "kentha"),
	"params" => array(
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Text", "kentha" ),
		   "param_name" => "text"
		),
		array(
		   "type" => "colorpicker",
		   "heading" => esc_html__( "Color 1", "kentha" ),
		   "param_name" => "color1"
		),
		array(
		   "type" => "colorpicker",
		   "heading" => esc_html__( "Color 2", "kentha" ),
		   "param_name" => "color2"
		),
		array(
		   "type" => "colorpicker",
		   "heading" => esc_html__( "Color 3", "kentha" ),
		   "param_name" => "color3"
		),
		array(
		   "type" => "dropdown",
		   "heading" => esc_html__( "Effect", "kentha" ),
		   "param_name" => "fx",
		   "std" => "large",
		   'value' => array(
				esc_html__("Tokyo", "kentha")	=> "tokyo",
				esc_html__("London", "kentha")	=> "london",
				esc_html__("Paris", "kentha")	=> "paris",
				esc_html__("Ibiza", "kentha")	=> "ibiza",
				esc_html__("New York", "kentha")	=> "newyork",
				esc_html__("Oslo", "kentha")	=> "oslo",
				
			),
		   "description" => esc_html__( "Choose the size for the images", "kentha" )
		),
	)
  ) );
}}
