<?php  
/**
 *
 *	@package QT Places
 *  Shortcodes
 * 
 */


if(!function_exists('qtplaces_main_shortcode')){
function qtplaces_main_shortcode($atts){
	extract( shortcode_atts( array(
		'template' => "1",
		'limit' => -1,
		'mapheight' => false,
		
		'mapcolor' => 'dark',
		'listimages' => true,
		'showfilters' => true,
		'posttype' => 'place',
		'taxonomy' => 'pcategory',
		'debug' => false,
		'mousewheel' => false,
		'terms' => '',
		'mapid' => false,
		/* Custom CSS */
		'buttoncolor' => false,
		'buttonbackground' => false,
		'listbackground' => false,
		'markercolor' => false,
		'open' => '1',


		'mapheightmobile' => false,
		'autozoom' => false,
		'streetview' => false,
		'getdirections' => "Get directions"
	), $atts ));

	if(!$mapid) {
		$mapid =  substr(str_shuffle(str_repeat("abcdefghijklmnopqrstuvwxyz", 5)), 0, 5);
	}

	if(wp_is_mobile()) {
		$mousewheel = false;
	}




	$active = ( get_option( 'qtmaps_typeselect_'.$posttype) == 1  || $posttype == 'place'  || $posttype == 'event' )? true : false;
	if(post_type_exists( $posttype ) && $active) {


		/**
		 * [$args Query arguments]
		 * 
		 */
		$args = array(
			'post_type' => $posttype,
			'posts_per_page' => intval($limit),
			'post_status' => 'publish',
			'orderby' => array(  'menu_order' => 'ASC' ,	'post_date' => 'DESC'),
			'suppress_filters' => false
	    );

		/**
		 * Prepare query and tags for a certain taxonomy
		 */
		if($taxonomy != ''){
			if($terms != ''){
				$terms_array = explode(",",$terms);
				foreach($terms_array as $termid => $termvalue){
					if(!is_numeric($termvalue)){
						unset($terms_array[$termid]);
					}
				}
				if(count($terms_array) > 0){
					$args['tax_query'] = array(
						array(
							'taxonomy' => trim(esc_attr($taxonomy)),
							'field'    => 'term_id',
							'terms'    => $terms_array,
							'operator' => 'IN'
						)
					);
				}				
			}
		}

		/**
		 * Special for event post types
		 */

		if($posttype == 'event'){
		   	
		   	if(get_theme_mod( 'qt_events_hideold', 0 ) == '1'){
			    $args['meta_query'] = array(
	            array(
	                'key' => 'eventdate',
	                'value' => date('Y-m-d'),
	                'compare' => '>=',
	                'type' => 'date'
	                 )
	           	);
			}

           	$args['orderby'] = 'meta_value';
			$args['order'] = 'ASC';
			$args['meta_key'] = 'eventdate';
		}

		




		ob_start();

		if($debug) {
			echo '<h4>Map ID: '.$mapid.'</h4>';
			echo '<h5>Query arguments:</h5>';
			echo '<pre>';
			print_r($args);
			print_r($atts);
			echo '</pre>';
		}



		?>

		<!-- ============= BEGINNING QTPLACES MAP =============================== -->

		


		<!-- MAP CONTENT -->
		<div id="<?php echo esc_attr($mapid); ?>" class="qtPlaces-container qtPlaces-template-<?php echo esc_attr($template); ?> <?php echo esc_attr($mapcolor); ?> <?php if($open == '1' || $open == "true"){ ?>open<?php } ?> <?php if(wp_is_mobile()) { ?>mobile<?php } ?>" data-getdirections="<?php echo esc_attr(esc_js($getdirections)); ?>"  data-streetview="<?php echo esc_attr(esc_js($streetview)); ?>" data-mousewheel="<?php if($mousewheel){ ?>1<?php } ?>" data-mapcolor="<?php echo esc_attr(esc_js($mapcolor)); ?>" data-mapheight="<?php echo esc_js(esc_attr($mapheight)); ?>" data-dynamicmap="map<?php echo esc_attr($mapid); ?>" >
			<div class="qtPlaces-list">
				<?php
				$wp_query = new WP_Query( $args );
				$total_terms = array();
				$custom_colors = array();
				if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post(); global $post; ?>
					<?php  
                	 /**
				     * [$terms array of categories associated with the place]
				     */
				    $terms = wp_get_post_terms( $post->ID, trim(esc_attr($taxonomy)), array( 'fields' => 'all' ));
				    $termstring = ''; // used to filter the results
				    foreach($terms as $term){
				    	$term = (array) $term;
				    	$term["filterid"] = 'pfilter-'.$term["term_id"];
				    	$total_terms[$term["term_id"]] = (array) $term;
				    	$termstring .= $term["filterid"].' ';
				    }
				    ?>

				    <?php  
				    /**
				     * Generate the featured image permalink
				     */
				    $picture = '';
				    $thumb = wp_get_attachment_image_src( get_post_thumbnail_id($post->ID), 'medium' );
					$picture = $thumb['0'];
					
					?>
					<div class="qtPlaces-entry all <?php echo esc_attr($termstring); ?>"  data-qtautobg="<?php if($listimages) { echo esc_js(esc_attr($picture)); } ?>">
						<h4><?php 
							if("event" == $posttype){ 
								$thedate = get_post_meta($post->ID, "eventdate", true);
								if( $thedate ){
									echo date('d F, Y', strtotime( $thedate )).'<br>';
								}
								
							} 
							the_title(); 
							?>
						</h4>
						<?php  
						$country = get_post_meta($post->ID, 'qt_country', true);
						$city = get_post_meta($post->ID, 'qt_city', true);
						if($city || $country) {
						?>
						<p class="listdetail"><i class="fa fa-map"></i>&nbsp;
							<?php  
							if($city) {
								echo esc_attr(  get_post_meta($post->ID, 'qt_city', true) );
							} 
							if($country) {
								echo esc_attr( " (".get_post_meta($post->ID, 'qt_country', true).")" ); 
							}
							?>
						</p>
						<?php } ?>
						<?php
                        /*
                        *
                        *   Prepare coords for the map
                        *
                        */
                        $coord = esc_attr(get_post_meta($post->ID, 'qt_coord', true));
                        if($coord != ''){
                        	$coor = explode( "," , $coord);
                        	if(count($coor) == 2){

                        		$thumb = '';
                        		if ( $thumb = wp_get_attachment_image_src( get_post_thumbnail_id($post->ID), 'medium' ) )  {
				                	$thumb = $thumb['0'];
				                }

				                $markercolor_single = get_post_meta($post->ID, 'qt_placeiconcolor', true);


				                if($markercolor_single) {
				                	$custom_colors[$mapid.$post->ID] = $markercolor_single;
				                }
				                

	                            ?>
	                            <a id="<?php echo esc_js(esc_attr($mapid.$post->ID));?>" class="roundbtn qtPlaces-marker noajax" href="<?php the_permalink(); ?>"
	                                data-clicktarget = "mapbutton<?php echo esc_js(esc_attr($post->ID));?>"
	                                data-mapid = "<?php echo esc_js(esc_attr($mapid));?>"
	                                data-markerid = "<?php echo esc_js(esc_attr($mapid.$post->ID)); ?>"
	                                data-markertitle = "<?php echo esc_js(esc_attr(get_the_title())); ?>"
	                                data-markerimg = "<?php echo (esc_js(esc_url($thumb))); ?>"
	                                data-hidethumbnail = "<?php echo esc_attr((get_post_meta( $post->ID, 'qt_placeicondesign', true ) == 'icon')? "hidethumbnail" : ""); ?>"
	                               	data-filters="<?php echo esc_js(esc_attr($termstring)); ?>"
	                               	data-markercolor = "<?php echo esc_js(esc_attr(  $markercolor ));?>"
	                                data-markerlocation = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_location', true) ));?>"
	                                data-markeraddress = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_address', true) ));?>"
	                                data-markercity = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_city', true) )); ?>"
	                               	data-markercountry = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_country', true) )); ?>"
	                               	data-markerlink = "<?php echo esc_js(esc_url( get_post_meta($post->ID, 'qt_link', true) )); ?>"
	                               	data-markerphone = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_phone', true) )); ?>"
	                               	data-markeremail = "<?php echo esc_js(esc_attr(  get_post_meta($post->ID, 'qt_email', true) )); ?>"
	                                data-lat="<?php echo esc_js(esc_attr($coor[0])); ?>" 
	                                data-lon="<?php echo esc_js(esc_attr($coor[01])); ?>"
	                                data-autozoom="<?php echo esc_js(esc_attr($autozoom)); ?>">
	                            <?php
                            }
                        }else{
                            ?><a href="<?php the_permalink(); ?>" class="roundbtn"><?php
                        }
                    	?>
                    	<?php  
                    	$icon = (get_post_meta( $post->ID, 'qt_placeicon', true ) != '')? get_post_meta( $post->ID, 'qt_placeicon', true ) :  "fa-map-marker";
            

                    	?>
                    	<i class="fa <?php echo esc_attr($icon); ?>"></i>
                    	</a>
					</div>
				<?php endwhile; else: ?>
			   	 	<h4><?php echo esc_attr__("Sorry, no places found","qt-places")?></h4>
			    <?php endif;
			    wp_reset_postdata();
				?>


			</div>
			<div class="qtPlaces-map">
				<div class="qtPlaces-mapcontainer" id="map<?php echo esc_attr($mapid); ?>">
					
				</div>
				<?php if($showfilters){ ?>
				<div class="qtPlaces-tags">
					
					<?php 
					if(count($total_terms) > 1){
					foreach($total_terms as $id => $term){
						?>
						<a href="#" class="qtPlaces-tag" data-placefilter="<?php echo esc_attr(esc_js($term["filterid"])); ?>" data-targetmap="<?php echo esc_attr(esc_js($mapid)); ?>"><i class="fa fa-tag"></i> <?php echo esc_attr($term['name']); ?></a>
						<?php
					}}
					?>
				</div>
				<?php } ?>
			</div>
			<a class="qtPlaces-menuswitch"><i class="fa <?php if($open =="1" || $open =="true"){ ?>fa-close<?php } else { ?>fa-bars<?php } ?>"></i></a>

			<style type="text/css">
				<?php 
				if($buttoncolor) { ?>
					#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list .qtPlaces-entry a.roundbtn { color:<?php  echo esc_attr($buttoncolor); ?>;}
				<?php }
				if($buttonbackground) { ?>
					 #<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list .qtPlaces-entry h4 { border-color: <?php  echo esc_attr($buttonbackground); ?>; }
					 #<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list .qtPlaces-entry a.roundbtn,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list::-webkit-scrollbar-thumb,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-tags .qtPlaces-tag i,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-tags .qtPlaces-tag.active { background: <?php  echo esc_attr($buttonbackground); ?>; }
				<?php }
				if($listbackground) { ?>
					#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list { background: <?php  echo esc_attr($listbackground); ?>; }
				<?php }
				if($markercolor) { ?>
					#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-map .qtPlaces-mapcontainer .qtPlaces-mapmarker .qtPlaces-marker-img,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-map .qtPlaces-mapcontainer .qtPlaces-mapmarker .qtPlaces-marker-img::after,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-map .qtPlaces-mapcontainer .qtPlaces-mapmarker .qtPlaces-marker-img::before  {background:<?php  echo esc_attr($markercolor); ?>; }
				<?php }


				if($mapheight) { ?>

					@media (min-width:1024px){
						#<?php echo esc_attr($mapid); ?>.qtPlaces-container,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list , #<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-map {height: <?php echo esc_attr(intval(str_replace(array("px", "%"),"",trim($mapheight)))); ?>px; }
					}
				<?php } 

				if($mapheightmobile) { 
					if(is_numeric($mapheightmobile)) { 
						if($mapheightmobile < 400) {
							$mapheightmobile = 400;
						}
						?>
						@media (max-width:1023px){
							#<?php echo esc_attr($mapid); ?>.qtPlaces-container,#<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-list , #<?php echo esc_attr($mapid); ?>.qtPlaces-container .qtPlaces-map {height: <?php echo esc_attr(intval(str_replace(array("px", "%"),"",trim($mapheightmobile)))); ?>px; }
						}
				<?php }}?>

				<?php  
				if(count($custom_colors)> 0) {
					foreach($custom_colors as $mid => $color){
						
						?>
						#<?php echo esc_attr($mapid); ?>.qtPlaces-container #<?php echo esc_attr($mid); ?> { background-color: <?php echo esc_attr($color); ?>; }
						#<?php echo esc_attr($mapid); ?>.qtPlaces-container #mapmarker<?php echo esc_attr($mid); ?> .qtPlaces-marker-img, 
						#<?php echo esc_attr($mapid); ?>.qtPlaces-container #mapmarker<?php echo esc_attr($mid); ?> .qtPlaces-marker-img::after,  
						#<?php echo esc_attr($mapid); ?>.qtPlaces-container #mapmarker<?php echo esc_attr($mid); ?> .qtPlaces-marker-img::before  { background-color: <?php echo esc_attr($color); ?>; }

						<?php
					}
				}


				?>
			</style>
			

		</div>

		<!-- ============= END QTPLACES MAP =============================== -->
		<?php
		return ob_get_clean();
	} // post_type_exists
	else {
		return 'QT Places Error: the selected post type doesn\'t exists or is not active in the plugin settings.';
	}
}}

add_shortcode ("qtplaces", "qtplaces_main_shortcode");