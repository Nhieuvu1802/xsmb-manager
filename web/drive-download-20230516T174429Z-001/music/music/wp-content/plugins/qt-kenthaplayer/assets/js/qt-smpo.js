/**==============================================================================================================================
 * 
 * SoundManager player object
 * $.qtSMPO.sm = soundManager
 * 
 ==============================================================================================================================*/

(function ($) {


	



	$.qtSMPO = {
		sm: soundManager,
		playerCont: $('#qtmusicplayer'),
		soundId: 'qtSoundId',
		init: function(){
			var ob = $.qtSMPO,
				flashpath =  ob.playerCont.data("qtmusicplayer-smflash");
			$.qtPlayerObj.interface.log('qtSMPO init');
			$.qtSMPO.sm.setup({
				url: flashpath,
				preferFlash: false,
				bufferTime: 3000,
				onready: function() {
					$.qtPlayerObj.interface.log('qtSMPO init onready');
					// $.qtPlayerObj.initPlayer();
				}
			});
			return true;
		},
		smPause: function(){
			$.qtSMPO.sm.pause($.qtSMPO.soundId);
			$.qtPlayerObj.interface.log('qtSMPO smPause');
		},
		secondsTimeSpanToHMS: function(s){
			var h = Math.floor(s/3600); //Get whole hours
		    s -= h*3600;
		    var m = Math.floor(s/60); //Get remaining minutes
		    s -= m*60;
		    if(s > 3600){
		    	return h+":"+(m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
		    } else {
		    	return (m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
		    }
		},
		smPlay: function(){
			var smp = $.qtSMPO,
				sm = $.qtSMPO.sm,
				id = $.qtSMPO.soundId,
				ob = $.qtPlayerObj,
				interface = ob.interface,
				percLoaded;
			if(sm.nowplaying === ob.songdata.file){
				sm.play(id);
			} else {
				interface.log("> smPlay A");
				sm.destroySound(id);
				sm.nowplaying = ob.songdata.file;
				sm.sound = sm.createSound({
					id: id,
					url: ob.songdata.file,
					autoLoad: true,
					autoPlay: true,
					volume: 90,
					onload: function() {
						interface.log("> smPlay B onload");
					},
					whileplaying : function(){
						var duration = sm.sound.duration,
							position = sm.sound.position,
							perc = position /duration,
							time,
						 	s = Math.round(sm.sound.position) / 1000,
					    	h = Math.floor(s/3600); //Get whole hours
					    s -= h*3600;
					    var m = Math.floor(s/60); //Get remaining minutes
					    s -= m*60;
					    s = Math.round(s);
					    if(s > 3600){
					    	time = h+":"+(m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
					    } else {
					    	time = (m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
					    }
					    interface.timeupdate(perc, time);
					    $.qtRaphaelCircle.update(perc);
					    $.qtMplayerPlaylistCue.update(perc * 100);
					},
					onbufferchange: function(){
						interface.log("> smPlay D onbufferchange");
						if(sm.sound.isBuffering){
							interface.bufferStart();
						} else {
							interface.setDuration(smp.secondsTimeSpanToHMS(Math.round(sm.sound.duration / 1000)));
							interface.bufferEnd();
						}
					},
					whileloading: function(){
						percLoaded = sm.sound.bytesLoaded / sm.sound.bytesTotal;
						interface.progressUpdate(percLoaded);
						interface.log("> smPlay F whileloading"+percLoaded);
					},
					onPosition : function(){

					},
					onfinish: function(){
						interface.log("> smPlay G onfinish");
						interface.next();
					}
				});
			}
		},
		smSeek: function(perc){
			if( undefined === $.qtSMPO.sm.sound){ 
				return; 
			}
			var cue = $.qtSMPO.sm.sound.duration * perc / 100,
				time,
			 	s = Math.round($.qtSMPO.sm.sound.duration) / 1000 / 100 * perc,
		    	h = Math.floor(s/3600); //Get whole hours
		    s -= h*3600;
		    var m = Math.floor(s/60); //Get remaining minutes
		    s -= m*60;
		    s = Math.round(s);
		    if(s > 3600){
		    	time = h+":"+(m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
		    } else {
		    	time = (m < 10 ? '0'+m : m)+":"+(s < 10 ? '0'+s : s);
		    }
		    $.qtPlayerObj.interface.timeupdate(perc/100, time);
			$.qtSMPO.sm.setPosition($.qtSMPO.soundId,cue);
		},
		smSeekTime: function(t){
			var a = t.split(':');
			var sec = parseInt(a[0]*3600) + parseInt(a[1]*60) + parseInt(a[2]);
			var ms =  sec * 1000; 
			var perc = ms / $.qtSMPO.sm.sound.duration * 100;
			$.qtPlayerObj.interface.timeupdate(perc, t);
			$.qtSMPO.sm.setPosition($.qtSMPO.soundId, ms);
		}
	};
})(jQuery);