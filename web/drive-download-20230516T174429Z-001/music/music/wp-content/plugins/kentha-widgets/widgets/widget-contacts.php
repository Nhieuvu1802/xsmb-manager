<?php
/*
Package: Kentha Widgets
Description: WIDGET CONTACTS
Version: 0.0.0
Author: QantumThemes
Author URI: http://www.qantumthemes.xyz
*/

add_action( 'widgets_init', 'kentha_widgets_contacts_widget' );
function kentha_widgets_contacts_widget() {
	register_widget( 'kentha_widgets_Contacts_widget' );
}

class kentha_widgets_Contacts_widget extends WP_Widget {
	/**
	 * [__construct]
	 * =============================================
	 */
	public function __construct() {
		$widget_ops = array( 'classname' => 'qt_contactswidget', 'description' => esc_attr__('Display an icon list of website, telephone and other contacts', "kentha-widgets") );
		$control_ops = array( 'width' => 300, 'height' => 350, 'id_base' => 'qt_contacts-widget' );
		parent::__construct( 'qt_contacts-widget', esc_attr__('QT Contacts', "kentha-widgets"), $widget_ops, $control_ops );
	}
	/**
	 * [widget]
	 * =============================================
	 */
	public function widget( $args, $instance ) {
		extract( $args );
		echo $before_widget;
		if(array_key_exists("title",$instance)){
			echo $before_title.apply_filters("widget_title", $instance['title'], "qt_contacts-widget").$after_title; 
		}
		?>


		<div class="qt-widget-contacts">

			<?php  
			if(array_key_exists("link",$instance)){
				if($instance['link'] != ''){
					?>
					<p>
						<i class='material-icons'>home</i><a href="<?php echo esc_url($instance['link']); ?>"><?php echo esc_attr($instance['link']); ?></a>
					</p>
					<?php  
				}			
			}
			?>

			<?php  
			if(array_key_exists("phone",$instance)){
				if($instance['phone'] != ''){
					?>
					<p>
						<i class='material-icons'>phone_android</i><a href="tel:<?php echo esc_url($instance['phone']); ?>"><?php echo esc_attr($instance['phone']); ?></a>
					</p>
					<?php  
				}			
			}
			?>

			<?php  
			if(array_key_exists("email",$instance)){
				if($instance['email'] != ''){
					?>
					<p>
						<i class='material-icons'>email</i><a href="mailto:<?php echo esc_attr($instance['email']); ?>"><?php echo esc_attr($instance['email']); ?></a>
					</p>
					<?php  
				}			
			}
			?>

			<?php  
			if(array_key_exists("address",$instance)){
				if($instance['address'] != ''){

					$googleaddress = $instance['address'];
					if(array_key_exists("address2",$instance)){
						$googleaddress .= $instance['address2'];
					}
					$googleaddress = str_replace(" ", "+", $googleaddress);
					?>
					<p>
						<i class='material-icons'>location_on</i><a href="http://maps.google.com/?q=<?php echo esc_attr($googleaddress); ?>" target="_blank"><?php echo esc_attr($instance['address']); ?>
						<?php  
						if(array_key_exists("address2",$instance)){
							if($instance['address2'] != ''){
								?>
								 / <?php echo esc_attr($instance['address2']); ?>
								<?php  
							}			
						}
						?>
						</a>
					</p>
					<?php  
				}			
			}
			?>
			
			
		</div>

		<?php
		echo $after_widget;
	}

	/**
	 * [update save the parameters]
	 * =============================================
	 */
	public function update( $new_instance, $old_instance ) {
		$instance = $old_instance;
		//Strip tags from title and name to remove HTML 

		$attarray = array(
			'title',
			'phone',
			'link',
			'address',
			'address2',
			'email'
		);
		foreach ($attarray as $a){
			$instance[$a] = strip_tags( $new_instance[$a] );
		}
		return $instance;
	}

	/**
	 * [form widget parameters form]
	 * =============================================
	 */
	public function form( $instance ) {
		$defaults = array( 
				'title' => esc_attr__('Contacts', "kentha-widgets"),
				'phone' => "",
				'link' => "",
				'address' => "",
				'address2' => "",
				'email' => ""
				);

		$instance = wp_parse_args( (array) $instance, $defaults ); ?>
	 	<h2><?php echo esc_attr__("Options", "kentha-widgets"); ?></h2>
		<p>
			<label for="<?php echo $this->get_field_id( 'title' ); ?>"><?php echo esc_attr__('Title:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'title' ); ?>" name="<?php echo $this->get_field_name( 'title' ); ?>" value="<?php echo $instance['title']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'phone' ); ?>"><?php echo esc_attr__('Telephone number', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'phone' ); ?>" name="<?php echo $this->get_field_name( 'phone' ); ?>" value="<?php echo $instance['phone']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'link' ); ?>"><?php echo esc_attr__('Website URL:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'link' ); ?>" name="<?php echo $this->get_field_name( 'link' ); ?>" value="<?php echo $instance['link']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'email' ); ?>"><?php echo esc_attr__('Email:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'email' ); ?>" name="<?php echo $this->get_field_name( 'email' ); ?>" value="<?php echo $instance['email']; ?>" style="width:100%;" />
		</p>

		<p>
			<label for="<?php echo $this->get_field_id( 'address' ); ?>"><?php echo esc_attr__('Address:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'address' ); ?>" name="<?php echo $this->get_field_name( 'address' ); ?>" value="<?php echo $instance['address']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'address2' ); ?>"><?php echo esc_attr__('Address line 2:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'address2' ); ?>" name="<?php echo $this->get_field_name( 'address2' ); ?>" value="<?php echo $instance['address2']; ?>" style="width:100%;" />
		</p>
	<?php
	}
}
