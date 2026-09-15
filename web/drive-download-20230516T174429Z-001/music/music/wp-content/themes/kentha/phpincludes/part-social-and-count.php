<?php
$social = kentha_qt_socicons_array();
ksort($social);
foreach($social as $var => $val){
	$link = get_theme_mod( 'kentha_social_'.$var );
	if($link){
		?>
			<li class="qt-soc-count qt-social-linkicon">
				<a href="<?php echo ($var == 'skype')? 'skype:'.wp_kses( $link, array() ).'?call' : esc_url($link); ?>" class="qw-disableembedding qw_social" target="_blank"><i class="qt-socicon-<?php echo esc_attr($var); ?> qt-socialicon"></i>
				<?php
				/**
				 * Social counter: active if the Social Counter Plus plugin is installed and configured
				 */
				if(function_exists('get_scp_counter')){
					$n = intval( get_scp_counter($var) );
					if($n){
						echo '<span>'.kentha_number_format($n, 1).'</span>';
					}
				}
				?>
				</a>
			</li>
		<?php
	}
}





