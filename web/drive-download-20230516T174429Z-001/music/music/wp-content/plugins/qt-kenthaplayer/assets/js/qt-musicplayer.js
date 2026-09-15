/** @license
 *
 * Kentha Player: JavaScript player with audio analyzer
 * Version: 1.9.8
 * ----------------------------------------------
 * http://qantumthemes.com/
 *
 * Copyright (c) 2018, QantumThemes / Igor Nardo. All rights reserved.
 * This software cna be used only within our products. It can't be edited or modified for reuse under other projects.
 * Cannot be re-sold or embedded in other products for sale.
 *
 */


// IMPORTANT: THE FOLLOWINT IS NOT A COMMENT! IT IS JAVASCIPT IMPORTING! DO NOT DELETE
// ===================================================================================
// @codekit-prepend "warning.js"
// @codekit-prepend "../soundmanager/script/soundmanager2-nodebug-jsmin.js"
// @codekit-prepend "qt-smpo.js"
// @codekit-prepend "qt-webapiplayer.js"

(function($){

	var qtPlayDebug = false;
	var qtmPlayerContainer  = $('#qtmusicplayer');
	var qtMplayerisMobile  = qtmPlayerContainer.data('is-mobile');
	var qtShowPlayer  = qtmPlayerContainer.data('showplayer'); // disable webaudio
	var qtAnalyzer  = qtmPlayerContainer.data('analyzer'); // disable webaudio
	$.qtInitialized = false;
	var qtPlayIsAllowed = false;

	
	var qtMplayerWaveformContainer =  $('#qtmusicplayerWF');
	var qtMplayerWaveformContainerP =  $('#qtmusicplayerWFP');
	var qtMplayerisIphone = /iPhone/i.test(navigator.userAgent);
	

	var qtHaveProblem = 0;

	if( /MSIE|Edge|Trident/i.test(navigator.userAgent) || ( navigator.userAgent.indexOf('Safari') != -1 && navigator.userAgent.indexOf('Chrome') == -1 ) ){
		qtAnalyzer = 0;
	}

	function qtMplayer_filename(path){
	    path = path.substring(path.lastIndexOf("/")+ 1);
	    return (path.match(/[^.]+(\.[^?#]+)?/) || [])[0];
	}

	$.qtMplayerWaveform = function(fileurl){
		/**
	 	 * 
	 	 * Waveform generator here
	 	 * @since 2018 08 02
	 	 * @requires core-waveform.js
	 	 * 
	 	 */
		if( 'function' === typeof(qtmplayer_generateWaveform) ){
			var id = 'CurAudio';
			var filename = qtMplayer_filename(fileurl);
			var qtMplayerCanvas = qtMplayerWaveformContainer.find('canvas');
			var qtMplayerCanvasP = qtMplayerWaveformContainerP.find('canvas');
			// return;
			ttgcore_waveresult  = qtmplayer_generateWaveform({
				audioId: id,
				audioUrl: fileurl,
				filename: filename,
				canvas: qtMplayerCanvas,
				container: qtMplayerWaveformContainer
			});
		} 
	}



	$.qtMplayerPlaylistCue = {
		init: function(){
			$.qtMplayerPlaylistCue.destroy();
			var item = $("li.qtmusicplayer-played");
			if(item.length > 0){
				var offset = item.offset().left,
					width =  item.width(),
					left = 0,
					perc = 0,
					minicue, det;
				item.append('<span id="qtCueDet" class="qt-mplayer-track-det"></span><span id="qtMplayerPlaylistTrackAdv" class="qt-mplayer-track-adv qt-content-accent"></span><span id="qtMplayerPlaylistTrackMinicue" class="qt-mplayer-track-minicue"></span>');
				minicue = $("#qtMplayerPlaylistTrackMinicue");
				det = $("#qtCueDet");
				det.off("mousemove").off("click");
				det.on("mousemove", function(e){
					left = e.clientX - offset;
					minicue.css({'left': left});
				});
				det.on("click", function(e){
					perc = Math.round( (e.clientX - offset) / width * 100 );
					$.qtPlayerObj.uniPlayer.seek(perc);
				});
			}
		},
		update:function(p){
			$("#qtMplayerPlaylistTrackAdv").css({"width": p+'%'});
		},
		destroy: function(){
			$("#qtMplayerPlaylistTrackAdv").remove();
			$("#qtMplayerPlaylistTrackMinicue").remove();
			$("#qtCueDet").remove();
		}
	};

	/**
	 * ===========================================================================
	 * Circle for podcast
	 * @type {Object}
	 * ===========================================================================
	 */
	$.qtRaphaelCircle = {
		container: $(".qt-circularplayer"),
		findXY: function(obj) {
			var curleft = 0, curtop = 0;
			do {
				curleft += obj.offsetLeft;
				curtop += obj.offsetTop;
			} while (!!(obj = obj.offsetParent));
			return [curleft,curtop];
		},
		getScrollLeft: function() {
			return ($('body').scrollLeft+document.documentElement.scrollLeft);
		},
		getScrollTop: function() {
			return ($('body').scrollTop+document.documentElement.scrollTop);
		},
		init: function(){
			var RC = $.qtRaphaelCircle,
				rcontainer = $("#qtdonut"),
				cH = rcontainer.height(),
				cW = rcontainer.width(),
				R = cH / 2;
			RC.destroy();
			rcontainer.find("svg").remove();
			RC.R = R;
			var archtype = new Raphael("qtdonut", cW, cH);
			archtype.customAttributes.arc = function (xloc, yloc, value, total, R) {
				var alpha = 360 / total * value,
					a = (90 - alpha) * Math.PI / 180,
					x = xloc + R * Math.cos(a),
					y = yloc - R * Math.sin(a),
					path;
				if (total === value) {
					path = [
						["M", xloc, yloc - R],
						["A", R, R, 0, 1, 1, xloc - 0.01, yloc - R]
					];
				} else {
					path = [
						["M", xloc, yloc - R],
						["A", R, R, 0, +(alpha > 180), 1, x, y]
					];
				}
				return {
					path: path
				};
			};
			var my_arc = archtype.path().attr({
				"stroke": "#fff",
				"stroke-width": 60,
				arc: [0, 0, 0, 0, 0]
			});
			RC.arc = my_arc;
			var	uA = navigator.userAgent,
				isOpera = (uA.match(/opera/i)),
				isChrome = (uA.match(/chrome/i)),
				isTouchDevice = (uA.match(/ipad|iphone/i)),
				fullCircle = (isOpera||isChrome?359.9:360),
				angle, offl, offt,
				dx,dy,coords, perc;

			rcontainer.on('click','svg',function(e){
				e = e?e:window.event;
				if (isTouchDevice && e.touches) {
					e = e.touches[0];
				}
				if (e.pageX || e.pageY) {
					coords = [e.pageX,e.pageY];
				} else if (e.clientX || e.clientY) {
					coords = [e.clientX+RC.getScrollLeft(),e.clientY+RC.getScrollTop()];
				}
				offl = rcontainer.offset().left;
				offt = rcontainer.offset().top - $(window).scrollTop() ;
				dx = e.clientX -  (offl + (cW / 2));
				dy = e.clientY -  (offt + (cH / 2));
				angle = Math.floor(fullCircle-(  (Math.atan2(dx,dy) * 180/Math.PI )  +180));
				perc = angle/fullCircle * 100;
				$.qtPlayerObj.uniPlayer.seek(perc);
			});
		},
		update: function(p){
			var RC = $.qtRaphaelCircle,
				R = RC.R;
			if(typeof(p) === 'undefined' || typeof(RC.arc) === 'undefined' ){
				return;
			}
			if(isNaN(p)){
				return;
			}
			RC.arc.animate({
				arc: [R, R, p*100, 100, R]
			}, 2, "ease");
		},
		destroy: function(){
			var RC = $.qtRaphaelCircle;
			if(typeof(RC.arc) !== 'undefined'){
				RC.arc.remove();
			}
		}
	};


	$.qtPlayerObj = {
		isSoundApi: false,
		webAudioIsInitialized: false,
		uniPlayer: {
			btnPlay: $("#qtmusicplayerPlay"),
			canMoove: true,
			pause: function(){
				$.qtPlayerObj.uniPlayer.btnPlay.find("i").html("play_arrow");
				if($.qtPlayerObj.isSoundApi === true){
					$.qtWebApiPlayer.pause();
				} else {
					$.qtSMPO.smPause();
				}
			},
			webapiPlay: function(){
				$.qtWebApiPlayer.play($.qtPlayerObj.songdata.file);
				// $.qtPlayerObj.interface.doSpinner();
			},
			play: function(){

				
				var o = $.qtPlayerObj,
					i = o.interface,
					u = o.uniPlayer;

				i.log('uniPlayer play');
				i.log("======> play A");

				i.doSpinner(true);

				if('object' === typeof($.qtKentharadioObj)){
					if( 'function' === typeof( $.qtKentharadioObj.fn.radioSong ) ){
						$.qtKentharadioObj.fn.radioSong();
					}
				}

				if (u.btnPlay.find("i").html() === 'pause') {
					i.log("======> play B return");
					return;
				}
				if($.qtInitialized && qtPlayIsAllowed){
					i.log("======> play C - good");
					u.btnPlay.find("i").html("pause");

					if(o.isSoundApi === true){
						i.log("======> play D - isSoundApi");
						$.qtWebApiPlayer.pause();
						$.qtWebApiPlayer.play(o.songdata.file);
					} else {
						i.log("======> play E - NO SoundApi");
						$.qtSMPO.smPause();
						$.qtSMPO.smPlay();
					}
				} else {
					i.log("======> play F - blocked:"+$.qtInitialized+' - '+qtPlayIsAllowed);
				}
			},
			seek: function(p){ // p = percentage
				if(isNaN(p)){
					return;
				}
				p = Math.round( parseFloat(p) );
				if(p > 97){
					p = 97; // No sense to cue to 100 no?
				}
				if($.qtPlayerObj.isSoundApi === true){
					$.qtWebApiPlayer.seek(p);
				} else {
					$.qtSMPO.smSeek(p);
				}
			},
			seekTime: function(t){
				// if(t === '00:00'){
				// 	t = '00:00:00';
				// }
				// if($.qtPlayerObj.isSoundApi === true){
				// 	$.qtWebApiPlayer.seekTime(t);
				// } else {
				// 	$.qtSMPO.smSeekTime(t);
				// }
			},
			setVolume: function(v){
				if($.qtPlayerObj.isSoundApi === true){
					$.qtWebApiPlayer.setvolume(v);
				} else {
					$.qtSMPO.sm.setVolume(v * 100);
				}
			}
		},


		/**
		 * ================================================================
		 * 
		 * [interface functions controlling interaction and visual feedback]
		 * @type {Object}
		 *
		 * ================================================================ 
		 */
		interface: {
			window: $(window),
			body: $("body"),
			htmlAndbody: $('html,body'),
			player: $('#qtmusicplayer'),
			controls: $('#qtmusicplayer-controls'),
			qtmusicplayer: $('#qtmusicplayer-playlistcontainer'),
			playlist: $("#qtmusicplayer-playlist ul"),
			grooveadv:  $('#qtMplayerTadv'), // music cue
			buffer:  $('#qtMplayerBuffer'), // buffer
			progWave:  $('#qtMplayerprogWave'), // buffer
			advance: $("#qtMplayerTadv"),
			btnPlay: $("#qtmusicplayerPlay"),
			control: $('#qtmusicplayerTrackControl'),
			minicue: $("#qtMplayerMiniCue"),
			time: $("#qtmusicplayerTime"),
			autoplay: $('#qtmusicplayer').data('autoplay'),
			isMobile: function(){
				return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || $.qtWebsiteObj.window.width() < 1170 ;
			},
			doSpinner: function(state){
				var notif = $('#qtmplayerNotif');
				notif.html("");
				if( true === state ){ 
					notif.addClass("active qtmp-spinner"); 
				} else {
					notif.removeClass("active").removeClass("qtmp-spinner"); 
				}
			},
			preloadTrack: function(){
				var p = $.qtPlayerObj,
					i = p.interface;
				i.log('preloadTrack A');
				p.interface.doSpinner(true);
				i.playlist.find("li:first-child .qtmusicplayer-play-btn").each(function(i,c){
					var trk = $(c),
						q = 'qtmplayer-';
					p.songdata = {
						type: 		trk.data(q+"type"),
						cover: 		trk.data(q+"cover"),
						cover: 		trk.data(q+"cover"),
						file: 		trk.data(q+"file"),
						title: 		trk.data(q+"title"),
						artist: 	trk.data(q+"artist"),
						album: 		trk.data(q+"album"),
						link: 		trk.data(q+"link"),
						buylink: 	trk.data(q+"buylink"),
						icon: 		trk.data(q+"icon"),
					};
					trk.closest(".qtmusicplayer-trackitem").addClass("qtmusicplayer-played");
					var c = $.qtPlayerObj.interface.controls,
						ot = false;
					if(qtShowPlayer){
						p.interface.showhide();
					}

				
					if('radio' === p.songdata.type && 'object' === typeof($.qtKentharadioObj)){
						$.qtKentharadioObj.qtFeedData = {
							host: trk.attr("data-host"),
							port:  trk.attr("data-port"),
							channel:  trk.attr("data-channel"),
							ssl:  trk.attr("data-ssl"),
							icecast:  trk.attr("data-icecasturl"),
							icecast_mount:  trk.attr("data-icecastmountpoint"),
							radiodotco:  trk.attr("data-radiodotco"),
							airtime:  trk.attr("data-airtime"),
							radionomy:  trk.attr("data-radionomy"),
							textfeed: trk.attr("data-textfeed")
						};
						if( 'function' === typeof( $.qtKentharadioObj.fn.radioSong ) ){
							$.qtKentharadioObj.fn.radioSong();
						}
					}

					if(p.interface.deployTrack()){

						p.interface.log('preloadTrack B');
						// Autoplay:If google allows
						// remove spinner
						p.interface.doSpinner(true);
						// setTimeout(
						// 	p.interface.doSpinner, 
						// 	1000
						// );
						if(p.interface.autoplay){
							p.interface.log('preloadTrack C');
							setTimeout(
								p.uniPlayer.play, 
								1000
							);
						}
					}
				});
			},


			deployTrack: function(autoplay){
				var o = $.qtPlayerObj,
					i = o.interface,
					hd = i.controls,
					dt = o.songdata,
					mp = i.qtmusicplayer,
					cartlink,
					cur_url = window.location.href,
					wc_params = '',
					wc_classes = '',
					params, // for URL
					params_str; // for URL
				
				if(dt.file == ''){
					return;
				}
				i.doSpinner(true);


				if(false == $.qtInitialized){
					setTimeout(
						i.doSpinner, 
						2200
					);
				}


				i.log('deployTrack A');
				$.qtMplayerWaveform( dt.file );

				hd.find('.qt-mplayer__title').html('<strong>'+dt.title+'</strong> ');
				hd.find('.qt-mplayer__artist').text(dt.artist);
				if(dt.album !== ''){
					hd.find('.qt-mplayer__title').append('['+dt.album+']');
				}
				hd.find('.qt-mplayer__cover').attr("href", dt.link);
				// WooCommerce support added
				if(dt.buylink !== ''){
					// WooCommerce
					cartlink = dt.buylink;
					dt.buylink = dt.buylink.toString();
					if (dt.buylink.match(/^-?\d+$/)) { // is a numeric ID
						
						params = { "add-to-cart":dt.buylink };
						params_str = jQuery.param( params );
						if(cur_url.indexOf('?') != -1) {
							cartlink = cur_url+"&"+params_str;
						}else{
							cartlink = cur_url+"?"+params_str;
						}
						// Extra cart classes and attrs
						wc_classes = ' product_type_simple add_to_cart_button ajax_add_to_cart ';

						hd.find('.qt-mplayer__cart').attr("href", cartlink).attr('data-quantity','1').attr('data-product_id', dt.buylink).addClass(wc_classes).show();
					} else {
						hd.find('.qt-mplayer__cart').attr("href", dt.buylink).removeClass('product_type_simple').removeClass('add_to_cart_button').removeClass('ajax_add_to_cart').show();

					}
				} else {
					hd.find('.qt-mplayer__cart').hide().removeClass('product_type_simple').removeClass('add_to_cart_button').removeClass('ajax_add_to_cart');
				}

				hd.find('.qt-mplayer__cart i').html(dt.icon);
				i.advance.width(0);
				i.buffer.width(0);
				if(dt.cover !== ''){
					mp.find('.qt-mplayer__album img').attr("src", dt.cover).show();
					hd.find('.qt-mplayer__cover img').attr("src", dt.cover).show();
				} else {
					mp.find('.qt-mplayer__album img').hide();
					hd.find('.qt-mplayer__cover img').hide();
				}
				mp.find('.qt-albumlink').attr("href",dt.link);
				if(qtShowPlayer){
					i.showhide();
				}
				i.log('deployTrack B');
				i.btnPlayClick();
				i.playTrack();
				if(autoplay){
					o.uniPlayer.play();
				}
				return true;
			},
			
			playTrack: function(){
				var p = $.qtPlayerObj,
					i = p.interface,
					u = p.uniPlayer;
				i.body.off("click", ".qtmusicplayer-play-btn");
				i.body.on("click", ".qtmusicplayer-play-btn", function(e){
					e.preventDefault();		
					i.log("playTrack A");
					qtPlayIsAllowed = true;
					i.doSpinner(true);
					var tr = $(this),
						item = tr.closest(".qtmusicplayer-trackitem"),
						isDonut = item.hasClass("qt-donut"),
						icon = tr.find("i"),
						clickedsong = tr.attr('data-qtmplayer-file'),
						playedclass = "qtmusicplayer-played",
						playedtrack = i.body.find("."+playedclass),
						iplay =  "dripicons-media-play",
						ipause = "dripicons-media-pause";

					if(item.hasClass(playedclass)){
						if(  tr.find('i').html() === 'pause_circle_filled' ){
							i.switchicon(icon, 'play');
							u.pause();
							e.stopPropagation();
							return;
						} else {
							item.addClass(playedclass);
							i.switchicon(icon, 'pause');
							u.play();
							e.stopPropagation();
							return;
						}
						return;
					} else {

						// 1. Removed any played attribute for any previously played track
						if(playedtrack.length > 0){
							i.body.find(".qtmusicplayer-played").find('i').html('play_circle_filled');
							playedtrack.removeClass(playedclass);
							i.switchicon(icon, 'play');
							i.justStop();
							u.pause();
							// e.stopPropagation();
						}

						// Make sure to stop any possibly actually playing track
						u.pause();
						i.justStop();

						// 2. Play the new track
						if( undefined === tr.data("qtmplayer-type") ){
							tr.data("qtmplayer-type", 'track');
						}
						p.songdata = {
							type: tr.data("qtmplayer-type"),
							cover: tr.data("qtmplayer-cover"),
							file: tr.data("qtmplayer-file"),
							title: tr.data("qtmplayer-title"),
							artist: tr.data("qtmplayer-artist"),
							album: tr.data("qtmplayer-album"),
							link: tr.data("qtmplayer-link"),
							buylink: tr.data("qtmplayer-buylink"),
							icon: tr.data("qtmplayer-icon"),
						};
						i.seekBtn();
						i.switchicon(icon, 'pause');
						item.addClass(playedclass);
						if($("#qtdonut").length > 0){
							$("#qtdonut").removeAttr("id");
						}
						if(isDonut){
							item.find("a").closest('.qt-donut').attr("id", "qtdonut");
							$.qtMplayerPlaylistCue.destroy();
							$.qtRaphaelCircle.init();
						} else {
							if( 'track' === p.songdata.type){
								$.qtMplayerPlaylistCue.init();
							}
						}
						i.deployTrack();

						// safe initialization
						if(false == $.qtInitialized){
							i.log('Qua'),
							i.initializeAudio();
							i.log("playTrack C");
							i.doSpinner(true);
							setTimeout(
								function(){
									u.play();
								}, 
								1000
							);
						} else {
							i.log("playTrack C");
							u.play();
						}

						// u.play();
					}
					e.stopPropagation();
				});
			},
			
			switchicon: function(i, state) {
				if(state === 'play'){
					i.html('play_circle_filled');
				} else if (state === 'pause') {
					i.html('pause_circle_filled');
				}
			},
			progressUpdate: function(perc){ // buffered
				var i = $.qtPlayerObj.interface;
				i.buffer.css({width: (perc * 100)+'%'});
				i.log('========= progressUpdate =============');
				i.log(perc);
				if(perc == 0 && qtHaveProblem == 0){
					qtHaveProblem += 1;
				}
				i.log('Have problems??  '+qtHaveProblem);
			},
			timeupdate: function(perc, time){
				var i = $.qtPlayerObj.interface,
					p = perc * 100;
				i.advance.css({width: (p)+'%'});
				i.time.html(time);
				i.doSpinner();
				if($('#qtMplayerprogWave')){
					$('#qtMplayerprogWave').css({width: (p)+'%'});
				}
			},
			seekBtn: function(){
				var o = $.qtPlayerObj,
					i = o.interface,
					c = i.control,
					m = i.minicue,
					ol = c.offset().left,
					w = c.outerWidth(),
					t = (o.songdata.type == 'radio') ? 'radio' : 'track',
					l;
				c.off("mousemove").off("click");
				if(t === 'radio') {
					m.css({'left': 0});
				} else {
					c.on("mousemove", function(e){
						ol = c.offset().left;
						w = c.outerWidth();
						l = e.clientX - ol;
						m.css({'left': l});
					}).on("click", function(e){
						l = e.clientX - ol;
						o.uniPlayer.seek(l / w * 100);
					});
				}
			},	
			appendAlbum: function(){
				var p = $.qtPlayerObj,
					i = p.interface,
					c = i.controls,
					cartlink,
					cur_url = window.location.href,
					wc_params = '',
					wc_classes = '',
					params, // for URL
					params_str, // for URL
					ot = false, // timeout
					notif = $('#qtmplayerNotif');
				i.body.on("click", "[data-kenthaplayer-addrelease]", function(e){
					e.preventDefault();
					var that = $(this),
						url = that.data("kenthaplayer-addrelease"),
						playnow = that.data("playnow"),
						latestAdded = 'qt-latestadded';
					if(that.data("kenthaplayer-addrelease") === '0'){
						return;
					}
					$.getJSON(url, function( data ) {
						var newitem,
							special_action,
							tn = data.length;
						$.each( data, function( key, val ) {
							// WooCommerce
							
							cartlink = val.buylink;
							if (val.buylink.match(/^-?\d+$/)) { // is a numeric ID
								params = { "add-to-cart":val.buylink };
								params_str = jQuery.param( params );
								if( cur_url) {
									if( cur_url.indexOf("?")>= 0 ) {
										cartlink = cur_url+"&"+params_str;
									}else{
										cartlink = cur_url+"?"+params_str;
									}
								}
								// Extra cart classes and attrs
								wc_classes = ' product_type_simple add_to_cart_button ajax_add_to_cart ';
								wc_params = ' data-quantity="1" data-product_id="'+ val.buylink +'" ';
							}

							special_action = '<i class="material-icons">'+val.icon+'</i>';
							if( typeof(val.price) !== 'undefined'){
								if (val.price !== ''){
									special_action = '<span class="qt-price qt-btn qt-btn-xs qt-btn-primary">'+val.price+'</span>';
								}
							}
							newitem = '<li class="qtmusicplayer-trackitem dynamic"><img src="'+val.cover+'"><span class="qt-play qt-link-sec qtmusicplayer-play-btn '+latestAdded+'" data-qtmplayer-type="track" data-qtmplayer-cover="'+val.cover+'" data-qtmplayer-price="'+val.price+'" data-qtmplayer-file="'+val.file+'" data-qtmplayer-title="'+val.title+'"'+'data-qtmplayer-artist="'+val.artist+'"'+'data-qtmplayer-album="'+val.album+'" data-qtmplayer-link="'+val.link+'" data-qtmplayer-buylink="'+val.buylink+'" data-qtmplayer-icon="'+val.icon+'"><i class="material-icons">play_circle_filled</i></span><p>	<span class="qt-tit">'+(key+1)+'. '+val.title+'</span><br>	<span class="qt-art">'+val.artist+'</span></p><a href="'+cartlink+'" '+wc_params+' class="qt-cart '+ wc_classes +'" target="_blank">'+special_action+'</a><i class="qtmusicplayer-del qt-btn-secondary material-icons">clear</i></li>';
							i.playlist.append(newitem);
							if(0 === key && playnow){
								$.qtPlayerObj.interface.justStop();
								$.qtPlayerObj.uniPlayer.pause();
								p.songdata = val;
								$("."+latestAdded).click();
							}
							latestAdded = '';
						});
						i.showhide();
						if(that.data("clickonce") === 1){
							that.hide();
							$(that.data("notificate")).addClass("active");
						} 
						notif.html("+"+tn).addClass("active").delay(1500).promise().done(function(){
							notif.removeClass("active");
						});
					});
				});
			},
			removetrack: function(){
				$.qtPlayerObj.interface.playlist.on('click','.qtmusicplayer-del', function(e){
					e.preventDefault;
					var li = $(this).closest('li');
					li.addClass('qt-deleted').delay(202).promise().done(function(){
						li.remove();
					});
				});

			},
			showhide: function(){
				var c = $.qtPlayerObj.interface.controls;
				c.addClass('open');
				ot = setTimeout(function() {
					c.removeClass('open');
					clearTimeout(ot);
				}, 6000);
			},
			prevNext: function(){
				$.qtPlayerObj.interface.controls.on("click",".qt-mplayer__prev, .qt-mplayer__next", function(e){
					e.preventDefault();
					var t = $(this), b;
					$.qtPlayerObj.interface.doSpinner(true);

					if(t.data("control") === "prev"){
						b = $(".qtmusicplayer-played").prev();
					} else {
						b = $(".qtmusicplayer-played").next();
					}
					b.find(".qtmusicplayer-play-btn").click();
				});
			},
			next: function(){
				var i = $.qtPlayerObj.interface,
					nt = $(".qtmusicplayer-played").next();
				if(nt !== undefined){
					if(nt.length > 0){
						nt.find(".qtmusicplayer-play-btn").click();
					} else {
						i.justStop();
					}
				} else {
					i.justStop();
				}
			},			
			justStop: function(){
				$.qtPlayerObj.interface.switchicon($(".qtmusicplayer-played .qtmusicplayer-play-btn i"), 'play');
				$.qtPlayerObj.uniPlayer.btnPlay.find("i").html("play_arrow");
			},
			// skipCue: function(){
			// 	var o = $.qtPlayerObj,
			// 		i = o.interface;
			// 	i.body.on('click', '[data-qtplayercue]',function(){
			// 		i.log('data-qtplayercue');
			// 		var t = $(this),
			// 			k = t.data('qttrackurl'),
			// 			c = t.data('qtplayercue');
			// 		if(o.songdata.file === k) {
			// 			o.uniPlayer.seekTime(c);
			// 		}
			// 	});
			// },
			volBtn: function(){
				var v = $("#qtmusicplayerVol"),
					c = $("#qtmpvc"), // cue
					f = $("#qtmpvf"), // fill
					i = v.find('i'),
					off = v.offset().top,
					h =  v.height(),
					t, // top
					p, // percentage
					d; // delta
				v.on("mousemove", function(e){
					off = v.offset().top - $(window).scrollTop();
					t = e.clientY - off ;
					c.css({'top': t});
				});
				v.on("click", function(e){
					off = v.offset().top - $(window).scrollTop() + h;
					d = off - e.clientY;
					if(d > 50){
						d = 60;
						i.html('volume_up');
					} else if(d < 10){
						d = 0;
						i.html('volume_off');
					} else {
						i.html('volume_down');
					}
					f.height( d );
					p = d / h;
					$.qtPlayerObj.uniPlayer.setVolume(p);
				});
			},
			setDuration: function(text){
				if(text === 'NaN:NaN' || text === '00:00'){
					$("#qtmusicplayerDuration").html();
					return;
				}
				$("#qtmusicplayerDuration").html(text);
			},
			bufferStart: function(){
				$("#qtmusicplayerDuration").html('...');
				$("#qtmusicplayer-buffer").show();
			},
			bufferEnd: function(){
				$("#qtmusicplayer-buffer").hide();
			},
			screenResize: function(){
				var resizeTimer,
					o = $.qtPlayerObj,
					i = o.interface,
					w = i.window,
					ww = w.width(),
					wh = w.height();
				w.on('resize', function() {
					clearTimeout(resizeTimer);
					resizeTimer = setTimeout(function() {
						if (w.width() !== ww || w.height() !== wh) {
							i.seekBtn();
							$.qtMplayerPlaylistCue.init();
						}
						
					}, 100);
				});
			},
			initializeAudio: function() {
				if(true === $.qtInitialized){
					return;
				}
				var o = $.qtPlayerObj,
				i = o.interface;
				i.doSpinner(true);

				i.log("initializeAudio A");
				if(qtAnalyzer){
					var hasAudioContext = false;
					
					try {
						hasAudioContext = window.AudioContext || window.webkitAudioContext;
					} catch(e) {
						if($.qtSMPO.init()){
							$.qtInitialized = true;
							// setTimeout(
							// 	i.doSpinner, 
							// 	2200
							// );
							return true;
						};
					}
					if(hasAudioContext !== false){
						o.isSoundApi = true;
						$.qtInitialized = true;
						if($.qtWebApiPlayer.init()){
							// setTimeout(
							// 	i.doSpinner, 
							// 	1000
							// );
							
							return true;
						}
					}
				} else {
					i.log("initializeAudio B");
					if($.qtSMPO.init()){
						i.log("initializeAudio C");
						setTimeout(
							i.doSpinner, 
							1000
						);

						$.qtInitialized = true;
						return true;
					};
					i.log("initializeAudio D");
				}
			},
			resumeAudio: function(){
				// this seems to break the player by creating sometimes a parallel audio instance
				// return;

				var o = $.qtPlayerObj,
					i = o.interface;
				i.log("resumeAudio A");
				i.initializeAudio(); // Appply new fixes
				qtPlayIsAllowed = true;
				if(i.autoplay){
					i.log("resumeAudio B");
					setTimeout(
						function(){ 
							i.btnPlay.click(); 
							i.log("resumeAudio A1");
							setTimeout(
								function(){ 
									i.log("resumeAudio AB");
									if(false === i.isMobile()){
										i.log("resumeAudio AB 0");
									} else {
										i.btnPlay.click();
										i.log("resumeAudio AB 1");
									}
								},
								10
							);
						},
						2200
					);					
				}
				i.log("resumeAudio C");
				document.removeEventListener("click", i.resumeAudio);
			

			},
			
			triucco: function(){
				var b = $('body'),
					i = $.qtPlayerObj.interface,
					t; 
				t = $('#qtmPlayerMobenable');
				t.on('click',function(e){
					e.preventDefault();
					i.initializeAudio(); 
					i.resumeAudio();
					if(i.autoplay){
						i.btnPlay.click();
					}
					t.animate({"left":"1000px"}, 0);
					b.addClass("qt-mplayer-enabled");
					i.log('mobile player enabled');
					t.remove();
				});
				
			},
			log: function(m){
				var c = $("#qtmPlayerDebugger");
				if(c.length > 0){
					c.append(m+'<br>');
				}
			},

			/**
			 * ==================================================================================================
			 * Manage the main Play button
			 * ==================================================================================================
			 */
			btnPlayClick: function(){
				var state,
					o = $.qtPlayerObj,
					i = o.interface,
					b = i.btnPlay,
					p = o.uniPlayer;

				b.off("click");
				var state = b.find("i.material-icons").html();
				i.log(state);
				b.on("click", function(e){
					e.preventDefault();
					state = b.find("i.material-icons").html();
					i.log(state);
					i.log( o.songdata );
					if(state === 'pause'){
						p.pause();
					} else {
						i.log( o.songdata );
						// p.play();
						if(false == $.qtInitialized){
							i.initializeAudio();
							qtPlayIsAllowed = true;
							i.doSpinner(true);
							setTimeout(
								function(){
									p.play();
								}, 
								2200
							);
						} else {
							p.play();
						}
					}
				});
				return;
			},
		},
		initPlayer: function(){
			if(qtPlayDebug === true){
				$('body').append('<div class="qt-mplayer__debugger" id="qtmPlayerDebugger"><h5>Player Debug</h5></div>');
			}
			var o = $.qtPlayerObj,
				i = o.interface,
				c = i.controls,
				b = i.body,
				ot; // ot = outTimer
			o.songdata = {};
			
			b.on("click", "[data-playlistopen]", function(){
				b.toggleClass("qt-mplayer-active");
			});
			c.find('.qt-mplayer__cover').html('<img src="">');
			i.qtmusicplayer.find('.qt-mplayer__album').prepend('<img src="">');
			
			// 2020 sep 04 resume triucco for ios 13
			if( qtMplayerisMobile ){
				i.log('Is iPhone!['+qtMplayerisMobile+']');
				i.triucco();
			} 	else {
				b.addClass("qt-mplayer-enabled");
			}


			i.preloadTrack();
			i.prevNext();
			i.appendAlbum();
			i.seekBtn();
			i.volBtn();
			i.bufferEnd();
			// i.skipCue();
			i.screenResize();
			i.removetrack();
			c.mouseenter(function(){
				c.addClass('open');
				i.seekBtn();
				clearTimeout(ot);
			}).mouseleave(function(){				
				ot = setTimeout(function() {
					c.removeClass('open');
				}, c.data('hidetimeout'));
			});
			i.log("initPlayer A");

		},
	};
	$(document).ready(function() {
		if(0 === $('#qtmusicplayer-playlist li').length ){
			return;
		}
		$.qtPlayerObj.initPlayer();
	});
})(jQuery);




