<?php  
///////////////// THIS TEMPLATE IS UNUSED
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
			?>
			<a href="<?php  echo esc_url($eventslinks[0]['cbuylink_url']); ?>" class="btn-floating qt-btn-primary" rel="nofollow" target="_blank">
				<i class="material-icons">shopping_cart</i> <?php echo esc_html( $eventslinks[0]['cbuylink_anchor'] ); ?>
			</a>
			<?php
		}
	} elseif(count($eventslinks) > 1) {
		if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
			?>
			<!-- Dropdown Trigger -->
			<a href="#" class="btn-floating dropdown-button qt-btn-primary" data-activates='dropdown-actions-event-<?php echo esc_attr($id); ?>'>
				<i class="material-icons">shopping_cart</i> <?php esc_html_e( 'Buy tickets', 'kentha' ); ?>
			</a>
			<!-- Dropdown Structure -->
			<!-- <ul id='dropdown-actions-event-<?php echo esc_attr($id); ?>' class='dropdown-content qt-dropdown-content'>
				<?php
				/*
				*
				*   Print the BUY links
				*	=======================================
				*/
				$eventslinks= get_post_meta($id,'eventrepeatablebuylinks',true);   
				if(is_array($eventslinks)){
				  	if(count($eventslinks)>0){
						if($eventslinks[0]['cbuylink_url'] != '' && $eventslinks[0]['cbuylink_anchor']){
							foreach($eventslinks as $b){ 
							  	if(isset($b['cbuylink_url'])){
								  	if($b['cbuylink_url']!=''){
										?>
										<li><a href="<?php echo esc_url($b['cbuylink_url']); ?>"><i class="material-icons">shopping_cart</i> <?php echo esc_html($b['cbuylink_anchor']); ?></a></li>
										<?php
								  	}
							  	}
							}
						}
					}
				}
				?>
				<li><a href="#!"><i class="material-icons">close</i> <?php esc_attr_e('Close', 'kentha'); ?></a></li>
			</ul> -->
			<?php
		}
	}
}
