<?php  
/**
 * @package QT Chartvote
 * 
 */

if(!function_exists('qt_chartvote_track_vote')){
function qt_chartvote_track_vote()
{
	// Check for nonce security
	$nonce = $_POST['nonce'];
	if ( ! wp_verify_nonce( $nonce, 'chartvote-nonce' ) )
		die ( 'Illegal token.');

	if(!array_key_exists('chartid', $_POST) || !array_key_exists('position', $_POST) || !array_key_exists('move', $_POST) ) {
		echo 'Missing data';
		exit;
	}

	if(isset($_POST['chartid']))
	{
		/**
		 * 1. Get the chart meta field
		 */
		$events = get_post_meta( $_POST['chartid'], 'track_repeatable', true);   
		$mytrack = $events[ $_POST['position'] ];
		
		if($mytrack['releasetrack_rating'] == ''){
			$mytrack['releasetrack_rating'] = 0;
		}
		$new_vote_value =  intval( $mytrack['releasetrack_rating'] ) + intval ( $_POST['move'] );
		
		// Save the data
		$events[ $_POST['position'] ]['releasetrack_rating'] = $new_vote_value;
		$data = array(
			'ID' => $_POST['chartid'],
			'POSITION' =>  $_POST['position'],
			'MOVE' =>  $_POST['move'],
			'newvalue' => $new_vote_value
			);
		if( update_post_meta($_POST['chartid'], "track_repeatable", $events) ){
			print_r(json_encode($data));
		} 
	}
	exit;
}}

