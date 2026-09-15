/**
 * 
 * Web Api Player by QantumThemes: reproduct music with HTML5 soundApi
 * created by Igor Nardo (QantumThemes)
 * License: you cannot use this software in other way out of the themes or plugins provided by Qantumthemes,
 * you can't edit, copy or modify it to create new products to resell.
 * 
 */
(function ($) {

	 /**
	 * ========================================================================================================================
	 * 
	 * 	Web api player functions 
	 *  TO CALL THE FUNCTIONS FROM THE THEME JS (qt-musicpolayer.php global functions)
	 *
	 * ========================================================================================================================
	 */
	
	var qt_HiQualityEq = $('#qtmusicplayer').data('hiquality'); // set to 1 to use triple visualizer

	$.qtWebApiPlayer = {
		body: $("body"),
		actualSong: false,
		grooveadv: $('#qtmusicplayer-grooveadv'),
		init: function(){
			AudioAnalyser.AudioContext = window.AudioContext || window.webkitAudioContext;
			AudioAnalyser.enabled = (AudioAnalyser.AudioContext !== undefined);	
			if(0 === $('#qtmusicplayer-playlist li').length ){
				return false;
			}
			try {
				settings = {
					"autoplay": false,
					"volume": 1,
					"size": 1024,
					"smoothing": 0.3,
					"mindecibels": -50,
					"maxdecibels": -1,
					"frame": 30,
					"audio": [
						{
							"mp3": $('#qtmusicplayer-playlist li:first-child .qt-play').data('qtmplayer-file'),
							"title": $('#qtmusicplayer-playlist li:first-child .qt-play').data('qtmplayer-title')
						}
					]
				};
				$.qtRaphael.init();
				$.qt_Visualizer.init();
				return true;
			} catch(error) {
				return false;
			}
		},	
		secondsTimeSpanToHMS: function (s) {
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
		HMStoSeconds: function (hms) {
			var a = hms.split(':');
			var seconds = (+a[0]) * 60 * 60 + (+a[1]) * 60 + (+a[2]); 
			return seconds;
		},
		play: function(file){
			var song = {
				"mp3": file,
				"title": file
			};
			if(song.mp3 !== $.qtWebApiPlayer.actualSong){ // resume check
				$.qtWebApiPlayer.AudioAnalyzer.load(song);
				$.qtWebApiPlayer.actualSong = song.mp3;
			}
			$.qtWebApiPlayer.AudioAnalyzer.play();
		},
		pause: function(){
			$.qtWebApiPlayer.AudioAnalyzer.pause();
		},
		seek: function(perc){
			var a = $.qtWebApiPlayer.AudioAnalyzer,
				d = a.audio.duration;

			if(isFinite(perc) && isFinite(d)){
				perc = parseFloat(perc);
				var SecondsToGo = d / 100 * perc;
				$.qtWebApiPlayer.AudioAnalyzer.audio.currentTime = SecondsToGo;
			}
		},
		seekTime: function(t){
			if(t){
				$.qtWebApiPlayer.AudioAnalyzer.audio.currentTime = $.qtWebApiPlayer.HMStoSeconds(t);
			}
		},
		timeupdate: function(perc, time){
			time = $.qtWebApiPlayer.secondsTimeSpanToHMS(Math.round(time));
			$.qtPlayerObj.interface.timeupdate(perc, time);
			$.qtRaphaelCircle.update(perc);
			$.qtMplayerPlaylistCue.update(perc * 100);
		},
		progress: function(perc){
			this.progressPerc = perc;
			$.qtPlayerObj.interface.progressUpdate(perc);
		},
		setvolume: function(vol){
			$.qtWebApiPlayer.AudioAnalyzer.audio.volume = vol;
		},
		setDuration: function(dur){
			$.qtPlayerObj.interface.setDuration($.qtWebApiPlayer.secondsTimeSpanToHMS(Math.round(dur)));
		},
		next: function(){
			$.qtPlayerObj.interface.next();
		}
	}

	/**
	 * ========================================================================================================================
	 * 
	 * Audio Analyzer main script 
	 *
	 * ========================================================================================================================
	 */
	var codecs = {
			mp3: 'audio/mpeg',
			ogg: 'audio/ogg',
			webm: 'audio/webm'
		},
		settings;
	function remove(node) {
		if(node.parentNode) {
			node.parentNode.removeChild(node);
		}
	}
	function inReverse(a, b) {
		return b.localeCompare(a);
	}
	function AudioAnalyser() {
		this.audio = new Audio();
		this.audio.crossOrigin = "anonymous";
		this.canplay = false;
		this.seeking = false;


		this.context = new AudioAnalyser.AudioContext();



		this.analyser = this.context.createAnalyser();
		this.analyser.fftSize = settings.size * 2; /* The amount of data values is generally half the fftSize */
		this.analyser.smoothingTimeConstant = settings.smoothing;
		this.analyser.minDecibels = settings.mindecibels;
		this.analyser.maxDecibels = settings.maxdecibels;
		this.source = null;
		this.gainNode = null;
		this.events = {};
		this.song =  -1; /* calling next() will load first song */
	}
	AudioAnalyser.prototype.next = function () {
		$.qtWebApiPlayer.next();
	};
	AudioAnalyser.prototype.preload = function () {
		this.song = (this.song + 1) % settings.audio.length;
		this.load(settings.audio[this.song]);
	};
	AudioAnalyser.prototype.last = function () {
		// this.song = (this.song + settings.audio.length - 1) % settings.audio.length;
		// this.load(settings.audio[this.song]);
	};
	AudioAnalyser.prototype.initialize = function () {
		var self = this,
			percent, durSec, 
			trackDurationSec = false;
		['canplay', 'ended', 'pause', 'playing', 'progress', 'timeupdate'].forEach(function (name) {
			self.audio.addEventListener(name, function (event) {
				self.emit(name, event);
			});
		});
		self.audio.addEventListener('canplay', function () {
			var canplay = self.canplay;
			self.canplay = true;
			if( $.qtWebApiPlayer.AudioAnalyzer.audio.duration !== "undefined"){
				$.qtWebApiPlayer.setDuration($.qtWebApiPlayer.AudioAnalyzer.audio.duration);
			}
			if(settings.autoplay) {
				// self.play();
			}
			$.qtPlayerObj.interface.bufferEnd();
			if(AudioAnalyser.enabled && !canplay) {
				self.source = self.context.createMediaElementSource(self.audio);
				self.source.connect(self.analyser);
				self.gainNode = self.context.createGain();
				self.gainNode.gain.setTargetAtTime(settings.volume, self.context.currentTime, 0.02);
				$.qtWebApiPlayer.AudioAnalyzer.audio.volume = self.gainNode.gain.value;
				self.analyser.connect(self.gainNode);
				self.gainNode.connect(self.context.destination);
			}
		});
		self.addEventListener('seeking', function (event) {
			self.pause();
			self.seeking = true;
			self.audio.currentTime = event.currentTime;
			$.qtPlayerObj.interface.bufferStart();
		});
		self.addEventListener('seeked', function (event) {
			self.seeking = false;
			if(event.resume) {
				self.play();
			}
			$.qtPlayerObj.interface.bufferEnd();
		});
		self.addEventListener('timeupdate', function () {
			percent = $.qtWebApiPlayer.AudioAnalyzer.audio.currentTime / $.qtWebApiPlayer.AudioAnalyzer.audio.duration;
			$.qtWebApiPlayer.timeupdate(percent, $.qtWebApiPlayer.AudioAnalyzer.audio.currentTime);
		});
		self.addEventListener('progress', function () {
			if( $.qtWebApiPlayer.AudioAnalyzer.audio.buffered.length > 0) {
				var percentEnd =  $.qtWebApiPlayer.AudioAnalyzer.audio.buffered.end(0) /  $.qtWebApiPlayer.AudioAnalyzer.audio.duration;
				$.qtWebApiPlayer.progress(percentEnd);

			}
		});
		self.audio.addEventListener('ended', self.next.bind(self));
		self.preload();
	};

	AudioAnalyser.prototype.load = function (song) {
		var audio = this.audio,
			props = Object.getOwnPropertyNames(song),
			i,
			prop,
			source;
		if(audio){
			audio.pause();
		}
		Array.prototype.slice.call(audio.children).forEach(remove);
		props.sort(inReverse);
		for(i = 0; i < props.length; i++) {
			prop = props[i];

			if(prop === 'title') {
				this.emit('title', {title: song[prop]});
			} else {
				source = document.createElement('source');
				source.type = codecs[prop];
				source.src = song[prop];
				audio.appendChild(source);
			}
		}
		audio.controls = true;
		if(settings.autoplay) {
			audio.autoplay = false;
		}
		audio.playing = false;
		audio.load();
		$.qtPlayerObj.interface.bufferStart();
	};
	AudioAnalyser.prototype.play = function () {
		if(this.audio.paused && this.canplay && !this.seeking) {
			this.audio.play();
			this.audio.playing = true;
		}
	};
	AudioAnalyser.prototype.pause = function () {
		if(!this.audio.paused) {
			this.audio.pause();
			this.audio.playing = false;
		}
	};
	AudioAnalyser.prototype.addEventListener = function (event, callback) {
		if(typeof callback !== 'function' || (this.events[event] && !this.events.hasOwnProperty(event))) {
			return;
		}
		if(!this.events.hasOwnProperty(event)) {
			this.events[event] = [callback];
		} else if(Array.isArray(this.events[event])) {
			this.events[event].push(callback);
		}
	};
	AudioAnalyser.prototype.emit = function (event, data) {
		if(this.events.hasOwnProperty(event) && Array.isArray(this.events[event])) {
			for(var i = 0; i < this.events[event].length; i++) {
				this.events[event][i].call(this, data);
			}
		}
	};
	// AudioAnalyser.AudioContext = window.AudioContext || window.webkitAudioContext;
	// AudioAnalyser.enabled = (AudioAnalyser.AudioContext !== undefined);




	/**
	 * ======================================================================================================
	 * 
	 *
	 *     qt_Visualizer
	 *
	 *
	 * ======================================================================================================
	 **/

	function qt_getSum(total, num) {
	    return total + num;
	}
	var sum;

	$.qt_Visualizer = {
		init: function (){
			var self = this,
				i,
				canvas,
				effect;
			var arrBass = arrMid = arrTop = [];
			$.qtWebApiPlayer.AudioAnalyzer = new AudioAnalyser();
			self.audioanalyser = $.qtWebApiPlayer.AudioAnalyzer;
			self.timeout = null;
			self.canvases = [];
			self.contexts = [];
			self.sizes = new Array(1);
			self.sizes[0] = 100; // sta cosa causa un bug dopo
			$.qtWebApiPlayer.AudioAnalyzer.initialize();
			self.audioanalyser.addEventListener('playing', function () {
				if(self.timeout === null) {
					self.timeout = setInterval($.qt_Visualizer.qt_draw.bind(self), settings.frame);
				}
			});
		},
		qt_draw: function () {
			var analyser = this.audioanalyser.analyser,
				timeData = new Uint8Array(Math.min(analyser.fftSize, Math.max.apply(Math, this.sizes))),
				freqData = new Uint8Array(Math.min(analyser.frequencyBinCount, Math.max.apply(Math, this.sizes)));
			analyser.getByteFrequencyData(freqData);
			// Since 1.9.0 
			// Added control to see if i have to draw or not, save gpu in standby
			sum = freqData.reduce(qt_getSum);
			if( freqData.reduce(qt_getSum) > 0){
				$.qt_Visualizer.qt_drawFFT(freqData);
			}
		},
		qt_drawFFT: function (data) {
			var i;/* data index */
			if(qt_HiQualityEq){
				arrBass = [];
				arrMid = [];
				arrTop = [];
				for(i = 1 ; i < 10; i++) {
					arrBass[i] = Math.round (data[i]);
				}
				for(i = 10; i < 30; i++) {
					arrMid[i-10] = Math.round (data[i]);
				}
				for(i = 30; i < 50; i++) {
					arrTop[i-30] = Math.round (data[i]);
				}
				$.qtRaphael.animEq(arrBass, 60, $.qtRaphael.bgBass, 0.5); // 40
				$.qtRaphael.animEq(arrMid, 50, $.qtRaphael.bgMid, 0.7); // 20
				$.qtRaphael.animEq(arrTop, 20, $.qtRaphael.bgTop, 0.8); // 8

			} else {
				arr = [];
				
				// WHI I+2? because first frequencies are usually ' in mastered tracks, are 20 and 30 hz'
				for(i = 0; i < 5; i++) {
					arrTop[i] = data[i+2]*0.6;
				}
				for(i = 5; i < 16; i++) {
					arrTop[i] = data[i+2]*0.7;
				}
				for(i = 16; i <= 38; i++) {
					arrTop[i] = data[i+2]*0.8;
				}
				for(i = 38; i <= 44; i++) {
					arrTop[i] = data[i+2]*1.2;
				}
				$.qtRaphael.animEq(arrTop, 15, $.qtRaphael.bgTop, 0.9);

			}
		}
	}
	
	
	/**
	 * ======================================================================================================
	 * 
	 *
	 *      RAPHAEL: Visualizzatione pura
	 *
	 *
	 * ======================================================================================================
	 **/
	
	$.qtRaphael = {
		container: $("#qtmusicplayerFFT"),
		color: $("#qtmusicplayerFFT").data("color"),
		cH: $("#qtmusicplayerFFT").height() - 30,
		cW: $("#qtmusicplayerFFT").width(),
		init: function(){
			var AR = $.qtRaphael,
				container = AR.container,
				color = AR.color,
				cW, cH;
			AR.cH = $("#qtmusicplayerFFT").height();
			AR.cW = $("#qtmusicplayerFFT").width();
			cW = AR.cW,
			cH = AR.cH;
			var paper = Raphael("qtmusicplayerFFT", cW, $(window).height());
			var dotsy = [];
			c = paper.path("M0,0").attr({fill: "none", "stroke-width": 4, "stroke-linecap": "round"});
			AR.bgBass = paper.path("M0,0").attr({stroke: "none", opacity: .5});
			AR.bgMid = paper.path("M0,0").attr({stroke: "none", opacity: .6});
			AR.bgTop = paper.path("M0,0").attr({stroke: "none", opacity: .8});
			var path = AR.eqPath([cH,1]) + "L"+cW+","+cH+" 0,"+cH+"z";
			AR.bgBass.attr({
				path: path, 
				fill: color});
			AR.bgMid.attr({
				path: path, 
				fill: color});
			AR.bgTop.attr({
				path: path, 
				fill: color});
		},
		eqPath: function(heights, factor) {
			var AR = $.qtRaphael,
				path = "",
				x = 0,
				y = 0,
				dotsy = dotsy || [],
				cH = AR.cH,
				cW = AR.cW,
				inc = Math.round(cW / (heights.length-1)) ;
			path += "M0,"+cH;
			for (var i = 0; i < heights.length; i++) {
				dotsy[i] = Math.round((heights[i] / 100) * AR.cH * factor);

				y = cH - (dotsy[i]);

				if(x == 0){
					path += ",L" + [x, y]+ 'S';
				} else {
					path += "," + [x, y];
				}
				
				x += inc;
			}
			if(qt_HiQualityEq){
				path += "," + [cW, cH];
			} else {
				path += ",L" + [cW, cH];
			}
			path += ",L0,"+cH;
			return path;
		},
		animEq: function(points, refresh, object, factor){
			var AR = $.qtRaphael,
				anim = Raphael.animation(
					{
						path: AR.eqPath(points, factor)
						, stroke: AR.color
					}, 
					refresh, "<>"
				),
				cH = AR.cH,
				cW = AR.cW;
			object.animate (anim, {path: AR.eqPath(points, factor) + "L"+cW+","+cH+" 0,"+cH+"z", 
			fill: AR.color}, refresh, "<>");
		}
	}
})(jQuery);





