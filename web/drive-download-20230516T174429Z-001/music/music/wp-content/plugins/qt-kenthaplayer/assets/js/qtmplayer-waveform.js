
var qtmplayer_audioContext = new ( window.AudioContext || window.webkitAudioContext )();

function qtmplayer_loadAudio( url ) {
	return new Promise( ( resolve, reject ) => {
		const request = new XMLHttpRequest();
		request.open( 'GET', url, true );
		request.responseType = 'arraybuffer';

		request.onload = () => {
			qtmplayer_audioContext.decodeAudioData(
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

function qtmplayer_generateWaveform({ audioId, audioUrl, filename, canvas, container }) { //{ audioId, audioUrl, filename, ttgcore_screen }
	var myCanvasContext = canvas[0];
	return 	qtmplayer_loadAudio( audioUrl ).then( buffer => {
		var waveform = new Waveform({
			buffer: buffer
		});
		waveform.draw({
			el: myCanvasContext
		})
	}).then( blob => {
		container.addClass( 'loaded' );
		
		var img    = myCanvasContext.toDataURL("image/png");
		container.find("#qtMplayerprogWave").remove();
		container.append('<div id="qtMplayerprogWave" class="qt-mplayer__waveformp"><img src="'+img+'"/></div>');
		// container.append('	<div class="qt-mplayer__waveformprogress"></div>');
		// container.find( "canvas" ).clone().appendTo( ".qt-mplayer__waveformprogress" );
	});
}
