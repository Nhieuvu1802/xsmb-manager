<?php
/*
Package: Kentha
@requires qt-kentharadio
*/

get_header();
?>
<!-- ======================= MAIN SECTION  ======================= -->
<div id="maincontent">
	<div class="qt-main qt-clearfix qt-single-artist qt-3dfx-content">
		<?php while ( have_posts() ) : the_post(); ?>
		<?php get_template_part( 'phpincludes/part-background' ); ?>
		<article id="qtarticle" <?php post_class("qt-main-contents qt-single-members"); ?>>

			<div class="qt-container">
				<header id="qt-pageheader" class="qt-pageheader qt-intro__fx <?php kentha_is_negative(); ?>" data-start>
					<div class="qt-pageheader__in">
						<span class="qt-tags">
							<?php  echo get_the_term_list( get_the_id(), 'membertype'); ?>
						</span>
						<h1 class="qt-caption"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h1>
						<?php  
						$nat = get_post_meta($post->ID, 'member_role',true);
						if($nat){ ?>
							<span class="qt-item-metas"><?php echo esc_html($nat);	?></span>
						<?php } ?>
						<hr class="qt-capseparator">
					</div>
				</header>
			</div>

			<div class="<?php kentha_is_negative(); ?>">
			<?php  
			/**
			 * [$category slug of taxonomy]
			 * @var [string]
			 */
			$members_show_pick = get_post_meta( get_the_ID(), 'members_show_pick', $single = true );
			if(is_array($members_show_pick)){
				if(count($members_show_pick) > 0){
					$shows_array = '';
					if(array_key_exists('membershow', $members_show_pick[0])){

						if($members_show_pick[0]['membershow'][0]){

							foreach($members_show_pick as $arr => $s){
								$shows_array .= $s['membershow'][0].',';
							}
							?>
							<!-- ======================= MANUALLY ASSOCIATED MEMBERS ======================= -->
								<?php 
								if(shortcode_exists('kentha-carousel-post' )){
									echo do_shortcode('[kentha-carousel-post posttype="shows" design="center" title="'.get_the_title().' ' .esc_attr__("shows","kentha").'" id="'.rtrim($shows_array,',').'"]' );
								}
								?>
							<!-- ======================= RELATED MEMBERS END ======================= -->
							<?php
						}
					}
				}
			}
			?>
			</div>

			<div class="qt-container">
				<div class="row">
					<div class="col s12 m8 l8">
						<?php if(has_post_thumbnail(  )){ ?>
						<a class="qt-imglink qt-card qt-featuredimage" href="<?php the_post_thumbnail_url( 'large' ); ?>">
							<?php the_post_thumbnail("large" ); ?>
						</a>
						<?php } ?>
						<div class="qt-paddedcontent qt-paper">
							<div class="qt-the-content">
								<?php the_content(); ?>
							</div>
						</div>
						<hr class="qt-spacer-s">
					</div>
					<div class="col s12 m4 l4">
						<?php  
						$artist_social = '';
						$links_array = array(
							array(	'label' => 'Facebook',
								'id'    => 'QT_facebook',
								'icon'	=> 'qt-socicon-facebook',
								)
							,array(
								'label' => 'Twitter',
								'id'    => 'QT_twitter',
								'icon'	=> 'qt-socicon-twitter',
								)
							,array(
								'label' => 'Pinterest ',
								'id'    => 'QT_pinterest',
								'icon'	=> 'qt-socicon-pinterest',
								)
							,array(
								'label' => 'Vimeo',
								'id'    => 'QT_vimeo',
								'icon'	=> 'qt-socicon-vimeo',
								)
							,array(
								'label' => 'Wordpress',
								'id'    => 'QT_wordpress',
								'icon'	=> 'qt-socicon-wordpress',
								)
							,array(
								'label' => 'Youtube',
								'id'    => 'QT_youtube',
								'icon'	=> 'qt-socicon-youtube',
								'type'  => 'text'
								)
							,array(
								'label' => 'Soundcloud',
								'id'    => 'QT_soundcloud',
								'icon'	=> 'qt-socicon-soundcloud',						
							)
							,array(
								'label' => 'Beatport',
								'id'    => 'QT_beatport',
								'icon'	=> 'qt-socicon-beatport',						
							)
							,array(
								'label' => 'Myspace',
								'id'    => 'QT_myspace',
								'icon'	=> 'qt-socicon-myspace',						
							)
							,array(
								'label' => 'Itunes',
								'id'    => 'QT_itunes',
								'icon'	=> 'qt-socicon-itunes',						
							)
							,array(
								'label' => 'Mixcloud',
								'id'    => 'QT_mixcloud',
								'icon'	=> 'qt-socicon-mixcloud',						
							)
							,array(
								'label' => 'Resident Advisor',
								'id'    => 'QT_resident-advisor',
								'icon'	=> 'qt-socicon-residentadvisor',						
							)
							,array(
								'label' => 'ReverbNation',
								'id'    => 'QT_reverbnation',
								'icon'	=> 'qt-socicon-reverbnation',						
							)
							,array(
								'label' => 'Instagram',
								'id'    => 'QT_instagram',
								'icon'	=> 'qt-socicon-instagram',
							)
							,array(
								'label' => 'Snapchat',
								'id'    => 'QT_snapchat',
								'icon'	=> 'qt-socicon-snapchat',
							)
							,array(
								'label' => 'Lastfm',
								'id'    => 'QT_lastfm',
								'icon'	=> 'qt-socicon-lastfm',
							)
							,array(
								'label' => 'Google+',
								'id'    => 'QT_googleplus',
								'icon'	=> 'qt-socicon-googleplus',
							)
							,array(
								'label' => 'Amazon',
								'id'    => 'QT_amazon',
								'icon'	=> 'qt-socicon-amazon',
							)
							,array(
								'label' => 'Reddit',
								'id'    => 'QT_reddit',
								'icon'	=> 'qt-socicon-reddit',
							)
							,array(
								'label' => 'Vk',
								'id'    => 'QT_vk',
								'icon'	=> 'qt-socicon-vk',
							)
						);
						foreach ($links_array as $l => $r){
							$valore = get_post_meta(get_the_id(),  $r['id'], true );
							if($valore!=''){
								$artist_social .= '<li><a target="_blank" rel="external nofollow" href="'.esc_url($valore).'" class="qw-disableembedding qt-artist-socialicon qt-btn qt-btn-secondary" ><i class="'.esc_attr($r['icon']).'"></i></a>';
							}
						}
						if ($artist_social){
							?>
							<div class="qt-paddedcontent qt-card qt-paper qt-booking-contacts">
								<h4 class="qt-caption-small"><?php esc_html_e( 'Social profiles', 'kentha' ); ?></h4>
								<ul class="qt-social-list">
								<?php echo wp_kses_post( $artist_social); ?>
								</ul>
							</div>
							<hr class="qt-spacer-s">
							<?php 
						} 
						
						
						get_template_part( 'phpincludes/part-share' ); 
						?>
						<?php get_sidebar(); ?>
						<hr class="qt-spacer-s">
					</div>
				</div>
			</div>
		</article>
		<?php get_template_part( 'phpincludes/part-related' ); ?>
		<hr class="qt-spacer-m">
		<?php endwhile; ?>
	</div>
</div>
<!-- ======================= MAIN SECTION END ======================= -->
<?php get_footer();