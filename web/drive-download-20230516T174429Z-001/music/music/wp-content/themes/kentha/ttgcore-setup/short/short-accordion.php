<?php  
/*
Package: kentha
*/

/**
 * 
 * Featured list with titles links and bullet list
 * =============================================
 */
if(!function_exists('kentha_accordion_shortcode')){
	function kentha_accordion_shortcode ($atts){
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
			$id = preg_replace('/[0-9]+/', '', uniqid('qttabs')); 
			if(array_key_exists("title", $items[0])){
				?>
				<ul class="collapsible qt-collapsible" data-collapsible="accordion">
					<?php  
					foreach($items as $item){
						if(array_key_exists("text", $item)){
							?>
							<li>
								<div class="collapsible-header qt-content-primary-dark"><i class="material-icons">add</i><?php echo esc_html($item["title"]); ?></div>
								<div class="collapsible-body qt-paper">
									<div class="qt-paddedcontent">
									<?php  
									if(array_key_exists("text", $item)){
										echo str_replace( ']]>', ']]&gt;', apply_filters( 'the_content', $item['text'] ) );
									}
									?>
									</div>
								</div>

							</li>
							<?php
						}
					}
					?>
				</ul>
				<?php
			}
		}
		return ob_get_clean();
	}
}
if(function_exists('ttg_custom_shortcode')) {
	ttg_custom_shortcode("kentha-accordion","kentha_accordion_shortcode");
}


/**
 *  Visual Composer integration
 */
add_action( 'vc_before_init', 'kentha_accordion_shortcode_vc' );
if(!function_exists('kentha_accordion_shortcode_vc')){
function kentha_accordion_shortcode_vc() {
  vc_map( array(
	 "name" => esc_html__( "Accordion", "kentha" ),
	 "base" => "kentha-accordion",
	 "icon" => get_template_directory_uri(). '/img/accordion-vc-shortcode.png',
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