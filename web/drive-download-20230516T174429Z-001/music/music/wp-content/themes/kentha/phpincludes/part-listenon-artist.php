<?php  
$data = get_post_meta(get_the_id(), 'repeatablebuylinks', false);
if(array_key_exists(0, $data)){
	$data = $data[0];
	if(count($data)>0){
		if($data[0]['cbuylink_anchor'] != ''){
		?>
		<ul class="collapsible qt-collapsible qt-paper qt-card qt-spacer-s qt-listenon" data-collapsible="accordion">
		    <li>
				<h5 class="collapsible-header qt-collapsible-header qt-center qt-capfont-thin">
					<?php 
					$qt_custom_links_title = get_post_meta(get_the_id(), 'qt_custom_links_title', true);
					if($qt_custom_links_title !== ''){
						echo esc_html($qt_custom_links_title);
					} else {
						esc_attr_e("Listen to this artist on:", 'kentha'); 
					}
					?>
					<i class="material-icons">keyboard_arrow_down</i>
				</h5>
				<div class="collapsible-body qt-collapsible-body">
					<?php  
					foreach($data as $d){
					?>
					<h6 class="qt-capfont-thin qt-listenlink">
						<a href="<?php echo esc_html($d['cbuylink_url']); ?>" target="_blank">
							<?php echo esc_html($d['cbuylink_anchor']); ?>
						</a>
					</h6>
					<?php } ?>
				</div>
		    </li>
		</ul>
		<?php 
		}
	}
}