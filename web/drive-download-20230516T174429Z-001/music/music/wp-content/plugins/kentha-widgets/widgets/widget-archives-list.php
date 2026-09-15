<?php  
/**
Package: Kentha Widgets
Description: archives list
Version: 0.0.0
Author: QantumThemes
Author URI: http://www.qantumthemes.xyz
 */
?>
<?php


add_action( 'init', 'kentha_widgets_list_add_new_image_size' );
function kentha_widgets_list_add_new_image_size() {
    add_image_size( 'kentha-widget-thumb', 60, 60, true ); //mobile
    add_image_size( 'kentha-widget-med', 420, 420, true ); //mobile
}

add_action( 'widgets_init', 'kentha_widgets_archives_widget' );
function kentha_widgets_archives_widget() {
	register_widget( 'kentha_widgets_archives_widget' );
}
class kentha_widgets_archives_widget extends WP_Widget {
	function __construct() {
		$widget_ops = array( 'classname' => 'archiveswidget', 'description' => esc_attr__('A widget that displays archives ', "kentha-widgets") );
		$control_ops = array( 'width' => 300, 'height' => 350, 'id_base' => 'kentha_widgets_archives_widget' );
		parent::__construct( 'kentha_widgets_archives_widget', esc_attr__('QT Archives List Widget', "kentha-widgets"), $widget_ops, $control_ops );
	}

	function widget( $args, $instance ) {
		extract( $args );
		extract( $instance );



		echo $before_widget;
		if(array_key_exists('title', $instance)) {
			if( $instance['title'] !== '' ){
				echo $before_title.apply_filters("widget_title", $instance['title']).$after_title; 
			}
		}
		if(!array_key_exists('posttype', $instance)) {
			$instance['posttype'] = 'post';
		}

		//Send our widget options to the query
		if(!post_type_exists( $instance['posttype'] )) {
			echo esc_attr__("ALERT: This is a custom post type. Please install qt Core plugin to correctly visualize the contents.", "kentha-widgets");
			echo $after_widget;
			return;
		}
		$queryArray =  array(
			'post_type' => $instance['posttype'],
			'posts_per_page' => array_key_exists('number',$instance)? $instance['number'] : 5 ,
			'ignore_sticky_posts' => 1,
			'order' => 'ASC'
		);

		if(array_key_exists('specificid', $instance)) {
			if($instance['specificid'] != ''){
				$posts = explode(',',$instance['specificid']);
				$finalarr = array();
				foreach($posts as $p){
					if(is_numeric($p)){
						$finalarr[] = $p;
					}
				};
				$queryArray['post__in'] = $finalarr;
			}
		}

		$queryArray['orderby'] = 'date';
		if(array_key_exists('order', $instance)) {
			$queryArray['orderby'] = $instance['order'];
		}


		if(array_key_exists('orderby', $instance)) {
			switch($instance['orderby']){
				case 'menu_order':
					$queryArray['orderby'] = 'menu_order title';
					$queryArray['order']   = 'ASC';
					break;
				case 'rand':
					$queryArray['orderby'] = 'rand';
					break;
				case "date":
				default:
					$queryArray['orderby'] = 'date';
					$queryArray['order']   = 'DESC';
					break;
			}
		} 

		// ========== POSTS ONLY QUERY =========================
		if(array_key_exists('posttype', $instance)) {
			if ($instance['posttype'] === 'post') {
				$queryArray['orderby'] = 'date';
				$queryArray['order']   = 'DESC';
			}
		} else {
			$instance['posttype'] == 'post';
		}
		// ========== END OF POSTS ONLY QUERY ==================
		 
		// =========== REAKTIONS QUERY =========================
		if(array_key_exists('order', $instance)) {
			if ($instance['order'] === 'views') {
				$queryArray['orderby'] = 'meta_value';
				$queryArray['order']   = 'DESC';
				$queryArray['meta_key'] = 'qt_reaktions_views';
			}
			if ($instance['order'] === 'love') {
				$queryArray['orderby'] = 'meta_value';
				$queryArray['order']   = 'DESC';
				$queryArray['meta_key'] = 'qt_reaktions_votes_count';
			}
			if ($instance['order'] === 'rating') {
				$queryArray['orderby'] = 'meta_value';
				$queryArray['order']   = 'DESC';
				$queryArray['meta_key'] = 'qt_rating_average';
			}
		}
		// =========== REAKTIONS QUERY END =====================

		$reaktions = array("views", "loveit", "rating");
		foreach($reaktions as $r){
			${$r} = false;
			if(array_key_exists($r, $instance)){
				if($instance[$r] == "1"){ 
					${$r} = true;
				}
			}
		}
		
		// ========== EVENTS ONLY QUERY =================
		if( $instance['posttype'] === 'event' ){
			$queryArray['orderby'] = 'meta_value';
			$queryArray['order']   = 'ASC';
			$queryArray['meta_key'] = 'eventdate';
			if(get_theme_mod( 'kentha_events_hideold', 0 ) == '1'){
			    $queryArray['meta_query'] = array(
	            array(
	                'key' => 'eventdate',
	                'value' => date('Y-m-d'),
	                'compare' => '>=',
	                'type' => 'date'
	                 )
	           	);
			}
		}
		// ========== END OF EVENTS ONLY QUERY =================
		
		$query = new WP_Query($queryArray);
		?>
		<div class="qt-archives-widget">
			<?php
			/**
			 *
			 * List template loop
			 * Run the control before the loop to save cpu
			 * 
			 */
			
			if(!array_key_exists('template', $instance)) {
				$instance['template'] = 'list';
			}

			if(!array_key_exists('showthumbnail', $instance)) {
				$instance['showthumbnail'] = true;
			}
			if($instance['template'] === 'list' || $instance['template'] === ''){
				if ($query->have_posts()) : while ($query->have_posts()) : $query->the_post();
					$post = $query->post;
					?>
						<!-- ITEM INLINE  ========================= -->
						
						<div class="qt-part-archive-item qt-item-inline qt-clearfix">
							<?php if(has_post_thumbnail()){ ?>
							<a class="qt-inlineimg" href="<?php the_permalink(); ?>">
								<img width="60" height="60" src="<?php echo get_the_post_thumbnail_url(null,'kentha-widget-thumb'); ?>" class="attachment-thumbnail size-thumbnail wp-post-image" alt="Thumbnail">
							</a>
							<?php } ?>

							<h6 class="qt-tit">
								<a class="" href="<?php the_permalink(); ?>">
									<?php 
									$title = get_the_title();
									echo esc_attr(kentha_shorten($title, 70) ); 
									if(strlen($title) > 70) { ?>...<?php }
									?>
								</a>
							</h6>

							<span class="qt-item-metas">
								<?php  
								switch($instance['posttype']){
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
									case 'podcast':
										$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
										$date = get_post_meta( get_the_id(), '_podcast_date', true );
										echo esc_html($artist); 
										if($artist && $date){ ?> | <?php }
										echo esc_html($date);
										break;
									case 'event':
										$date = date( 'd M Y', strtotime(get_post_meta($post->ID, 'eventdate',true)));
										$location = get_post_meta($post->ID, 'qt_location',true); 
										if($location){
											echo esc_html( $location );
										}
										if($date && $location){ ?> / <?php }
										if($date){
											echo esc_html($date);
										}
										break;
									case 'post':
									default:
										the_author(); ?> | <?php kentha_international_date();
								}
								?>
							</span>


							
						</div>

						<!-- ITEM INLINE END ========================= -->
					<?php 
				endwhile; endif;  

			} elseif ($instance['template'] === 'card' ) {
				if ($query->have_posts()) : while ($query->have_posts()) : $query->the_post();
					$post = $query->post;
					?>

						<!-- ITEM CARD  ========================= -->
						<div <?php post_class("qt-glass-card qt-negative"); ?> data-bgimage="<?php echo get_the_post_thumbnail_url(null, 'kentha-widget-med'); ?>">
							<a href="<?php the_permalink(); ?>" class="qt-content">
								<h5>
									<?php the_title(); ?>
								</h5>
								<span class="qt-item-metas">
									<?php 
									switch($instance['posttype']){
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
										case 'podcast':
											$artist = get_post_meta( get_the_id(), '_podcast_artist', true );
											$date = get_post_meta( get_the_id(), '_podcast_date', true );
											echo esc_html($artist); 
											if($artist && $date){ ?> | <?php }
											echo esc_html($date);
											break;
										case 'event':
											$date = date( 'd M Y', strtotime(get_post_meta($post->ID, 'eventdate',true)));
											$location = get_post_meta($post->ID, 'qt_location',true); 
											if($location){
												echo esc_html( $location );
											}
											if($date && $location){ ?> / <?php }
											if($date){
												echo esc_html($date);
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
						<!-- ITEM CARD ========================= -->
					
					<?php 

				endwhile; endif;  
			}
			?>
		</div>
		<?php 
			if(array_key_exists('archivelink_url', $instance)) {
				if($instance['archivelink_url'] != ''){
					if($instance['archivelink_text']==''){$instance['archivelink_text'] = esc_attr__('See all',"kentha-widgets");};
					echo '<a href="'.esc_url($instance['archivelink_url']).'" class="qt-btn qt-btn-s qt-btn-secondary"><i class="material-icons">chevron_right</i>'.esc_attr($instance['archivelink_text']).'</a>';
				}
			} 
		?>
		<?php
		wp_reset_postdata();
		echo $after_widget;
	}

	//Update the widget 
	function update( $new_instance, $old_instance ) {
		$instance = $old_instance;
		//Strip tags from title and name to remove HTML 

		$attarray = array(
				'title',
				'showthumbnail',
				'template',
				'number',
				'specificid',
				'orderby',
				'archivelink_text',
				'posttype',
				'archivelink_url',
				'views',
				'loveit',
				'rating',
		);

		if(!is_numeric($new_instance['number'])){
			$new_instance['number'] = 5;
		}

		$new_instance['archivelink_url'] = esc_url($new_instance['archivelink_url']);

		foreach ($attarray as $a){
			$instance[$a] = esc_attr(strip_tags( $new_instance[$a] ));
		}
		return $instance;
	}

	function form ( $instance ) {
		//Set up some default widget settings.
		$defaults = array( 'title' => "",
							'showthumbnail'=> '1',
							'number'=> '5',
							'specificid'=> '',
							'orderby'=> 'menu_order',
							'posttype'=> 'post',
							'template'=> 'list',
							'views' => 0,
							'loveit' => 0,
							'rating' => 0,
							'archivelink_text'=> esc_attr__('See all',"kentha-widgets"),
							'archivelink_url' => ''
							);
		$instance = wp_parse_args( (array) $instance, $defaults ); ?>
		<h2>General options</h2>
		<p>
			<label for="<?php echo $this->get_field_id( 'title' ); ?>"><?php echo esc_attr__('Title:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'title' ); ?>" name="<?php echo $this->get_field_name( 'title' ); ?>" value="<?php echo $instance['title']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'posttype' ); ?>"><?php echo esc_attr__('Post type', "kentha-widgets"); ?></label><br>
			<?php  
			$args = array(
			   'public'   => true,
			   '_builtin' => false
			);
			$custom_types = get_post_types( $args ); 
			$post_types[] = 'post';
			$post_types = array_merge($post_types, $custom_types);
			?>
			<select id="<?php echo $this->get_field_id( 'posttype' ); ?>" name="<?php echo $this->get_field_name( 'posttype' ); ?>">
			<?php foreach ( $post_types as $post_type ) { ?>
					<option value="<?php echo esc_attr($post_type); ?>" <?php if($instance['posttype'] === $post_type): ?> selected="selected" <?php endif; ?>><?php echo esc_attr($post_type); ?></option>
			<?php } ?>
			</select>
		</p>

		<!-- ====== TEMPLATE =========== -->
		<p>
			<label for="<?php echo $this->get_field_id( 'template' ); ?>"><?php echo esc_attr__('Template', "kentha-widgets"); ?></label><br />			
			<select id="<?php echo $this->get_field_id( 'template' ); ?>" name="<?php echo $this->get_field_name( 'template' ); ?>">
				<?php 
				$templates = array('list','card');
				foreach ( $templates as $template ) { ?>
						<option value="<?php echo esc_attr($template); ?>" <?php if($instance['template'] === $template): ?> selected="selected" <?php endif; ?>><?php echo esc_attr($template); ?></option>
				<?php 
				} 
				?>
			</select>
		</p> 
		<!-- ====== TEMPLATE END =========== -->

		<p>
			<label for="<?php echo $this->get_field_id( 'specificid' ); ?>"><?php echo esc_attr__('Add only specific ids (comma separated like: 23,46,94)', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'specificid' ); ?>" name="<?php echo $this->get_field_name( 'specificid' ); ?>" value="<?php echo $instance['specificid']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'number' ); ?>"><?php echo esc_attr__('Quantity:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'number' ); ?>" name="<?php echo $this->get_field_name( 'number' ); ?>" value="<?php echo $instance['number']; ?>" style="width:100%;" />
		</p>

		<p>
			<label for="<?php echo $this->get_field_id( 'showthumbnail' ); ?>"><?php echo esc_attr__('Show thumbnail', "kentha-widgets"); ?></label><br />			
		   <?php echo esc_attr__("Yes","kentha-widgets"); ?>   <input type="radio" name="<?php echo $this->get_field_name( 'showthumbnail' ); ?>" value="1" <?php if($instance['showthumbnail'] == '1'){ echo ' checked= "checked" '; } ?> />
		   <?php echo esc_attr__("No","kentha-widgets"); ?>  <input type="radio" name="<?php echo $this->get_field_name( 'showthumbnail' ); ?>" value="0" <?php if($instance['showthumbnail'] != '1'){ echo ' checked= "checked" '; } ?> />  
		</p>  
		<p>
			<label for="<?php echo $this->get_field_id( 'orderby' ); ?>"><?php echo esc_attr__('Order', "kentha-widgets"); ?></label><br />			
			<input type="radio" name="<?php echo $this->get_field_name( 'orderby' ); ?>" value="menu_order" <?php if($instance['orderby'] == 'menu_order'){ echo ' checked= "checked" '; } ?> /><?php echo esc_attr__("Page order","kentha-widgets"); ?><br>
			<input type="radio" name="<?php echo $this->get_field_name( 'orderby' ); ?>" value="date" <?php if($instance['orderby'] == 'date'){ echo ' checked= "checked" '; } ?> /><?php echo esc_attr__("Date","kentha-widgets"); ?><br>
			<input type="radio" name="<?php echo $this->get_field_name( 'orderby' ); ?>" value="rand" <?php if($instance['orderby'] == 'Random'){ echo ' checked= "checked" '; } ?> /><?php echo esc_attr__("Random","kentha-widgets"); ?>  
		</p>  
		<p>
			<label for="<?php echo $this->get_field_id( 'archivelink_text' ); ?>"><?php echo esc_attr__('Link to archive text:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'archivelink_text' ); ?>" name="<?php echo $this->get_field_name( 'archivelink_text' ); ?>" value="<?php echo $instance['archivelink_text']; ?>" style="width:100%;" />
		</p>
		<p>
			<label for="<?php echo $this->get_field_id( 'archivelink_url' ); ?>"><?php echo esc_attr__('Link to archive URL:', "kentha-widgets"); ?></label>
			<input id="<?php echo $this->get_field_id( 'archivelink_url' ); ?>" name="<?php echo $this->get_field_name( 'archivelink_url' ); ?>" value="<?php echo $instance['archivelink_url']; ?>" style="width:100%;" />
		</p>
	<?php
	}
}
?>