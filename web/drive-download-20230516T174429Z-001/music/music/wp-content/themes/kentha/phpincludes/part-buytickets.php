<?php  
$data = get_post_meta(get_the_id(), 'eventrepeatablebuylinks', false);
if(array_key_exists(0, $data)){
$data = $data[0];
if(count($data)>0){
  	if($data[0]['cbuylink_url'] !== ''){
		?>
		<hr class="qt-spacer-s">
		<ul class="collapsible qt-collapsible qt-paper qt-card qt-listenon" data-collapsible="accordion">
			<li>
				<h5 class="collapsible-header qt-collapsible-header qt-center qt-capfont-thin">
				  <?php esc_attr_e("Buy tickets on", 'kentha'); ?>
				  <i class="material-icons">keyboard_arrow_down</i>
				</h5>
				<div class="collapsible-body qt-collapsible-body">
				  <?php  
				  foreach($data as $d){
				  ?>
				  <h6 class="qt-capfont-thin qt-listenlink">
					

					<?php 
					if($d['cbuylink_url'] !== ''){ 
						/**
						 *
						 * WooCommerce update:
						 *
						 */
						$buylink = $d['cbuylink_url'];
						if(is_numeric($buylink)) {
							$prodid = $buylink;
							$buylink = add_query_arg("add-to-cart" ,   $buylink, get_the_permalink());
							?>
							<a href="<?php echo esc_html($buylink); ?>"  data-quantity="1" data-product_id="<?php echo esc_attr($prodid); ?>" class="product_type_simple add_to_cart_button ajax_add_to_cart">
								<?php echo esc_html($d['cbuylink_anchor']); ?>
							</a>
							<?php  
						} else {
							?>
							<a href="<?php echo esc_html($d['cbuylink_url']); ?>" target="_blank">
								<?php echo esc_html($d['cbuylink_anchor']); ?>
							</a>
							<?php
						}
					}
					?>
				  </h6>
				  <?php } ?>
				</div>
			</li>
		</ul>
		<?php 
	}
}}