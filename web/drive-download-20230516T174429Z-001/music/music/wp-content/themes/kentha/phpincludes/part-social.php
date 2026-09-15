<?php
$social = kentha_qt_socicons_array();
krsort($social);
foreach($social as $var => $val){
	$link = get_theme_mod( 'kentha_social_'.$var );
	if($link){
		?>
			<li class="qt-social-linkicon">
				<a href="<?php echo ($var == 'skype')? 'skype:'.wp_kses( $link, array() ).'?call' : esc_url($link); ?>" class="qw-disableembedding qw_social" target="_blank"><i class="qt-socicon-<?php echo esc_attr($var); ?> qt-socialicon"></i>
				</a>
			</li>
		<?php
	}
}
