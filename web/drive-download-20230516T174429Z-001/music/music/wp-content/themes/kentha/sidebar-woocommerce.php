<?php
/*
Package: Kentha
*/

if(is_active_sidebar( 'kentha-woocommerce-sidebar' ) ){
?>
<!-- SIDEBAR ================================================== -->
<div class="qt-paper qt-paddedcontent  qt-card">
	<div id="qtSidebar" class="qt-widgets qt-sidebar-main qt-content-aside row"  data-collapsible="accordion">
		<?php dynamic_sidebar( 'kentha-woocommerce-sidebar' ); ?>
	</div>
</div>
<!-- SIDEBAR END ================================================== -->
<?php } ?>