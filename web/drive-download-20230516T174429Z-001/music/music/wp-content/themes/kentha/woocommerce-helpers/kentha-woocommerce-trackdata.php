<?php  
/**
 * @package Kentha
 * @subpackage  WooCommerce
 * @since  2.0
 * @version  2.0
 * @author QantumThemes 2019 Oct 07
 * 
 * Add track details in the single product page for single track products
 * 
 */


if( !function_exists( 'kentha_single_track_details' )) {

	add_action('woocommerce_single_product_summary' , 'kentha_single_track_details' , 30);
	function kentha_single_track_details(){
		
		$id = get_the_ID();
		global $product;



		/**
		 * Extract custom fields and taxonomies
		 */
		
		
		$singletrack = get_post_meta( $id, 'kentha_singletrack', true );
		
		// Display table only for single tracks
		if( '1' !== $singletrack ){
			return;
		}

		/**
		 * Details
		 * made from file custom-product-fields.php
		 */
		$kentha_artist = get_post_meta( $id, 'kentha_artist', true );
		if($kentha_artist){
			$kentha_artist_name = get_the_title( $kentha_artist[0] );

		}

		?>
		<div class="qt-woocommerce-trackdata qt-paper qt-card"><?php  


			/**
			 * Audio sample
			 * -----------------------------------
			 */
			// Show the player only if I'm not managing the stock or if I still have some
			if ( ( $product->managing_stock() && $product->is_in_stock() ) || !$product->managing_stock() ){

				$releasetrack_mp3_demo = get_post_meta(  $id, 'releasetrack_mp3_demo', true );
				if( $releasetrack_mp3_demo ){
					$thumb = get_the_post_thumbnail_url( $id ,'kentha-squared');
					$title = get_the_title( $id );
					$link = get_the_permalink( $id );
					?>
					<div class="qt-playlist-large qt-paper">
						<ul class="qt-playlist">
							<li class="qtmusicplayer-trackitem">
								<span class="qt-play qt-link-sec qtmusicplayer-play-btn" 
								data-qtmplayer-cover="<?php echo esc_url($thumb); ?>" 
								data-qtmplayer-file="<?php echo esc_url($releasetrack_mp3_demo); ?>" 
								data-qtmplayer-title="<?php echo esc_attr( $title ); ?>" 
								<?php if($kentha_artist){ ?>data-qtmplayer-artist="<?php echo esc_attr( $kentha_artist_name ); ?>" <?php } ?>
								data-qtmplayer-album="<?php echo esc_attr( kentha_postcategories_text( 1, "trackgenre") ); ?>"
								data-qtmplayer-link="<?php echo esc_url($link); ?>" 
								data-qtmplayer-buylink="<?php echo esc_url($link ); ?>" 
								data-qtmplayer-icon="cart" ><i class='material-icons'>play_circle_filled</i></span>
								<p>
									<span class="qt-tit"><?php echo esc_html( $title ); ?></span><br>
									<span class="qt-art">
										<?php if($kentha_artist){ echo esc_html( $kentha_artist_name);} ?>
									</span>
								</p>
							</li>
						</ul>
					</div>
					<?php
				}
			}


			

			/**
			 * Item details
			 * ----------------------------------------------------
			 */
			?>
			<table>
				<tbody>
					<?php 

					/**
					 * Artist
					 * -----------------------------------
					 */
					
					if( $kentha_artist ){
						?>
						<tr>
							<th><?php esc_html_e( 'Artist', 'kentha' ) ?></th>
							<td><a href="<?php echo get_the_permalink( $kentha_artist[0] ); ?>"><?php echo esc_html( $kentha_artist_name );  ?></a></td>
						</tr>
						<?php 
					}

					/**
					 * BPM
					 * -----------------------------------
					 */
					$kentha_bpm = get_post_meta( $id, 'kentha_bpm', true );
					if( $kentha_bpm ){
						?>
						<tr>
							<th><?php esc_html_e( 'BPM', 'kentha' ) ?></th>
							<td><?php echo esc_html( $kentha_bpm ); ?></td>
						</tr>
						<?php 
					}

					/**
					 * Duration
					 * -----------------------------------
					 */
					$kentha_duration = get_post_meta( $id, 'kentha_duration', true );
					if( $kentha_duration ){
						?>
						<tr>
							<th><?php esc_html_e( 'Duration', 'kentha' ) ?></th>
							<td><?php echo esc_html( $kentha_duration ); ?></td>
						</tr>
						<?php 
					}


					/**
					 * Genres
					 * -----------------------------------
					 */

					$genres = get_the_term_list( $id, 'trackgenre', '<span>', ',</span><span>', '</span>' );
					if( !is_wp_error( $genres ) ){
						?>
						<tr>
							<th><?php esc_html_e( 'Genre', 'kentha' ) ?></th>
							<td><?php echo wp_kses_post( $genres ); ?></td>
						</tr>
						<?php 
					}

					/**
					 * Software
					 * -----------------------------------
					 */

					$softwares = get_the_term_list( $id, 'tracksoftware', '<span>', ',</span><span>', '</span>' );
					if( !is_wp_error( $softwares ) ){
						if( $softwares != ''){
							?>
							<tr>
								<th><?php esc_html_e( 'Software', 'kentha' ) ?></th>
								<td><?php echo wp_kses_post( $softwares ); ?></td>
							</tr>
							<?php 
						}
					}


					/**
					 * Royalties
					 * -----------------------------------
					 */

					$royalties = get_the_term_list( $id, 'royalty-types', '<span>', '</span> / <span>', '</span>' );
					if( !is_wp_error( $royalties ) ){
						if( $royalties != ''){
						?>
						<tr>
							<th><?php esc_html_e( 'Royalties', 'kentha' ) ?></th>
							<td><?php echo wp_kses_post( $royalties ); ?></td>
						</tr>
						<?php 
						}
					}

					?>
				</tbody>
			</table>
		</div>

		<?php  
		if( get_post_meta( $id, 'kentha_hideinfo', true ) == '1' ){
			?>
			<div class="qt-singletrack-description qt-spacer-m ">
				<div class="qt-paper qt-card qt-paddedcontent">
				<?php the_content(); ?>
				</div>
			</div>
			<?php
		}

	}
}







