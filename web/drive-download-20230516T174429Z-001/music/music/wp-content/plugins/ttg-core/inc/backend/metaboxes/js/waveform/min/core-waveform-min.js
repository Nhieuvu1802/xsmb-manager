
var ttgcore_audioContext = new ( window.AudioContext || window.webkitAudioContext )();

function ttgcore_loadAudio( url ) {
	return new Promise( ( resolve, reject ) => {
		const request = new XMLHttpRequest();
		request.open( 'GET', url, true );
		request.responseType = 'arraybuffer';

		request.onload = () => {
			ttgcore_audioContext.decodeAudioData(
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

function ttgcore_generateWaveform({ audioId, audioUrl, filename, canvas }) { //{ audioId, audioUrl, filename, ttgcore_screen }
	console.log("generating waveform!!!!!");
	var myCanvasContext = canvas[0];
	return 	ttgcore_loadAudio( audioUrl ).then( buffer => {
		var waveform = new Waveform({
			buffer: buffer
		});
		waveform.draw({
			el: myCanvasContext
		});
	});
}


