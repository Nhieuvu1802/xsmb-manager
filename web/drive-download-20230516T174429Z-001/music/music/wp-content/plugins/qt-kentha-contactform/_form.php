<?php
if (!function_exists('qt_kentha_contactform')){
	function qt_kentha_contactform(){
		ob_start();
		$submission_nonce = wp_create_nonce( 'contactform_sending_secret-'.get_the_id() );
		$recipient = get_post_meta(get_the_id(), "qt_contacts_recipient", true);
		$subject =  esc_html__("Contact from your website", "qt-kentha-contactform");		
		?>
		<!-- ====================== SECTION BOOKING AND CONTACTS ================================================ -->
		<div id="kentha-contactform"  class="row qt-bookingform">
			<form class="col s12" method="post" action="<?php echo add_query_arg("qtSendEmail","1", get_the_permalink()); ?>#kentha-contactform">
				<div class="row">
					<div class="input-field col s12 m6">
						<input name="first_name" id="first_name" type="text" class="validate" 
						value="<?php if(array_key_exists('first_name', $_POST)){ esc_attr_e($_POST['first_name']); } ?>"
						>
						<label for="first_name"><?php esc_html_e("Name", 'qt-kentha-contactform'); ?></label>
					</div>
					<div class="input-field col s12 m6">
						<input name="last_name" id="last_name" type="text" class="validate" value="<?php if(array_key_exists('last_name', $_POST)){  esc_attr_e($_POST['last_name']); } ?>">
						<label for="last_name"><?php esc_html_e("Last name", 'qt-kentha-contactform'); ?></label>
					</div>
				</div>
				<div class="row">
					<div class="input-field col s12 m12">
						<input name="email" id="email" type="email" class="validate"  value="<?php if(array_key_exists('email', $_POST)){  esc_attr_e($_POST['email']); } ?>">
						<label for="email"><?php esc_html_e("Email", 'qt-kentha-contactform'); ?></label>
					</div>
					<div class="input-field col s12 m12">
						<input name="phone" id="phone" type="text" class="validate" value="<?php if(array_key_exists('phone', $_POST)){  esc_attr_e($_POST['phone']); } ?>">
						<label for="phone"><?php esc_html_e("Phone", 'qt-kentha-contactform'); ?></label>
					</div>
				</div>
				<div class="row">
					<div class="input-field col s12 m12">
						<textarea name="message" id="message" class="materialize-textarea"><?php if(array_key_exists('message', $_POST)){  esc_attr_e($_POST['message']); } ?></textarea>
						<label for="message"><?php esc_html_e("Message", 'qt-kentha-contactform'); ?></label>
					</div>
					<?php  
					$qt_contacts_privacy = get_post_meta(get_the_id(), 'qt_contacts_privacy', true);
					if($qt_contacts_privacy != ''):
					?>
					<div class="row">
						<div class="input-field col s12">
							<input name="privacy" type="checkbox" id="privacy" value="1" />
							<label for="privacy"><?php echo esc_attr__("I accept the", "qt-kentha-contactform"); ?> <a href="<?php echo esc_url($qt_contacts_privacy) ?>" target="_blank"><?php echo esc_attr__("privacy terms", "qt-kentha-contactform"); ?></a>.</label>
						</div>
					</div>
					<?php endif; ?>
					<div class="input-field col s12 m12">
						<input id="submit" value="<?php esc_attr_e( 'Send request', 'qt-kentha-contactform' ) ?>" type="submit" class="qt-btn qt-btn-primary qt-btn-xl qt-full">
					</div>
				</div>
				<?php  
				/**
				 * 	Anti-XSS protection with WP nonce:
				 * 	=======================================================
				 */
				?>
				<input type="hidden" name="_qtform_snonce" value="<?php echo esc_attr($submission_nonce); ?>">
				<?php  
				/**
				 * 	Hidden antispam field:
				 * 	=======================================================
				 */
				?>
				<p class="qt-antispam qt-hidden"><input type="text" name="url" /></p>
			</form>
		</div>
		<!-- ====================== SECTION BOOKING AND CONTACTS END ================================================ -->
		<?php  
		/**
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 * 
		 * Submission autenticity test for safety against spam attacks
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 *
		 * 
		 */
		if(isset($_POST) && isset($_GET) && $recipient != ''){
			if(array_key_exists("_qtform_snonce", $_POST) && array_key_exists('qtSendEmail', $_GET)) {
				/**
				 * 	Antispam check
				 * 	===============================
				 */
				if(array_key_exists('url', $_POST)) {
					if($_POST['url'] !== '') {
						die( 'Security check failed. Spam attempt detected' ); 
					}
				}
				
				$nonce = $_POST['_qtform_snonce'];
				if ( ! wp_verify_nonce( $nonce, 'contactform_sending_secret-'. get_the_id() ) ) {
					// This nonce is not valid.
					die( 'Security check failed. Spam attempt detected' ); 
				} else {

					

					//======================================================
					
					//DYNAMIC EMAIL SENDING CODE

					//======================================================
					$fields = array('first_name','last_name','email','message'); // LIST OF THE FIELDS

					$qt_contacts_privacy = get_post_meta(get_the_id(), 'qt_contacts_privacy', true);
					if($qt_contacts_privacy != ''){
						$fields[] = 'privacy';
					}


					$errors = ''; // ERROR MESSAGE
					// FOR EVERY FIELD WE CHECK IF IT'S COMPILED, OTHERWISE DISPLAY THE ERROR
					foreach($fields as $fieldname){
						if(!array_key_exists($fieldname, $_POST)) { // FIELD NOT EXISTING
							$errors .= $fieldname.', ';
						} else {
							if($_POST[$fieldname] == ''){ // OR FIELD EMPTY
								$errors .= $fieldname.', ';
							}
						}
					}
					if($errors != '') { // IF WE HAVE ERRORS, DISPLAY THE ERROR MESSAGE
						$errors = str_replace("_", " ", rtrim( $errors, ', '));
						?>
						<div class="qt-contactform-error">
							<h5 class="qt-section-title"><?php  esc_html_e("Error: Some fields are missing","qt-kentha-contactform"); ?></h5>
						</div>
						<?php  
					} else { // IF ALL FIELDS ARE COMPILED LET'S GO ON
						if(isset($_POST['privacy'])){
							$privacy = $_POST['privacy'];
						}
						$first_name = $_POST['first_name'];
						$last_name = $_POST['last_name'];
						$email = $_POST['email'];
						$message = str_replace("\n.", "\n..",$_POST['message']);

						$message .= "\n..Phone: ". $_POST['phone'];

						$headers = 'From: '.$first_name.' '.$last_name.' <' . $email .'>'."\r\n" .
							'Reply-To:  '.$first_name.' '.$last_name.' <' . $email .'>'."\r\n" .
							'X-Mailer: PHP/' . phpversion();
						if(wp_mail($recipient, $subject, $message, $headers)){
							?>
							<div class="qt-contactform-success">
								<h5 class="qt-section-title"><?php esc_html_e("Message sent Thank you, we will answer as soon as possible","qt-kentha-contactform"); ?><i class="deco"></i></h5>
								
							</div>
							<hr class="qt-spacer-m">
							<?php  
						} else {
							?>
							<div class="qt-contactform-error">
								<h5 class="qt-section-title"><?php esc_html_e("Sorry, because of a technical error is not possible to delivery your message. Please write us manually at our email address.","qt-kentha-contactform"); ?><i class="deco"></i></h5>
								<hr class="qt-spacer-m">
							</div>
							<hr class="qt-spacer-m">
							<?php  
						}
					}
				}
			}
		}

		return ob_get_clean();
	}
} // function end

add_shortcode("qt-kentha-contactform", "qt_kentha_contactform");


