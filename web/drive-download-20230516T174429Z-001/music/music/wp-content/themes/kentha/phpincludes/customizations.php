<?php
/*
Package: kentha
*/
if(!function_exists('kentha_hex2rgba')){
function kentha_hex2rgba($color, $opacity = false) {
	$default = 'rgb(0,0,0)';
	if(empty($color)) {
		return $default; 
	}
	if ($color[0] == '#' ) {
		$color = substr( $color, 1 );
	}
	//Check if color has 6 or 3 characters and get values
	if (strlen($color) == 6) {
			$hex = array( $color[0] . $color[1], $color[2] . $color[3], $color[4] . $color[5] );
	} elseif ( strlen( $color ) == 3 ) {
			$hex = array( $color[0] . $color[0], $color[1] . $color[1], $color[2] . $color[2] );
	} else {
			return $default;
	}
	//Convert hexadec to rgb
	$rgb =  array_map('hexdec', $hex);
	//Check if opacity is set(rgba or rgb)
	
	if($opacity == false && $opacity != 0){
		$opacity = 1;
	}
	$output = 'rgba('.implode(",",$rgb).','.$opacity.')';
	//Return rgb(a) color string
	return $output;
}}

add_action('wp_head','kentha_css_customizations',1000);
if(!function_exists('kentha_css_customizations')){
	function kentha_css_customizations(){
		
		/**
		 * Colors from customizer
		 * ==========================
		 */

		$qt_primary_color= get_theme_mod( 'kentha_primary_color', "#454955");
		$qt_primary_color_light= get_theme_mod( 'kentha_primary_color_light', "#565c68");
		$qt_primary_color_dark= get_theme_mod( 'kentha_primary_color_dark', "#101010");
		$qt_color_accent= get_theme_mod( 'kentha_color_accent', "#00fcff");
		$qt_color_accent_hover= get_theme_mod( 'kentha_color_accent_hover', "#01b799");
		$qt_color_secondary= get_theme_mod( 'kentha_color_secondary', "#ff0d51");
		$qt_color_secondary_hover= get_theme_mod( 'kentha_color_secondary_hover', "#c60038");
		$qt_color_background= get_theme_mod( 'kentha_color_background', "#444");
		$qt_color_paper= get_theme_mod( 'kentha_color_paper', "#131617");
		$qt_textcolor_original = get_theme_mod( 'kentha_textcolor_original', "#fff");
		$kentha_textcolor_primary = get_theme_mod( 'kentha_textcolor_primary', "#fff"); // color of text when on top of primary color
		$kentha_textcolor_menu = get_theme_mod('kentha_textcolor_menu', '#fff');
		$kentha_textcolor_on_buttons = get_theme_mod( 'kentha_textcolor_on_buttons', '#fff' );


		/**
		 * Derivated colors (calculated from the originals by alpha change following material design principles)
		 * ==========================
		 */
		$qt_text_color= kentha_hex2rgba($qt_textcolor_original, 0.87);
		$qt_text_color_secondary= kentha_hex2rgba($qt_textcolor_original, 0.65);
		$qt_titles_color= kentha_hex2rgba($qt_textcolor_original, 1);
		$qt_text_color_aside= kentha_hex2rgba($qt_textcolor_original, 0.65);
		$qt_text_color_divider_and_hints= kentha_hex2rgba($qt_textcolor_original, 0.38);
		$qt_backgorund_lightcolor= kentha_hex2rgba($qt_textcolor_original, 0.1);
		$qt_text_color_negative= $qt_color_paper;
		$qt_text_color_negative_light= kentha_hex2rgba($qt_color_paper, 0.65);
	?>

	<!-- THEME CUSTOMIZER SETTINGS INFO   ================================ -->

	<!-- qt_primary_color: <?php echo esc_attr($qt_primary_color); ?> -->
	<!-- qt_primary_color_light: <?php echo esc_attr($qt_primary_color_light); ?> -->
	<!-- qt_primary_color_dark: <?php echo  esc_attr($qt_primary_color_dark); ?> -->
	<!-- qt_color_accent: <?php echo esc_attr($qt_color_accent); ?> -->
	<!-- qt_color_accent_hover: <?php echo esc_attr($qt_color_accent_hover); ?> -->
	<!-- qt_color_secondary: <?php echo esc_attr($qt_color_secondary); ?> -->
	<!-- qt_color_secondary_hover: <?php echo esc_attr($qt_color_secondary_hover); ?> -->
	<!-- qt_color_background: <?php echo esc_attr($qt_color_background); ?> -->
	<!-- qt_color_paper: <?php echo esc_attr($qt_color_paper); ?> -->
	<!-- qt_textcolor_original: <?php echo esc_attr($qt_textcolor_original); ?> -->

	<!-- ===================================================== -->

	<!-- QT STYLES DYNAMIC CUSTOMIZATIONS ========================= -->
	<style>
	<?php
	ob_start();
	echo '
	body, html, .qt-nclinks a, .qt-btn.qt-btn-ghost, .qt-paper h1, .qt-paper h2, .qt-paper h3, .qt-paper h4, .qt-paper h5, .qt-paper h6, .qt-paper  {
		color: '.$qt_text_color.'; 
	}
	.qt-slickslider-outercontainer .slick-dots li button {
		background: '.$qt_text_color.'; 
	}
	a {
		color: '.$qt_color_accent.';
	}
	a:hover {
		color: '.$qt_color_accent_hover.';
	}
	h1, h2, h3, h4, h5, h6 {
		color: '.$qt_titles_color.';
	}
	.dropdown-content li > a, .dropdown-content li > span, .qt-part-archive-item.qt-open .qt-headings .qt-tags a, .qt-link-sec, .qt-caption-small::after, .qt-content-aside a:not(.qt-btn), nav .qt-menu-secondary li a:hover, .qt-menu-secondary li.qt-soc-count a  {
		color: '.$qt_color_secondary.';
	}
	.qt-content-secondary, .qt-content-accent, .qt-btn-secondary, .qt-btn-primary, .qt-content-aside .qt-btn-primary , .qt-content-aside .qt-btn-secondary,  .qt-content-aside .tagcloud a, .qt-content-aside a.qt-btn-primary:hover, .qt-content-aside a.qt-btn-secondary:hover, input[type="submit"], .qt-part-archive-item.qt-open .qt-capseparator {
		color: '.$kentha_textcolor_on_buttons.';
	}
	.qt-content-primary, .qt-content-primary-dark, .qt-content-primary-light, .qt-content-primary-dark a, .tabs .tab a, .qt-mobilemenu a.qt-openthis, .qt-mobilemenu .qt-logo-text h2, li.qt-social-linkicon a i, 
	[class*=qt-content-primary] h1,
	[class*=qt-content-primary] h2,
	[class*=qt-content-primary] h3,
	[class*=qt-content-primary] h4,
	[class*=qt-content-primary] h5,
	[class*=qt-content-primary] h6
	 {
		color: '.$kentha_textcolor_primary.';
	}
	.qt-part-archive-item.qt-open .qt-iteminner .qt-header .qt-capseparator {
		border-color: '.$kentha_textcolor_on_buttons.';
		background: '.$kentha_textcolor_on_buttons.';
	}
	body.skrollable-between nav.qt-menubar ul.qt-desktopmenu > li > a, body.skrollable-between nav.qt-menubar .qt-menu-secondary li a, body.skrollable-between .qt-breadcrumb, .qt-breadcrumb a {
		color: '.$kentha_textcolor_menu.' !important;
	}
	.qt-desktopmenu-notscr .qt-morphbtn i span {
		border-color: '.$kentha_textcolor_menu.' !important; 
	}
	.tabs .tab a:hover {
		color: '.$qt_color_secondary_hover.';
	}
	.qt-content-secondary {
		color: #fff;
	}
	body, html, .qt-main{
		background-color: '.$qt_color_background.'; 
	}
	.qt-paper {
		background-color: '.$qt_color_paper.';
	}
	.qt-content-primary-light {
		background-color: '.$qt_primary_color_light.'; 
	}
	.qt-content-primary{
		background-color: '.$qt_primary_color.';
	}
	.qt-content-primary-dark, .is_ipad .qt-parentcontainer .qt-menubar  {
		background-color: '.$qt_primary_color_dark.'; 
	}
	.qt-content-accent, .qt-menubar ul.qt-desktopmenu li li::after,  input[type="submit"],  #qtBody.woocommerce .widget_price_filter .ui-slider .ui-slider-handle , #qtBody.woocommerce .widget_price_filter .ui-slider-horizontal .ui-slider-range  {
		background-color: '.$qt_color_accent.'; 
	}
	.qt-content-secondary, .qt-material-slider .indicator-item.active, .tabs .indicator, .qt-mobilemenu ul.qt-side-nav li.menu-item-has-children a.qt-openthis, .qt-capseparator {
		background-color: '.$qt_color_secondary.'; 
	}
	.qt-tags a, .tagcloud a {    
		background-color: '.$qt_color_secondary.';
	}
	.qt-part-archive-item.qt-open .qt-headings, .qt-btn-secondary, .qt-sectiontitle::after,  h2.widgettitle::after  {
		background-color: '.$qt_color_secondary.';
	}
	.qt-btn-primary , .qt-menubar ul.qt-desktopmenu > li.qt-menuitem > a::after, .qt-widgets .qt-widget-title::after, input[type="submit"] {
		background-color:'.$qt_color_accent.'; 
	}
	input:not([type]):focus:not([readonly]), input[type=text]:focus:not([readonly]), input[type=password]:focus:not([readonly]), input[type=email]:focus:not([readonly]), input[type=url]:focus:not([readonly]), input[type=time]:focus:not([readonly]), input[type=date]:focus:not([readonly]), input[type=datetime]:focus:not([readonly]), input[type=datetime-local]:focus:not([readonly]), input[type=tel]:focus:not([readonly]), input[type=number]:focus:not([readonly]), input[type=search]:focus:not([readonly]), textarea.materialize-textarea:focus:not([readonly]) {
		border-color:'.$qt_color_accent.'; 
		
	}
	ul.qt-side-nav.qt-menu-offc>li>a:not(.qt-openthis)::after, .qt-slickslider-outercontainer__center .qt-carouselcontrols i.qt-arr, .qt-btn.qt-btn-ghost, .qt-capseparator {
		border-color:'.$qt_color_secondary.'; 
	}
	input:not([type]):focus:not([readonly])+label, input[type=text]:focus:not([readonly])+label, input[type=password]:focus:not([readonly])+label, input[type=email]:focus:not([readonly])+label, input[type=url]:focus:not([readonly])+label, input[type=time]:focus:not([readonly])+label, input[type=date]:focus:not([readonly])+label, input[type=datetime]:focus:not([readonly])+label, input[type=datetime-local]:focus:not([readonly])+label, input[type=tel]:focus:not([readonly])+label, input[type=number]:focus:not([readonly])+label, input[type=search]:focus:not([readonly])+label, textarea.materialize-textarea:focus:not([readonly])+label {
		color: '.$qt_color_accent.'; 
	}
	@media only screen and (min-width: 1201px) {
		a:hover, h1 a:hover, h2 a:hover, h3 a:hover, h4 a:hover, h5 a:hover, h6 a:hover, .qt-btn.qt-btn-ghost:hover {
			color:'.$qt_color_accent_hover.'; 
		}
		.qt-content-aside a:hover, .qt-btn.qt-btn-ghost:hover {
			color: '.$qt_color_secondary_hover.';
		}
		.qt-btn-primary:hover, input[type="submit"]:hover {
			background-color:'.$qt_color_accent_hover.'; 
			color: #fff;
		}
		.qt-btn-secondary:hover, .qt-tags a:hover, .qt-mplayer:hover .qt-mplayer__play:hover, .qt-mplayer__volume:hover, .qt-mplayer__cart:hover, .qt-mplayer__prev:hover, .qt-mplayer__next:hover, .qt-mplayer__playlistbtn:hover {
			background-color: '.$qt_color_secondary_hover.';
			color: #fff;
		}
	}';

	/**
	 * ===================================================================================================================
	 * WooCommerce customizations
	 * ===================================================================================================================
	 */
	if ( class_exists( 'WooCommerce' ) ) {
		echo '
		.woocommerce div.product p.price, .woocommerce div.product span.price, .woocommerce ul.products li.product .price {color: '.$qt_color_secondary.' !important; }
		.qt-body.woocommerce li.product{ background-color: '.$qt_color_paper.' !important; }
		.qt-body.woocommerce div.product .woocommerce-tabs ul.tabs li.active, .qt-accent, .woocommerce #respond input#submit, .woocommerce a.button, .woocommerce button.button, .woocommerce input.button, .woocommerce button.button.alt { background-color: '.$qt_color_accent.' !important; color: '.$kentha_textcolor_on_buttons.';  }
		.woocommerce span.onsale, .woocommerce #respond input#submit.alt .woocommerce a.button.alt, .woocommerce input.button.alt { background-color: '.$qt_color_secondary.' !important }
		.woocommerce #respond input#submit:hover, .woocommerce a.button:hover, .woocommerce button.button:hover, .woocommerce input.button:hover, .woocommerce-tabs ul.tabs li:hover, .woocommerce button.button.alt:hover { background-color:'.$qt_color_accent_hover.' !important; color: '.$kentha_textcolor_on_buttons.';  }
	    ';
	}
	/**
	 * ===================================================================================================================
	 * WooCommerce end
	 * ===================================================================================================================
	 */
	?>
	</style>
	<?php
	$output = ob_get_clean();
	$output = str_replace(array("	","\n","  "), " ", $output);
	$output = str_replace("  ", " ", $output);
	$output = str_replace("  ", " ", $output);
	$output = str_replace(" { ", "{", $output);
	$output = str_replace("} .", "}.", $output);
	$output = str_replace("; }", ";}", $output);
	$output = str_replace(", .", ",.", $output);
	$output .= "\n<!-- QT STYLES DYNAMIC CUSTOMIZATIONS END ========= -->\n\n\n";
	echo kentha_sanitize_content($output) ;
}}






