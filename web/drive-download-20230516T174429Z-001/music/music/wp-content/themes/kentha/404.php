<?php
/*
Package: Kentha
*/
get_header();
?>
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content qt-page-visualcomposer">
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div class="qt-404-container qt-main-contents <?php kentha_is_negative(); ?>">
			<div class="qt-vc">
				<div class="qt-vi">
					<div class="qt-container-l">
						<h1 class="qt-caption qt-spacer-s qt-center">
							<span class="qt-errorcode"><?php esc_html_e( '404', 'kentha' ); ?></span>
							<?php esc_html_e("PAGE NOT FOUND", "kentha"); ?>
						</h1>
						<hr class="qt-spacer-m">
						<div class="qt-container">
							<h4 class="qt-subtitle">
								<?php esc_html_e("Search for something else:", "kentha"); ?>
							</h4>
							<?php get_template_part('searchform' ); ?>
							<p class="qt-center qt-spacer-s"><a class="qt-btn qt-btn-primary qt-btn-l" href="<?php echo esc_url( home_url( '/' ) ); ?>"><?php esc_html_e("Home", "kentha"); ?></a></p>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>
<?php get_footer();