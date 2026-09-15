<?php
/*
Package: Kentha
Description: Single show
Version: 0.0.0
Author: QantumThemes
Author URI: http://qantumthemes.com
Requires Kentha Radio Suite Plugin
*/
get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-3dfx-content qt-single-show">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<div id="qtarticle" <?php post_class("qt-main-contents"); ?>>

			<div class="qt-container">
				<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
					<div class="qt-pageheader__in">
						<?php 					
						/**
						 * Show genre tags
						 * Requires Kentha Radio Suite plugin
						 */
						if(function_exists('qt_kentharadio_showgenre')){
							qt_kentharadio_showgenre(get_the_id());
						}
						?>

						<h1 class="qt-caption qt-nomargin"><?php the_title(); ?></h1>
						
						<?php 
						/**
						 * Show social icons
						 * Requires Kentha Radio Suite plugin
						 */
						if(function_exists('qt_kentharadio_subtitle')){
							?><span class="qt-item-metas"><?php
							qt_kentharadio_subtitle(get_the_id());
							?></span><?php  
						}
					
						?>

						
						<hr class="qt-capseparator">
					</div>
				</header>
			</div>


			<?php 
			/**
			 * Show schedule table
			 * Requires Kentha Radio Suite plugin
			 */
			if(function_exists('qt_kentharadio_showtable')){
				qt_kentharadio_showtable(get_the_id());
				?>
				<hr class="qt-spacer-l">
				<?php
			}
			?>

			<div class="qt-container">

				<?php if(has_post_thumbnail()){ ?>
				<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url("full"); ?>">
					<?php the_post_thumbnail("large" ); ?>
				</a>
				<?php } ?>

				<div class="qt-the-content qt-paper qt-paddedcontent  qt-card">
					<div class="qt-the-content">
						<?php 
						/**
						 * Show social icons
						 * Requires Kentha Radio Suite plugin
						 */
						if(function_exists('qt_kentharadio_subtitle2')){
							qt_kentharadio_subtitle2(get_the_id());
						}
						?>

						<?php the_content(); ?>
					</div>
				</div>

				<?php
				/**
				 * Show social icons
				 * Requires Kentha Radio Suite plugin
				 */
				if(function_exists('qt_kentharadio_singlesocial')){
					?>
					<div class="qt-the-content qt-content-primary qt-paddedcontent qt-card qt-center">
						<?php qt_kentharadio_singlesocial(get_the_id()); ?>
					</div>
					<?php  
				}
				?>
			</div>
		</div>
		<?php get_template_part( 'phpincludes/part-related' ); ?>
		<hr class="qt-spacer-m">
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();



























