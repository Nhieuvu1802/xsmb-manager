<?php
/*
Package: Kentha
*/

$id = get_the_id();
$date =  esc_attr(get_post_meta($id,'eventdate',true));
if($date){
	$date = date_i18n( get_option( "date_format", "d M Y" ) , strtotime(get_post_meta($post->ID, 'eventdate',true)));
}
$street 		= get_post_meta($id, 'qt_address',true);
$city 			= get_post_meta($id, 'qt_city',true);
$country 		= get_post_meta($id, 'qt_country',true);
$phone 			= get_post_meta($id, 'qt_phone',true);
$website 		= get_post_meta($id, 'qt_link',true);
$facebooklink 	= get_post_meta($id, 'eventfacebooklink',true);
$location 		= get_post_meta($id, 'qt_location',true);
$coord 			= get_post_meta($id, 'qt_coord',true);
$email 			= get_post_meta($id, 'qt_email',true);
?>

<table class="table qt-eventtable ">
	<tbody>
		<?php 
		if($date){ ?>
		<tr>
			<th><?php esc_html_e('Date', 'kentha'); ?>:</th>
			<td><?php echo esc_html($date); ?> <?php echo esc_html(get_post_meta($post->ID, 'eventtime',true)); ?></td>
		</tr>
		<?php
		}
		if($location){ 
		?>
		<tr>
			<th><?php esc_html_e('Location', 'kentha'); ?>:</th>
			<td><?php echo esc_html($location); ?></td>
		</tr>
		<?php
		}
		if($street || $city || $country){ 
		?>
		<tr>
			<th><?php esc_html_e('Address', 'kentha'); ?>:</th>
			<td><?php echo esc_html($street.' '.$city.' '.$country); ?></td>
		</tr>
		<?php
		}
		if($phone){ 
		?>
		<tr>
			<th><?php esc_html_e('Phone', 'kentha'); ?>:</th>
			<td><a href="tel:<?php echo esc_url($facebooklink); ?>" target="_blank" rel="nofollow"><?php echo esc_html($phone); ?></a></td>
		</tr>
		<?php
		}
		if($website){ 
		?>
		<tr>
			<th><?php esc_html_e('Website', 'kentha'); ?>:</th>
			<td><a href="<?php echo esc_url($website); ?>" target="_blank" rel="nofollow"><?php echo esc_html($website); ?></a></td>
		</tr>
		<?php
		}
		if($facebooklink){ 
		?>
		<tr>
			<th><?php esc_html_e('Facebook event', 'kentha'); ?>:</th>
			<td><a href="<?php echo esc_url($facebooklink); ?>" target="_blank" rel="nofollow"><?php echo esc_html($facebooklink); ?></a></td>
		</tr>
		<?php } ?>
	</tbody>
</table>