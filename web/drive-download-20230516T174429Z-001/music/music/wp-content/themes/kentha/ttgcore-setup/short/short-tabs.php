<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_tabs_shortcode')){
	function kentha_tabs_shortcode ($atts){
		extract( shortcode_atts( array(
			'class' => '',
			'items' => array(),
		), $atts ) );
		

		if(!function_exists('vc_param_group_parse_atts') ){
			return;
		}
		ob_start();
		if(is_array($atts)){
			if(array_key_exists("items", $atts)){
				$items = vc_param_group_parse_atts( $atts['items'] );
			}
		}
		if(is_array($items)){
			if(array_key_exists("title", $items[0])){
				$id = preg_replace('/[0-9]+/', '', uniqid('qttabs')); 
				?>
				<ul class="tabs qt-tabs qt-content-primary-dark qt-small">
					<?php  
					foreach($items as $item){
						if(array_key_exists("text", $item)){
							?>
							<li class="tab"><a href="#<?php echo esc_attr($id); echo kentha_slugify($item["title"]); ?>"><?php echo esc_html($item["title"]); ?></a></li>
							<?php
						}
					}
					?>
				</ul>
				<?php  
				foreach($items as $item){
					if(array_key_exists("text", $item)){
						?>
						<div id="<?php echo esc_attr($id); echo kentha_slugify($item["title"]); ?>" class="qt-paper qt-paddedcontent">
							<?php 
						    echo str_replace( ']]>', ']]&gt;', apply_filters( 'the_content', $item['text'] ) );
						    ?>
						</div>
						<?php
					}
				}
			}
		}
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-tabs","kentha_tabs_shortcode");
}







/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_tabs_shortcode_vc' );
if(!function_exists('kentha_tabs_shortcode_vc')){
function kentha_tabs_shortcode_vc() {
  vc_map( array(
	 "name" => esc_html__( "Tabs", "kentha" ),
	 "base" => "kentha-tabs",
	 "icon" => get_template_directory_uri(). '/img/tab-vc-shortcode.png',
	 "category" => esc_html__( "Theme shortcodes", "kentha"),
	 "params" => array(
		array(
			'type' => 'param_group',
			'value' => '',
			'param_name' => 'items',
			'params' => array(
				array(
				   "type" => "textfield",
				   "heading" => esc_html__( "Title", "kentha" ),
				   "param_name" => "title",
				   'value' => ''
				),
				array(
					'type' => 'textarea',
					'value' => '',
					'heading' => 'Content',
					'param_name' => 'text',
				)
			)
		),
		array(
		   "type" => "textfield",
		   "heading" => esc_html__( "Class", "kentha" ),
		   "param_name" => "class",
		   'value' => '',
		   'description' => 'add an extra class for styling with CSS'
		),
	 )
  ) );
}}