<?php  
/**
 * @since  2.2.0
 * @requires WooCommerce + Single Track prroduct option enabled in the customized
 * =================================================
 * WooCommerce single track product
 * =================================================
 */

if ( class_exists( 'WooCommerce' ) ) {
	if( get_theme_mod('kentha_woocommerce_singletrack_enable') ){

		/**
		 * =================================================
		 * Kentha preload product featured
		 * =================================================
		 * @since 2.1.1
		 * @var array
		 * Featured releases by ID
		 */
		$featureds = get_theme_mod( 'kentha_player_prodfeatured' );
		$ids_featured = false;
		if ($featureds){
			$ids_featured = str_replace(' ', '', $featureds);
			$args = array (
				'post_type' =>  'product',
				'post__in'=> explode(',',$ids_featured),
				'orderby' => 'post__in',
				'meta_query' => array(
					'relation' => 'AND',
					array(
						'key' => 'kentha_singletrack',
						'value' => '1',
						'compare' => 'LIKE'
					),
					array(
						'key' => 'releasetrack_mp3_demo',
						'compare' => 'EXISTS'
					),
					array (
						'key' => '_stock_status',
						'value' => 'instock',
						'compare' => '=',
					)
				)
			);  
			$wp_query = new WP_Query( $args );
			if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
				$post = $wp_query->post;
				setup_postdata( $post );
				$id =  $post->ID;
				$releasetrack_mp3_demo = get_post_meta(  $id, 'releasetrack_mp3_demo', true );
				$thumb = get_the_post_thumbnail_url( $id ,'kentha-squared');
				$title = get_the_title( $id );
				$link = get_the_permalink( $id );
				$kentha_artist = get_post_meta( $id, 'kentha_artist', true );
				$kentha_artist_name = false;
				if($kentha_artist){
					$kentha_artist_name = get_the_title( $kentha_artist[0] );
				}
				?>
				<li class="qtmusicplayer-trackitem">
					<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
					data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" 
					data-qtmplayer-file="<?php echo esc_url($releasetrack_mp3_demo); ?>" 
					data-qtmplayer-title="<?php echo esc_attr( $title ); ?>" 
					<?php if( $kentha_artist_name ) { ?>data-qtmplayer-artist="<?php echo esc_attr( $kentha_artist_name ); ?>" <?php } ?>
					data-qtmplayer-album="" 
					data-qtmplayer-link="<?php echo esc_url($link); ?>" 
					data-qtmplayer-buylink="<?php echo esc_url($link ); ?>" 
					data-qtmplayer-icon="add_shopping_cart" ><i class='material-icons'>play_circle_filled</i></span>
					<p>
						<span class="qt-tit"><?php echo esc_html( $title ); ?></span><br>
						<span class="qt-art">
							<?php if( $kentha_artist_name ) { echo esc_html( $kentha_artist_name);} ?>
						</span>
					</p>
				</li>
				<?php
			endwhile; endif; 
			wp_reset_postdata();
		}

		/**
		 * Default products
		 * @since 2.1.1
		 */
		$products_amount = intval( get_theme_mod( 'kentha_player_prodamount', '1' ) );
		if ($products_amount !== 0){
			$args = array(
				'post_type' => 'product',
				'ignore_sticky_posts' => 1,
				'post_status' => 'publish',
				'orderby' => array ( 'menu_order' => 'ASC', 'date' => 'DESC'),
				'suppress_filters' => false,
				'posts_per_page' => $products_amount, // @since 1.9.0
				'paged' => 1,
				'meta_query' => array(
					'relation' => 'AND',
					array(
						'key' => 'kentha_singletrack',
						'value' => '1',
						'compare' => 'LIKE'
					),
					array(
						'key' => 'releasetrack_mp3_demo',
						'compare' => 'EXISTS'
					)					
				)
			);

			/**
			 * Remove featured IDS from the result to avoid duplicates
			 * @since 1.9.0 + 2.1.1
			 */
			if( $ids_featured ){
				$args['post__not_in'] = explode(',',$ids_featured);
			}
			$wp_query = new WP_Query( $args );
			if ( $wp_query->have_posts() ) : while ( $wp_query->have_posts() ) : $wp_query->the_post();
				$post = $wp_query->post;
				setup_postdata( $post );
				$id =  $post->ID;
				$releasetrack_mp3_demo = get_post_meta(  $id, 'releasetrack_mp3_demo', true );
				$thumb = get_the_post_thumbnail_url( $id ,'kentha-squared');
				$title = get_the_title( $id );
				$link = get_the_permalink( $id );
				/**
				 * Details
				 * made from file custom-product-fields.php
				 */
				$kentha_artist_name = false;
				$kentha_artist = get_post_meta( $id, 'kentha_artist', true );
				if($kentha_artist){
					$kentha_artist_name = get_the_title( $kentha_artist[0] );
				}
				?>
				<li class="qtmusicplayer-trackitem">
					<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
					data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" 
					data-qtmplayer-file="<?php echo esc_url($releasetrack_mp3_demo); ?>" 
					data-qtmplayer-title="<?php echo esc_attr( $title ); ?>" 
					<?php if( $kentha_artist_name ) { ?>data-qtmplayer-artist="<?php echo esc_attr( $kentha_artist_name ); ?>" <?php } ?>
					data-qtmplayer-album="<?php echo esc_attr($title); ?>" 
					data-qtmplayer-link="<?php echo esc_url($link); ?>" 
					data-qtmplayer-buylink="<?php echo esc_url($link ); ?>" 
					data-qtmplayer-icon="add_shopping_cart" ><i class='material-icons'>play_circle_filled</i></span>
					<p>
						<span class="qt-tit"><?php echo esc_html( $title ); ?></span><br>
						<span class="qt-art">
							<?php if( $kentha_artist_name ) { echo esc_html( $kentha_artist_name);} ?>
						</span>
					</p>
				</li>
				<?php
			endwhile; endif; 
			wp_reset_postdata();
		}
		/**
		 * =================================================
		 * END OF Kentha preload podcast
		 * =================================================
		 */
	}
}