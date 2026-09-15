<?php  

/**
 * Buy links:
 * If I have only 1 link, the button sends to the link, if I have many, it creates a dropdown
 * @var [type]
 */
$id = get_the_id();
$eventslinks= get_post_meta($id,'eventrepeatablebuylinks',true);   
if(is_array($eventslinks)){
	/**
	 * Case 1 : have only one link
	 */
	if(count($eventslinks) == 1){
		if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
			// WooCommerce integration 
			$buylink = $eventslinks[0]['cbuylink_url'];
			if(is_numeric($buylink)) {
				$prodid = $buylink;
				$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
				?>

				<a href="<?php echo esc_url( $buylink ); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="qt-btn qt-btn-ghost qt-btn-l product_type_simple add_to_cart_button ajax_add_to_cart">
					<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
				</a>

				<?php  
			} else {
				?>

				<a href="<?php echo esc_url( $buylink ); ?>" class="qt-btn qt-btn-ghost qt-btn-l" rel="nofollow" target="_blank">
					<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
				</a>

				<?php
			}
		}
	/**
	 * Case 2 : many links
	 */
	} elseif(count($eventslinks) > 1) {
		if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
			?>
			<!-- Dropdown Trigger -->
			<a href="#" class="qt-btn dropdown-button qt-btn-ghost qt-btn-l" data-activates='dropdown-actions-event'>
				<i class="material-icons">shopping_cart</i> <?php esc_html_e( 'Buy tickets', 'kentha' ); ?>
			</a>
			<!-- Dropdown Structure -->
			<ul id='dropdown-actions-event' class='dropdown-content qt-dropdown-content'>
				<?php
				/*
				*
				*   Print the BUY links
				*	=======================================
				*/
				if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
					foreach($eventslinks as $b){ 
					  	if(isset($b['cbuylink_url'])){
						  	if($b['cbuylink_url']!=''){
								// WooCommerce integration 
								$buylink = $b['cbuylink_url'];
								if(is_numeric($buylink)) {
									$prodid = $buylink;
									$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
									?>
									<li><a href="<?php echo esc_url($buylink); ?>" data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="product_type_simple add_to_cart_button ajax_add_to_cart"><i class="material-icons">shopping_cart</i> <?php echo esc_html($b['cbuylink_anchor']); ?></a></li>
									<?php  
								} else {
									?>
									<li><a href="<?php echo esc_url($buylink); ?>" target="_blank"><i class="material-icons">shopping_cart</i> <?php echo esc_html($b['cbuylink_anchor']); ?></a></li>
									<?php
								}
						  	}
					  	}
					}
				}
				?>
			</ul>
			<?php
		}
	}
}
