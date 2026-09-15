<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0.3
 * @version  2.0.3
 * @author QantumThemes 2020 Jan 25
 * 
 * Add custom software icon
 * 
 */

if ( ! class_exists( 'KENTHA_SOFTWARE_ICON' ) ) {
	class KENTHA_SOFTWARE_ICON {

		public function __construct() {
			// nothing here
		}
		 
		 /*
			* Initialize the class and start calling our hooks and filters
			* @since 1.0.0
		 */
		public function init() {

			$args = array(
			  'public'   => true
			  
			); 
			$output = 'objects'; // or objects
			$operator = 'and'; // 'and' or 'or'
			$taxonomies = get_taxonomies( $args, $output, $operator ); 
			// exclude the following:
			$exclude = array( );
			// Include only the following:
			$filter = array( 'tracksoftware' );
			foreach($taxonomies as $var => $taxonomy){
				 if( in_array( $taxonomy->name, $exclude ) ) {
		            continue;
		        }
		        if( !in_array( $taxonomy->name, $filter ) ) {
		            continue;
		        }
				add_action( $taxonomy->name.'_add_form_fields', array ( $this, 'add_category_image' ), 10, 2 );
				add_action( $taxonomy->name.'_edit_form_fields', array ( $this, 'update_category_image' ), 10, 2 );
				add_action( 'created_'.$taxonomy->name , array ( $this, 'save_category_image' ), 10, 2 );
				add_action( 'edited_'.$taxonomy->name, array ( $this, 'updated_category_image' ), 10, 2 );
			}
			add_action( 'admin_enqueue_scripts', array( $this, 'load_media' ) );
			add_action( 'admin_footer', array ( $this, 'add_script' ) );
		}

		public function load_media() {
		 	wp_enqueue_media();
			//  wp_enqueue_style( 'wp-color-picker' );
			// wp_enqueue_script( 'wp-color-picker');
			// wp_enqueue_script( 'wp-color-picker-script-handle', plugins_url('wp-color-picker-script.js', __FILE__ ), array( 'wp-color-picker' ), false, true );
		}
		 
		 /*
			* Add a form field in the new category page
			* @since 1.0.0
		 */
		 public function add_category_image ( $taxonomy ) { ?>
			<div class="form-field term-group">
				 <label for="kentha_software_icon"><?php esc_html_e('Software icon', 'kentha'); ?></label>
				 <input type="hidden" id="kentha_software_icon" name="kentha_software_icon" class="custom_media_url" value="">
				 <div id="category-image-wrapper"></div>
				 <p>
					 <input type="button" class="button button-secondary TTG_XTEND_media_button" id="TTG_XTEND_media_button" name="TTG_XTEND_media_button" value="<?php _e( 'Add icon', 'kentha' ); ?>" />
					 <input type="button" class="button button-secondary TTG_XTEND_media_remove" id="TTG_XTEND_media_remove" name="TTG_XTEND_media_remove" value="<?php _e( 'Remove icon', 'kentha' ); ?>" />
				</p>
			</div>

			<!-- <div class="form-field term-colorpicker-wrap">
				<label for="qt_taxonomy_color"><?php esc_html_e('Category Color', 'kentha'); ?></label>
				<input name="qt_taxonomy_color" value="#ffffff"  class="color-picker" id="qt_taxonomy_color" />
			</div> -->

		 	<?php
		 }
		 
		 /*
			* Save the form field
			* @since 1.0.0
		 */
		 public function save_category_image ( $term_id, $tt_id ) {
			 if( isset( $_POST['kentha_software_icon'] ) && '' !== $_POST['kentha_software_icon'] ){
				 $image = $_POST['kentha_software_icon'];
				 add_term_meta( $term_id, 'kentha_software_icon', $image, true );
			 }
		 }
		 
		 /*
			* Edit the form field
			* @since 1.0.0
		 */
		 public function update_category_image ( $term, $taxonomy ) { ?>

		 	<?php 
			/**
			 * Image uploader
			 */
			$image_id = get_term_meta ( $term->term_id, 'kentha_software_icon', true ); 
			?>
			<tr class="form-field term-group-wrap">
				<th scope="row">
					 <label for="kentha_software_icon"><?php esc_html_e( 'Icon', 'kentha' ); ?></label>
				</th>
				<td>
					<input type="hidden" id="kentha_software_icon" name="kentha_software_icon" value="<?php echo $image_id; ?>">
					<div id="category-image-wrapper">
						<?php if ( $image_id ) { ?>
							<?php echo wp_get_attachment_image ( $image_id, 'thumbnail' ); ?>
						<?php } ?>
					</div>
					<p>
						<input type="button" class="button button-secondary TTG_XTEND_media_button" id="TTG_XTEND_media_button" name="TTG_XTEND_media_button" value="<?php esc_attr_e( 'Add icon', 'kentha' ); ?>" />
						<input type="button" class="button button-secondary TTG_XTEND_media_remove" id="TTG_XTEND_media_remove" name="TTG_XTEND_media_remove" value="<?php esc_attr_e( 'Remove icon', 'kentha' ); ?>" />
					</p>
				</td>
			</tr>

			<?php 
			/**
			 * Color picker
			 * [$color saved color]
			 * @var [string]
			 */
			$color = get_term_meta( $term->term_id, 'qt_taxonomy_color', true );
    		$color = ( ! empty( $color ) ) ? "{$color}" : '#ffffff';

    		$is_color_enabled = false;
    		if( $is_color_enabled ){
				?>
				<tr class="form-field term-group-wrap">
					<th scope="row">
						<label for="qt_taxonomy_color"><?php esc_html_e('Category Color', 'kentha'); ?></label>
					</th>
					<td>
						<input name="qt_taxonomy_color" value="<?php echo esc_attr( $color ); ?>"  class="color-picker" id="$color" />
					</td>
				</tr>
				 <?php
			}
		 }

		/*
		 * Update the form field value
		 * @since 1.0.0
		 */
		 public function updated_category_image ( $term_id, $tt_id ) {


			 if( isset( $_POST['kentha_software_icon'] ) && '' !== $_POST['kentha_software_icon'] ){
				 $image = $_POST['kentha_software_icon'];
				 update_term_meta ( $term_id, 'kentha_software_icon', esc_attr( $image ) );
			 } else {
				 update_term_meta ( $term_id, 'kentha_software_icon', '' );
			 }


			 if( isset( $_POST['qt_taxonomy_color'] ) && '' !== $_POST['qt_taxonomy_color'] ){
			 	// wp_die('Has color'.$_POST['qt_taxonomy_color']);
				 $color = $_POST['qt_taxonomy_color'];
				 update_term_meta ( $term_id, 'qt_taxonomy_color',  $color  );
			 } else {
			 	
				 update_term_meta ( $term_id, 'qt_taxonomy_color', '' );
			 }
		 }

		/*
		 * Add script
		 * @since 1.0.0
		 */
		 public function add_script() { ?>
			 <script>
				 jQuery(document).ready( function($) {
					 function qt_taxonomy_media_upload(button_class) {
						 var _custom_media = true,
						 _orig_send_attachment = wp.media.editor.send.attachment;
						 $('body').on('click', button_class, function(e) {
							 var button_id = '#'+$(this).attr('id');
							 var send_attachment_bkp = wp.media.editor.send.attachment;
							 var button = $(button_id);
							 _custom_media = true;
							 wp.media.editor.send.attachment = function(props, attachment){
								 if ( _custom_media ) {
									 $('#kentha_software_icon').val(attachment.id);
									 $('#category-image-wrapper').html('<img class="custom_media_image" src="" style="margin:0;padding:0;max-height:100px;float:none;" />');
									 $('#category-image-wrapper .custom_media_image').attr('src',attachment.url).css('display','block');
								 } else {
									 return _orig_send_attachment.apply( button_id, [props, attachment] );
								 }
								}
						 wp.media.editor.open(button);
						 return false;
					 });
				 }
				 qt_taxonomy_media_upload('.TTG_XTEND_media_button.button'); 
				 $('body').on('click','.TTG_XTEND_media_remove',function(){
					 $('#kentha_software_icon').val('');
					 $('#category-image-wrapper').html('<img class="custom_media_image" src="" style="margin:0;padding:0;max-height:100px;float:none;" />');
				 });
				 // Thanks: http://stackoverflow.com/questions/15281995/wordpress-create-category-ajax-response
				 $(document).ajaxComplete(function(event, xhr, settings) {
					if(typeof(settings.data) === 'undefined'){
						return;
					}
					if( typeof(settings.data) !== 'undefined' ){
						if( typeof(settings.data.split) == 'function' ){
							 var queryStringArr = settings.data.split('&');
							 if( $.inArray('action=add-tag', queryStringArr) !== -1 ){
								 var xml = xhr.responseXML;
								 $response = $(xml).find('term_id').text();
								 if($response!=""){
									 // Clear the thumb image
									 $('#category-image-wrapper').html('');
								 }
							 }
						}
					}
				 });


				// color picker
				jQuery(document).ready(function($){
					$('.color-picker').each(function(){
						$(this).wpColorPicker();
						});
				});
			 });
		 </script>
		 <?php }

	}
	 

	function kentha_softwareicon_init(){
		$KENTHA_SOFTWARE_ICON = new KENTHA_SOFTWARE_ICON();
		$KENTHA_SOFTWARE_ICON -> init();
	}
	add_action('init', 'kentha_softwareicon_init', 9999);



	if(!function_exists('kentha_software_icon')){
		function kentha_software_icon($id){
			$softwares = get_the_terms( $id, 'tracksoftware');
			if(is_array($softwares)){
				foreach( $softwares as $sw ){
					if(is_object($sw)){
						$image_id = get_term_meta ( $softwares[0]->term_id, 'kentha_software_icon', true ); 
						if( $image_id ){
							echo '<span class="qt-swicon qt-btn-secondary">'.wp_get_attachment_image ( $image_id, 'thumbnail' ).'</span>';
						}
					}
				}
			}
			
			return false;
		}
	}
 
}