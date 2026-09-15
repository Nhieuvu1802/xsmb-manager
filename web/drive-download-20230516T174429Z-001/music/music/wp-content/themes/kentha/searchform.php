<?php
/*
Package: kentha
*/
?>
<form method="get" class="form-horizontal qw-searchform" action="<?php echo esc_url( home_url( '/' ) ); ?>" role="search">
	<div class="input-field">
		<i class="material-icons prefix">search</i>
		<input value="<?php echo esc_attr(get_search_query()); ?>" name="s" placeholder="<?php echo esc_attr_x( 'Search: type and hit enter &hellip;', 'placeholder', 'kentha' ); ?>" type="text" />
	</div>
</form>
