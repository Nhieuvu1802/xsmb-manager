/**
 * Load an audio file and decode into PCM data.
 *
 * @link https://developer.mozilla.org/en-US/docs/Web/API/BaseAudioContext/decodeAudioData
 *
 * @param {string} url Full URL for an audio file.
 * @return {Promise}
 */
function loadAudio( url ) {
	return new Promise( ( resolve, reject ) => {
		const request = new XMLHttpRequest();
		request.open( 'GET', url, true );

		// Retrieve the audio file as binary data.
		// @link https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Sending_and_Receiving_Binary_Data
		request.responseType = 'arraybuffer';

		request.onload = () => {
			audioContext.decodeAudioData(
				request.response,
				buffer => {
					resolve( buffer );
				},
				e => reject( e )
			);
		}
		request.send();
	});
}

/**
 * Downsample and retrieve peaks from an audio buffer.
 *
 * @param {number}      length Number of points to retrieve.
 * @param {AudioBuffer} buffer Audio buffer.
 * @return {Object[]} Objects with a min and max property.
 */
function getPeaks( length, buffer ) {
	const sampleSize = Math.floor( buffer.length / length );
	const numberOfChannels = buffer.numberOfChannels;
	const peaks = Array( length );

	for ( let channelIndex = 0; channelIndex < numberOfChannels; channelIndex++ ) {
		const channelData = buffer.getChannelData( channelIndex );

		for ( let i = 0; i < length; i++ ) {
			const start = parseInt( sampleSize * i, 10 );

			const sample = channelData.slice( start, start + sampleSize );
			const max = sample.reduce( ( a, b ) => a > b ? a : b, 0 );
			const min = sample.reduce( ( a, b ) => a < b ? a : b, 0 );

			peaks[ i ] = peaks[ i ] || { max: 0, min: 0 };

			if ( max > peaks[ i ].max ) {
				peaks[ i ].max = max;
			}

			if ( min < peaks[ i ].min ) {
				peaks[ i ].min = min;
			}
		}
	}

	return peaks;
}


/**
 * Draw a waveform on a canvas.
 *
 * @param {string|HTMLCanvasElement} el Canvas element or selector.
 * @param {AudioBuffer} buffer Audio buffer.
 */
function drawCanvas( el, buffer ) {
	const canvas = 'string' === typeof el ? document.querySelector( el ) : el;
	const context = canvas.getContext( '2d' );
	const height = canvas.height / 2;
	const length = canvas.width;
	const peaks = getPeaks( length, buffer );
	const y = value => height - Math.round( value * height );

	context.beginPath();
	context.moveTo( 0, height );

	// Draw the upper path.
	for ( let i = 0; i < length; i++ ) {
		context.lineTo( i, y( peaks[ i ].max ) );
	}

	context.lineTo( length - 1, 0 );

	// Draw the lower path.
	for ( let i = length - 1; i >= 0; i-- ) {
		context.lineTo( i, y( peaks[ i ].min ) );
	}

	context.lineTo( 0, 0 );
	context.fill();
}


/**
 * Create a WordPress media attachment.
 *
 * @param {string} filename Media filename. Also used as the attachment title.
 * @param {Blob}   blob     Raw binary data for the waveform.
 * @return {jQuery.Deferred}
 */
function createMedia( filename, blob ) {
	return wp.apiRequest({
		path: '/wp/v2/media',
		method: 'POST',
		contentType: 'image/png',
		data: blob,
		headers: {
			'Content-Disposition': `attachment; filename="${filename}"`
		},
		processData: false
	});
}


const audioUrl = 'https://example.com/Jimmie Dale Gilmore - Just A Wave, Not the Water.mp3';

loadAudio( audioUrl )
	.then( buffer => {
		const canvas = document.querySelector( '#canvas' );

		drawCanvas( canvas, buffer );

		canvas.toBlob( blob => createMedia( 'waveform.png', blob ) );
	});