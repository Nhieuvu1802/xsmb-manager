<?php
/**
 * 
 *
 * Events data
 * 
 */
$e = array(
  'id' =>  $post->ID,
  'lineup' => get_post_meta($post->ID,'event_lineup',true),
  'date' =>  get_post_meta($post->ID,'eventdate',true),
  'time' =>  get_post_meta($post->ID,'eventtime',true),
  'location' =>  get_post_meta($post->ID, 'qt_location',true),
  'street' =>  get_post_meta($post->ID, 'qt_address',true),
  'city' =>  get_post_meta($post->ID, 'qt_city',true),
  'country' =>  get_post_meta($post->ID, 'qt_country',true),
  'permalink' =>  get_permalink($post->ID),
  'title' =>  $post->post_title,
  'phone' => get_post_meta($id, 'qt_phone',true),
  'website' => get_post_meta($id, 'qt_link',true),
  'facebooklink' => get_post_meta($id, 'eventfacebooklink',true),
  'coord' => get_post_meta($id,  'qt_coord',true),
  'email' => get_post_meta($id,  'qt_email',true)
);

?>
<div class="qt-event-featured qt-center">

	<span class="qt-tags">
		<?php echo get_the_term_list( get_the_id(), 'eventtype'); ?>
	</span>
	<h2 class="qt-caption qt-caption-event"><?php get_template_part( 'phpincludes/part-archivetitle' ); ?></h2>
	<span class="qt-item-metas qt-center">
		<?php  
		if($e['location']){ echo esc_html( $e['location'] ).'&nbsp;/&nbsp;'; }
		if($e['city']){ echo esc_html( $e['city'] ); }
		if($e['country']){ ?>&nbsp;[<?php echo esc_html( $e['country'] );?>]<?php  }
		if($e['date']){ echo ' / '.date( get_option( "date_format", "d M Y" ) , strtotime($e['date'])).' '.esc_html($e['time']); }
		?>
	</span>
	<h3 class="qt-countdown" data-date="<?php echo esc_attr(get_post_meta($post->ID, 'eventdate',true)); ?>" data-time="<?php echo esc_attr(get_post_meta($post->ID, 'eventtime',true)); ?>" data-days="<?php esc_attr_e('D','kentha'); ?>" data-hours="<?php echo esc_attr('H','kentha'); ?>" data-minutes="<?php esc_attr_e('M','kentha'); ?>" data-seconds="<?php esc_attr_e('S','kentha'); ?>"><?php esc_html_e("Coming Soon", "kentha"); ?></h3>
	<div class="qt-event-actions">
		<a href="<?php the_permalink(); ?>" class="qt-btn qt-btn-l qt-btn-primary"><?php esc_html_e("Event details", "kentha"); ?></a>
		<?php get_template_part( 'phpincludes/part-buylink' ); ?>
	</div>
	<hr class="qt-capseparator">

</div>