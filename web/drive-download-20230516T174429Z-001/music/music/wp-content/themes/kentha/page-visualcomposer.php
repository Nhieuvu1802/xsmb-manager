<?php
/*
Package: Kentha
Template Name: Page Visual Composer
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content qt-page-visualcomposer">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-main-contents"); ?>>
			<?php the_content(); ?>
			<?php  
			/**
			 * Vertical Menu
			 */
			$vm = get_post_meta( get_the_id(), 'kentha_vertical_menu', true );
			if($vm){
				if(is_array($vm)){
					?>
					<div class="qt-vc_verticalmenu qt-capfont">
						<ul><?php 
						foreach($vm as $item){
							if($item['text'] !== ''){
								?><li><?php 
									?><a href="#<?php echo esc_attr($item['sectionid']); ?>" class="qt-smoothscroll"><span><?php echo esc_html($item['text']); ?></span></a><?php 
								?></li><?php 
							}
						}
						?>
						</ul>
					</div>
					<?php 
				}
			}
			?>
		</div>
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();