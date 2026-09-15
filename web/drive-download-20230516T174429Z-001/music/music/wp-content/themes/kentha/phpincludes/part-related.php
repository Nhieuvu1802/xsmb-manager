<?php
$related_posttype = get_post_type( get_the_id());
$related_taxonomy = esc_attr( kentha_get_type_taxonomy( $related_posttype ) );
$related_posts_per_page = 3;

/**
 *
 *  Basic query preparation
 *  
 */
$argsList = array(
	'post_type' => $related_posttype,
	'posts_per_page' => $related_posts_per_page,
	'orderby' => array(  'menu_order' => 'ASC' ,    'post_date' => 'DESC'),
	'post_status' => 'publish',
	'post__not_in'=>array(get_the_id())
);


/**
 *
 *  Check if we have a taxonomy result and add to query
 *  
 */
$add_more = false;
if($related_posttype == 'event'){
	if(get_theme_mod( 'kentha_events_hideold')=='1'){
		$add_more = true;
	}
}
$terms = get_the_terms( get_the_id()  , $related_taxonomy, 'string');
$term_ids = false;
if( true == $add_more && !is_wp_error( $terms ) ) {
	if(is_array($terms)) {
		$term_ids = wp_list_pluck($terms,'term_id');
		if ($term_ids) {
			$argsList['tax_query'] =  array(
				array(
					'taxonomy' => $related_taxonomy,
					'field' => 'id',
					'terms' => $term_ids,
					'operator'=> 'IN'
				)
			);
		}
	}
}



/**
 *  For events we reorder by date and eventually hide past events
 */
if($related_posttype == 'event'){
	$argsList['orderby'] = 'meta_value';
	$argsList['order'] = 'ASC';
	$argsList['meta_key'] = 'eventdate';

	if(get_theme_mod( 'kentha_events_hideold')=='1'){
		$argsList['meta_query'] = array(
		array(
			'key' => 'eventdate',
			'value' => date('Y-m-d'),
			'compare' => '>=',
			'type' => 'date'
			 )
		);
	}
}

/**
 * 
 * Execute query
 * 
 */
$the_query = new WP_Query($argsList);
?>

<!-- ======================= RELATED SECTION ======================= -->
<?php if ( $the_query->have_posts() ) :
	$count = $the_query->post_count;

	switch ($count){
		case '1':
			$colclass = ' col s12';
		break;
		case '2':
			$colclass = ' col s12 m6';
		break;
		case '3':
		default:
			$colclass = ' col s12 m4';
		break;
	}



	?>
	<hr class="qt-spacer-m">
	<div class="qt-related qt-container qt-clearfix">
		<div class="row">
			<div class="qt-cols  qt-clearfix ">
				<?php 
					while ( $the_query->have_posts() ) : $the_query->the_post(); 
					setup_postdata( $post ); 
					?>
					<div class="qt-related-item <?php echo esc_attr($colclass); ?>">
						<a href="<?php the_permalink(); ?>" class="qt-center qt-card qt-negative" data-bgimage="<?php echo get_the_post_thumbnail_url(null, 'medium'); ?>">
							<span class="qt-content-secondary qt-item-metas"><?php esc_html_e("Related", "kentha"); ?></span>
							<h5><?php echo esc_html(kentha_shorten(get_the_title(), '70' )); ?></h5>
							<span class="qt-item-metas">
								<?php  
								switch($related_posttype){
									case 'artist':
										/*
										*
										*   Artist nationality
										*/
										$nat = get_post_meta($post->ID, '_artist_nationality',true);
										$res = get_post_meta($post->ID, '_artist_resident',true); 
										if($res){
											echo esc_html( $res );
										}
										if($nat && $res){ ?>&nbsp;<?php }
										if($nat){
											echo esc_html( '['.$nat.']' );
										}
										break;
									case 'release':
										$tracks = get_post_meta(get_the_id(), 'track_repeatable');
										if(is_array($tracks)){ 
											$tracks = $tracks[0]; 
											echo count($tracks);  ?>&nbsp;<?php esc_html_e( 'Tracks', 'kentha' ); 
										} ?> | <?php 
											echo date( "Y", strtotime(get_post_meta(get_the_id(), 'general_release_details_release_date',true))); 
										break;
									case 'shows':
										$tags = get_the_terms( get_the_id(), 'qt-kentharadio-showgenre');
										if(is_array($tags)){
											echo $tags[0]->name;
										}										
										break;
									case 'members':
										$tags = get_the_terms(get_the_id(), 'membertype');
										if(is_array($tags)){
											echo $tags[0]->name;
										}										
										break;
									case 'chart':
										$tags = get_the_terms( get_the_id(), 'chartcategory');
										if(is_array($tags)){
											echo $tags[0]->name;
										}										
										break;
									case 'podcast':
										$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
										$date = get_post_meta( get_the_id(), '_podcast_date', true );
										echo esc_html($artist); 
										if($artist && $date){ ?> | <?php }
										// echo esc_html($date);
										echo date_i18n( "M d", strtotime($date));
										break;
									case 'event':
										$date = date( 'd M', strtotime(get_post_meta($post->ID, 'eventdate',true)));
										$location = get_post_meta($post->ID, 'qt_location',true); 
										if($location){
											echo esc_html( $location );
										}
										if($date && $location){ ?> / <?php }
										if($date){
											echo date_i18n( "M d", strtotime($date));
										}
										break;
									case 'post':
									default:
										the_author(); ?> | <?php kentha_international_date();
								}
								?>
							</span>
							
						</a>
					</div>
				<?php
				endwhile;
				?>
			</div>
		</div>
	</div>
<?php  endif;
wp_reset_postdata();