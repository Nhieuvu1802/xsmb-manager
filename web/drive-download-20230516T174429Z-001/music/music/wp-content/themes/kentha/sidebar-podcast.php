<?php
/*
Package: Kentha
*/

if(is_active_sidebar( 'kentha-podcast-sidebar' ) ){
?>
<!-- SIDEBAR ================================================== -->
<div class="qt-paper qt-paddedcontent  qt-card">
	<ul id="qtSidebar" class="qt-widgets qt-sidebar-main <?php if(get_theme_mod( 'kentha_widget_accordion' )){ ?>qt-collapsible<?php } ?> qt-content-aside row"  data-collapsible="accordion">
		<?php dynamic_sidebar( 'kentha-podcast-sidebar' ); ?>
	</ul>
</div>
<!-- SIDEBAR END ================================================== -->
<?php } ?>