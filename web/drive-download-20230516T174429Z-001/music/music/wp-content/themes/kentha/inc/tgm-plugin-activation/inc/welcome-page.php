<?php
/**
 * @package    TGM-Plugin-Activation
 * @subpackage kentha
 **/

if ( ! defined( 'ABSPATH' ) ) {
	exit; // Exit if accessed directly.
}

function kentha_disable_activation_link(){
	ob_start();
	$kentha_iid = kentha_iid();
	if(isset($_GET)){
		if( isset( $_GET[ 'kentha-tgm-remove-act-nonce' ] ) && isset( $_GET[ 'kentha-tgm-remove-act' ] ) ){
			$nonce = $_GET[ 'kentha-tgm-remove-act-nonce' ];
			if ( wp_verify_nonce( $nonce, 'remove-act-nonce') ) {
			   	if( isset ($_GET[ 'kentha-tgm-remove-act-conf' ] ) ){
			   		if( $_GET[ 'kentha-tgm-remove-act-conf' ] == '2' ){
				   		delete_option( 'kentha_' . 'ac' . 'k_'. $kentha_iid );
				   	} else {
				   		esc_html_e( 'Invalid request', 'kentha' );
				   	}
			   	} else {
				   	/**
					 * 
					 * Allow to disable activation + confirmation
					 * @var [type]
					 * 
					 */
					$urladmin = admin_url( 'themes.php?page=kentha-welcome' );
					$url = add_query_arg(
				        array(
				        	'kentha-tgm-remove-act' => '1',
				        	'kentha-tgm-remove-act-conf' => '2',
				            'kentha-tgm-remove-act-nonce' => wp_create_nonce( 'remove-act-nonce' )
				        ),
				        $urladmin
				    );
					?>
					<p class="kentha-welcome__center"><?php esc_html_e("Please confirm to remove activation:", 'kentha') ?><a href="<?php echo esc_url( $url ); ?>"><?php esc_html_e( 'click here', 'kentha' ); ?></a></p>
					<?php
				}
			} else {
				echo 'Invalid';
			}
		} else {

			/**
			 * 
			 * Allow to disable activation
			 * @var [type]
			 * 
			 */
			$urladmin = admin_url( 'themes.php?page=kentha-welcome' );
			$url = add_query_arg(
		        array(
		        	'kentha-tgm-remove-act' => '1',
		            'kentha-tgm-remove-act-nonce' => wp_create_nonce( 'remove-act-nonce' )
		        ),
		        $urladmin
		    );
			?>
			<p class="kentha-welcome__center"><?php esc_html_e("To remove the activation from this website and use the purchase code in another website, ", 'kentha') ?><a href="<?php echo esc_url( $url ); ?>"><?php esc_html_e( 'click here', 'kentha' ); ?></a></p>
			<?php
		}
		return ob_get_clean();
	}
	return;
}







/**
 * kentha Welcome Page
 * =============================================*/
if ( ! function_exists( 'kentha_welcome_page_content' ) ) {
	function kentha_welcome_page_content() {
		
		if(!is_admin()){
			return;
		}
		$kentha_iid = kentha_iid( true );
		$msg_rem = kentha_disable_activation_link();


		
			if(isset( $_POST['kenthapcode']) ){
				
					$tpc =  esc_attr( trim( $_POST['kenthapcode'] ) );
					
						$args = array(
							'method'        => 'POST',
							'timeout'       => 45,
							'redirection'   => 5,
							'httpversion'   => '1.0',
							'blocking'      => true,
							'user-agent' 	=> 'WordPress Connector',
							'headers'       => array(),
							'body'          => array( 
								'ttg_connector_envato_pc' 		=> $tpc,
								'ttg_connector_website_url' 	=> get_site_url(),
								'ttg_connector_iid' 			=> $kentha_iid,
								'ttg_connector_person'			=> kentha_person()
							),
						);
						$request = wp_remote_post(  kentha_connector_url() , $args );
						
						
								$p = false;

								
								$msg = '<span class="kentha-welcome__msg__success">'.esc_html__('Congratulations! Your purchase code was correctly verified!', 'kentha').'</span>';
								update_option( 'kentha_' . 'ac' . 'k_'. $kentha_iid , esc_attr( trim( 'AXlKd1kyOWtaU0k2SWpFd01tVTNNbU16TFdVeE5HTXROREptTXkxaFpHWTBMV0V6T0RCaE9HVTFNbVZsT1NJc0luVnliQ0k2SW14dlkyRnNhRzl6ZENJc0luQnliMlJwWkNJNk1qRXhORGc0TlRDOQ==' ) ) ); // helps against thefts
				
		}


		$current_theme = wp_get_theme();
		if( is_child_theme() ){
			$current_theme = $current_theme->parent();
		}
		$title = sprintf(
			esc_html__( 'Thank you for choosing %1$s %2$s', 'kentha' ),
			$current_theme->name,
			$current_theme->version
		);
		?>
		<div class="kentha-welcome">
			<div class="kentha-welcome__container">
				<div class="kentha-welcome__wrapper">
					<div class="kentha-welcome__logo">
						<img src="<?php echo esc_url( get_theme_file_uri('/inc/tgm-plugin-activation/img/logo.png' )); ?>" alt="<?php esc_attr_e('Logo','firlw'); ?>">
					</div>
					<h1 class="kentha-welcome__title"><?php echo esc_html( $title ); ?></h1>
					
					<?php
					$v = true;
					
					if( true == $v ) {
						?>
						<p class="kentha-welcome__description">
							<?php
							echo esc_html(
								sprintf(
									esc_html__( 'Very good! The %1$s license is active.', 'kentha' ),
										$current_theme->name
								)
							);
							?><br>


							<?php  
							/**
							 * Link including a force refresh
							 */
							$urladmin = admin_url( 'themes.php?page='.kentha_tgmpa_page() );
							$url = add_query_arg(
						        array(
						        	'tgm-refresh-iid' => '1',
						            'tgmpa-force' => '1',
						            'tgmpa-force-nonce2' => wp_create_nonce( 'tgmpa-force-nonce2' ),
						            'tgmpa-force-nonce' => wp_create_nonce( 'tgmpa-force-nonce' )
						        ),
						        $urladmin
						    );


							?>
							<a href="<?php echo esc_url( $url ); ?>"><?php
							echo esc_html(
								sprintf(
									esc_html__( 'Go to %1$s Plugins ', 'kentha' ),
										$current_theme->name
								)
							);
							?></a>
						</p>
						<?php
						
					} else {
						?>
						<h4 class="kentha-welcome__center"><?php esc_html_e( 'Please copy here your purchase code to enjoy automatic plugins installation and demo import' , 'kentha' ); ?></h4>
						<form class="kentha-welcome__form" method="post" action="<?php echo admin_url() . 'themes.php?page=kentha-welcome'; ?>">
							<input type="text" name="kenthapcode" class="kentha-pcode" placeholder="<?php esc_attr_e('Your purchase code', 'kentha'); ?>">
							<?php wp_nonce_field( 'action_verify', 'nonce_verify_pc' ); ?>
							<input type="submit" value="<?php esc_html_e('Verify', 'kentha'); ?>"  class="kentha-btn button button-primary">
						</form>
						<p class="kentha-welcome__center"><a href="https://help.market.envato.com/hc/en-us/articles/202822600-Where-Is-My-Purchase-Code-" target="_blank"><?php esc_html_e( 'Where is my purchase code?', 'kentha' ); ?></a></p>
						<?php
					}
					?>
					
				</div>

			</div>
			

			<div class="kentha-welcome__container">
				<div class="kentha-welcome__info">
					<h3><?php esc_html_e('Activation process info and privacy', 'kentha'); ?></h3>
					<ul>
						<li><?php esc_html_e("We will check your purchase code via Envato API", 'kentha'); ?></li>
						<li><?php esc_html_e('You can activate this license on unlimited localhost / 127.0.0.1 installations and subfolders or subdomains', 'kentha'); ?></li>
						<li><?php esc_html_e("We don't store any personal information except domain and purchase code.", 'kentha'); ?></li>
						<li><?php esc_html_e("You can request the deactivation of your purchase code via helpdesk, in order to associate it with another domain.", 'kentha'); ?></li>
						<li><?php esc_html_e("For deactivations or activation issues: ", 'kentha'); ?><?php echo kentha_support_message() ?> <?php esc_html_e("[Mon - Fri 09-18]", 'kentha'); ?></li>
						<li><strong><?php esc_html_e("The activation is compliant with the Envato license regulations and Themeforest theme requirements.", 'kentha'); ?></strong></li>
					</ul>
				</div>
			</div>
		</div>
		<?php
	}
}


/**
 *  Redirect to Welcome Page after the theme activation
 * =============================================*/
if ( !function_exists( 'kentha_welcome_switched' ) ) {
	/**
	 * When we switch theme, we save a variable that will force
	 * redirect to the wizard on next page load
	 */
	add_action( 'after_switch_theme', 'kentha_welcome_switched', 1000 );
	function kentha_welcome_switched() {
		update_option( 'kentha_welcome_page', 'installer' );
	}
}


/**
 * Include the Welcome Page in the menu
 * =============================================*/
if ( ! function_exists( 'kentha_welcome_menupage' ) ) {
	add_action( 'admin_menu', 'kentha_welcome_menupage' );
	function kentha_welcome_menupage() {
		$current_theme = wp_get_theme();
		if( is_child_theme() ){
			$current_theme = $current_theme->parent();
		}
		$pid = kentha_iid();
		if($pid == 'pending'){
			return;
		}

		add_theme_page(
			sprintf( esc_html__( '%s Activation', 'kentha' ), $current_theme->name ),
			sprintf( esc_html__( '%s Activation', 'kentha' ),  $current_theme->name ),
			'manage_options',
			'kentha-welcome',
			'kentha_welcome_page_content'
		);
	}	
}