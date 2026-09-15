/**====================================================================
 *
 *  Main Script File
 *
 *====================================================================*/

/**
 * These are the files required for the main script to run.
 * They are already imported in the minified version qt-main-min.js
 * If you enable Debug option in customizer, the unminified separated version
 * will be included instead, and you can modify this current js file for your own customizations
 */

// IMPORTANT: THE FOLLOWING IS NOT A COMMENT! IT IS JAVASCIPT IMPORTING! *** DO NOT DELETE ***
// ===========================================================================================
// @codekit-prepend "../components/materialize-src/js/initial.js"
// @codekit-prepend "../components/materialize-src/js/global.js"
// @codekit-prepend "../components/materialize-src/js/velocity.min.js"
// @codekit-prepend "../components/materialize-src/js/animation.js"
// @codekit-prepend "../components/materialize-src/js/sideNav.js"
// @codekit-prepend "../components/materialize-src/js/hammer.min.js"
// @codekit-prepend "../components/materialize-src/js/jquery.hammer.js"
// @codekit-prepend "../components/materialize-src/js/collapsible.js"
// @codekit-prepend "../components/materialize-src/js/jquery.easing.1.3.js"
// @codekit-prepend "../components/materialize-src/js/tabs.js"
// @codekit-prepend "../components/materialize-src/js/forms.js"
// @codekit-prepend "../components/materialize-src/js/slider.js"
// @codekit-prepend "../components/materialize-src/js/dropdown.js"
// @codekit-prepend "../components/slick/slick.min.js"
// @codekit-prepend "../components/raphael/raphael.min.js"
// @codekit-prepend "../components/popup/popup.js";
// @codekit-prepend "../components/ytbg/src/min/jquery.youtubebackground-min.js"


(function($) {
	"use strict";
	var qtDebugEnabled = 0, // set to 1 to enable console logging
	qtDebug = function(msg){
		if(qtDebugEnabled && console){
			if(typeof(console.log) === 'function'){
				console.log(msg);
			}
		}
	};
	qtDebug('Qt Main Loaded');
	$.qtWebsiteObj = {
		body: $("body"),
		window: $(window),
		document: $(document),
		htmlAndbody: $('html,body'),
		highQualityScroll: $("body").hasClass("qt-hq-parallax") , // true, // if true, in visual composer will use default parallax function
		
		/**
		 * ======================================================================================================================================== |
		 * 																																			|
		 * 																																			|
		 * START SITE FUNCTIONS 																													|
		 * 																																			|
		 *																																			|
		 * ======================================================================================================================================== |
		 */
		fn: {
			isExplorer: function(){
				return /Trident/i.test(navigator.userAgent) ;
			},
			isSafari: function(){
				return /Safari/i.test(navigator.userAgent) ;
			},
			isMobile: function(){
				return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || $.qtWebsiteObj.window.width() < 1170 ;
			},
			/**====================================================================
			 *
			 *
			 * Automatic link embed
			 *
			 * 
			 ====================================================================*/
			embedVideo: function (content, width, height) {
				height = width / 16 * 9;
				var youtubeUrl = content;
				var youtubeId = youtubeUrl.match(/=[\w-]{11}/);
				var strId = youtubeId[0].replace(/=/, '');
				var result = '<iframe width="'+width+'" height="'+height+'" src="'+window.location.protocol+'//www.youtube.com/embed/' + strId + '?html5=1" class="youtube-player" allowfullscreen></iframe>';
				return result;
			},
			
			/**====================================================================
			 *
			 * 
			 *	Smooth scrolling
			 *	
			 * 
			 ====================================================================*/
			smoothScr: function(){
				var topscroll;
				$.qtWebsiteObj.body.off("click",'a.qt-smoothscroll');
				$.qtWebsiteObj.body.off("click",'li.smoothscroll a');
				$.qtWebsiteObj.body.on("click",'a.qt-smoothscroll, li.smoothscroll a', function(e){     
					e.preventDefault();
					topscroll = $(this.hash).offset().top;
					$('html,body').animate({scrollTop:topscroll}, 600);
					e.stopPropagation();
				});
			},

			/**====================================================================
			 *
			 *
			 *	 Responsive video resize
			 *
			 * 
			 ====================================================================*/
			YTreszr: function  (){
				jQuery("iframe").each(function(i,c){ // .youtube-player
					var t = jQuery(this);
					if(t.attr("src")){
						var href = t.attr("src");
						if(href.match("youtube.com") || href.match("vimeo.com") || href.match("vevo.com")  ){
							var width = t.parent().width(),
								height = t.height();
							t.css({"width":width});
							t.height(width/16*9);
						}
						else if(href.match("soundcloud.com")){
							var width = t.parent().width();
							t.css({"width":width});
						}; 
					};
				});
			},

			/**====================================================================
			 *
			 *
			 * 	Check images loaded in a container
			 *
			 * 
			 ====================================================================*/
			imagesLoaded: function () {
				var $imgs = this.find('img[src!=""]');
				if (!$imgs.length) {return $.Deferred().resolve().promise();}
				var dfds = [];  
				$imgs.each(function(){
					var dfd = $.Deferred();
					dfds.push(dfd);
					var img = new Image();
					img.onload = function(){dfd.resolve();}
					img.onerror = function(){dfd.resolve();}
					img.src = this.src;
				});
				// return a master promise object which will resolve when all the deferred objects have resolved
				// IE - when all the images are loaded
				return $.when.apply($,dfds);
			},

			/**====================================================================
			 *
			 *
			 * Transform link in embedded players
			 *
			 * 
			 ====================================================================*/
			 // remove player
			transformlinksReverse: function(targetContainer){
				jQuery(targetContainer).find('[data-autoembed]').html("");
			},

			transformlinks: function (targetContainer, differ) {
				if(undefined === targetContainer) {
					targetContainer = "body";
				}

				var obj = $.qtWebsiteObj;
				jQuery(targetContainer).find("a[href*='youtube.com'],a[href*='youtu.be'],a[href*='mixcloud.com'],a[href*='soundcloud.com'], [data-autoembed]").not('.qw-disableembedding').not('.qt-disableembedding').each(function(element) {
					
					var that = jQuery(this),
						mystring = that.attr('href'),
						width = that.parent().width(),
						height = that.height(),
						element = that,
						fixedheight = that.data('fixedheight');

					if(differ === false && that.hasClass('qt-differembed')){
						return;
					}
					if(width === 0){
						width = that.parent().parent().parent();
					}
					if(width === 0){
						width = that.parent().parent().parent().width();
					}
					if(width === 0){
						width = that.parent().parent().parent().parent().width();
					}
					if(that.attr('data-autoembed')) {
						mystring = that.attr('data-autoembed');
					}
					//=== YOUTUBE https
					var expression = /(http|https):\/\/(\w{0,3}\.)?youtube\.\w{2,3}\/watch\?v=[\w-]{11}/gi,
						videoUrl = mystring.match(expression);
					if (videoUrl !== null) {
						for (var count = 0; count < videoUrl.length; count++) {
							mystring = mystring.replace(videoUrl[count], $.qtWebsiteObj.fn.embedVideo(videoUrl[count], width, (width/16*9)));
							replacethisHtml(mystring);
						}
					}               
					//=== SOUNDCLOUD
					var temphtml = '',
						iframeUrl = '',
						$temphtml,
						expression = /(http|https)(\:\/\/soundcloud.com\/+([a-zA-Z0-9\/\-_]*))/g,
						scUrl = mystring.match(expression);
					if (scUrl !== null) {
						for (count = 0; count < scUrl.length; count++) {
							var finalurl = scUrl[count].replace(':', '%3A');
							if(!fixedheight){
								fixedheight = 180;
							}
							jQuery.getJSON(
								'https://soundcloud.com/oembed?maxheight='+fixedheight+'&format=js&url=' + finalurl + '&iframe=true&callback=?'
								, function(response) {
									temphtml = response.html;
									if(that.closest("li").length > 0){
										if(that.closest("li").hasClass("qt-collapsible-item") ) {
											$temphtml = $(temphtml);
											iframeUrl = $temphtml.attr("src");
											replacethisHtml('<div class="qt-dynamic-iframe" data-src="'+iframeUrl+'"></div>');
										} else {
											replacethisHtml(temphtml);
										}
									} else {
										replacethisHtml(temphtml);
									}
							});
						}
					}
					//=== MIXCLOUD
					var expression = /(http|https)\:\/\/www\.mixcloud\.com\/[\w-]{0,150}\/[\w-]{0,150}\/[\w-]{0,1}/ig;
					var mixcloudUrl = mystring.match(expression);
					if (mixcloudUrl !== null) {
					
						for (count = 0; count < mixcloudUrl.length; count++) {

							var finalurl = encodeURIComponent(mixcloudUrl[count]);
							// finalurl = finalurl.replace("https","http");
							var embedcode ='<iframe data-state="0" class="mixcloudplayer" width="100%" height="160" src="//www.mixcloud.com/widget/iframe/?feed='+finalurl+'&embed_uuid=addfd1ba-1531-4f6e-9977-6ca2bd308dcc&stylecolor=&embed_type=widget_standard"></iframe><div class="canc"></div>';    
							replacethisHtml(embedcode);
						}
					}
					//=== STRING REPLACE (FINAL FUNCTION)
					function replacethisHtml(mystring) {
						if(element.is("a")){
							element.replaceWith(mystring);
						} else {
							element.html(mystring);
						}
						return true;
					}
					obj.fn.YTreszr();
				});
				
				/**
				 * Fix for soundcloud loaded in collapsed div for the chart
				 */
				obj.body.off('click','.qt-collapsible li');
				obj.body.on('click','.qt-collapsible li', function(e){
					var that = $(this);
					if(that.hasClass("active")){
						var item = that.find(".qt-dynamic-iframe");
						var itemurl = item.attr("data-src");
						item.replaceWith('<iframe src="'+itemurl+'" frameborder="0"></iframe>');
						obj.fn.YTreszr();
					}
				});
				obj.body.off('click','ul.tabs li a');
				obj.body.on('click','ul.tabs li a', function(e){
					obj.fn.YTreszr();
					window.dispatchEvent(new Event('resize'));
				});
			},


			/* Mobile navigation
			====================================================================*/
			qtMobileNav: function() {
				$.qtWebsiteObj.body.find( ".qt-dropdown-menu li.menu-item-has-children").each(function(i,c){
					var that = $(c);
					that.append("<a class='qt-openthis'><i class='material-icons'>keyboard_arrow_down</i></a>");
					that.on("click","> .qt-openthis", function(e){
						e.preventDefault();
						that.toggleClass("open");
						return;
					});
					return;
				});
				return true;
			},

			/* Slick gallery
			====================================================================*/
			slickGallery: function() {
				$.qtWebsiteObj.slickSliders = $('.qt-slickslider, .qt-slick');
				if($.qtWebsiteObj.slickSliders.length === 0) {
					return;
				}
				$.qtWebsiteObj.slickSliders.not('.slick-initialized').each(function() {
					var that = $(this),
						slidesToShow = that.attr("data-slidestoshow"),
						slidestoshowMobile = that.attr("data-slidestoshowmobile"),
						slidestoshowIpad = that.attr("data-slidestoshowipad"),
						appendArrows = that.attr("data-appendArrows");

					if (slidesToShow === undefined || slidesToShow === "") {
						slidesToShow = 1;
					}
					if (slidestoshowMobile === undefined || slidestoshowMobile === "") {
						slidestoshowMobile = 1;
					}

					if (slidestoshowIpad === undefined || slidestoshowIpad === "") {
						slidestoshowIpad = 3;
					}
					if (appendArrows === undefined || appendArrows === "") {
						appendArrows = that; // append the arrows to the same container
					} else {
						appendArrows = that.closest(appendArrows); // or append arrows to other divs
					}
					///	IMPORTANT ABOUT THE SLICKSLIDER IN THIS TEMPLATE:
					///	WE ARE ADDING MANUALLY THE ARROWS, SO THE APPEND-ARROWS IS ALWAYS SET TO FALSE
					that.slick({
						// lazyLoad: 'progressive',
						slidesToScroll: 1,
						pauseOnHover: that.attr("data-pauseonhover") === "true",
						infinite: that.attr("data-infinite") === "true",
						autoplay: that.attr("data-autoplay") === "true",
						autoplaySpeed: 4000,
						centerPadding: 0,// that.attr("data-centerpadding") || 0,
						slide: ".qt-item",
						dots: that.attr("data-dots") === "true",
						variableWidth: that.attr("data-variablewidth") === "true",
						arrows: false,
						centerMode: false,//that.attr("data-centermode") === "true",
						slidesToShow: slidesToShow,
						appendArrows: false,
						responsive: [
							{
								breakpoint: 790,
								settings: {
									arrows: false,
									centerMode: that.attr("data-centermodemobile") === "true",
									centerPadding: 30,
									variableWidth: true,//that.attr("data-variablewidthmobile") === "true",
									variableHeight: false,
									dots: that.attr("data-dotsmobile") === "true",
									slidesToShow: slidestoshowMobile,
									draggable: false,
									swipe: true,
									touchMove: true,
									infinite: that.attr("data-infinitemobile") === "true",
								}
							}, {
								breakpoint: 1170,
								settings: {
									arrows: false,
									centerMode: true,
									dots: that.attr("data-dotsipad") === "true",
									variableWidth: that.attr("data-variablewidth") === "true",
									slidesToShow: slidestoshowIpad,
								}
							}
						]
					}).promise().done(function(){
						that.removeClass("qt-invisible");
					});
				});
				$.qtWebsiteObj.body.off("click","[data-slicknext]");
				$.qtWebsiteObj.body.on("click","[data-slicknext]", function(e){
					e.preventDefault();
					$(this).closest(".qt-slickslider-outercontainer").find('.qt-slickslider').slick("slickNext");
				});
				$.qtWebsiteObj.body.off("click","[data-slickprev]");
				$.qtWebsiteObj.body.on("click","[data-slickprev]", function(e){
					e.preventDefault();
					$(this).closest(".qt-slickslider-outercontainer").find('.qt-slickslider').slick("slickPrev");
				});
			},

			

			/* Parallax Backgrounds
			
			/**
			 * [qtParallaxV8 new high performance parallax]
			 */
			qtParallaxRuntime8: function(event){
				var data = event.data,
					items = data.itemsArray,
					ob = $.qtWebsiteObj,
					now = Date.now(),
					wH = data.wH;
				var T, scr = ob.window.scrollTop(), offset, height, yBgPos, ost, s;
			    if (now > ob.lastMove + 1) {
					ob.lastMove  = now;
					items.each(function(i,c){
						T = $(c),
						s = T.data('speed') / 10;
						ost = T.offset().top;
						if (ost + T.outerHeight() <= scr || ost >= scr + wH) {
							return;
						}
						yBgPos = Math.round((ost - scr) * s);
						T.css('background-position', 'center ' + yBgPos + 'px');
					});
				}
			},
			qtParallaxV8: function() {
				var eventThrottle = 1,
					ob = $.qtWebsiteObj,
					rt = ob.fn.qtParallaxRuntime8,
					s,
					items = $('[data-parallax="1"]');
				if(items.length === 0 || ob.highQualityScroll === false ){
					return;
				}
				items.each(function(i,c){
					var T = $(c);
					if( ob.fn.isMobile() || ob.window.width() < 1280 ) {
						T.css('background-attachment', 'local');
						return;
					} else {
						T.css('background-attachment', 'fixed');
						if(!$(c).data('speed')){
							$(c).data('speed',1.5);
						}
					}
				});
				var args = { itemsArray : items, wH: ob.window.height() };
				ob.lastMove = Date.now();
				ob.window.off('scroll', rt);
				ob.window.on('scroll', args, rt );
				$(window).scroll();
			},

			/* Parallax Backgrounds reinitialize
			====================================================================*/
			qtParallaxReinit: function(){
				$.qtWebsiteObj.fn.qtParallaxV8();
			},


			/* Dynamic backgrounds
			====================================================================*/
			dynamicBackgroundsV4: function(targetContainer) {
				if (undefined === targetContainer) {
					targetContainer = "body";
				}
				$(targetContainer + " [data-bgimage]").each(function() {
					var that = $(this),
						bg = that.attr("data-bgimage"),
						myspeed = 1.5;
					if (bg !== '') {
						that.css({"background-image": "url("+bg+")"}).addClass("qt-bgloaded");
						return;
					}
				});
			},

			/* Skrollr plugin initialization only for desktop
			====================================================================*/
			qtSkrollrInit: function(){
				if( $.qtWebsiteObj.fn.isMobile() ) {
					return;
				}
				$.qtWebsiteObj.skrollrInstance = skrollr.init({
					smoothScrolling: true,
					forceHeight: false
				});
			},

			/* activate class
			====================================================================*/
			qtActivates: function(){
				var t, // target
					o = $.qtWebsiteObj;
				o.body.off("click", "[data-activates]");
				o.body.on("click", "[data-activates]", function(e){
					e.preventDefault();
					t = $($(this).attr("data-activates"));
					t.toggleClass("active");
				});
			},

			/* 3D page FX
			====================================================================*/
			qt3DfxFunction: {
				status: 0,
				init: function(){
					var ob = $.qtWebsiteObj,
						T = $.qtWebsiteObj.fn.qt3DfxFunction,
						cont = $("#maincontent"),
						lb = $("#qtLayerBottom"),
						perspect = $("#qtMasterContainter"),
						bt = $('[data-3dfx]');
					T.status = 0;
					T.lb = lb;
					T.bt = bt;
					T.cont = cont;
					T.perspect = perspect;
					T.iexpl = ob.fn.isExplorer();
					bt.on("click", function(e){
						e.preventDefault();
						e.stopPropagation();
						if(0 === T.status || !T.status){
							T.open();
						} else {
							T.close();
						}
						return false;
					});
					// CLOSE OFFCANVAS WHEN SIDE NAV MENU IS OPEN
					$(".qt-menuswitch").on('click', function(e){ 
						$.qtWebsiteObj.fn.qt3DfxFunction.close();
						bt.removeClass('active');
					});
				},
				open: function(){
					var ob = $.qtWebsiteObj,
						T = ob.fn.qt3DfxFunction,
						lb = T.lb,
						bt = T.bt;
					T.status = 1;
					bt.addClass("active");
					T.cont.addClass("qt-3dfx");
					$(".button-collapse").sideNav('hide');
					if(!ob.fn.isMobile()){
						if(T.iexpl){
							// IE only
							T.cont.addClass("qt-3dfx-on-IE");
							lb.addClass("active");
							ob.body.addClass("qt-body-3dfx-on-IE");

						} else {
							ob.body.css({height: "100vh", 'overflow': 'hidden'}).addClass("qt-body-3dfx-on");
							T.perspect.addClass("qt-3dfx-enabled").css({perspective: '1500px',height: '100vh', "overflow-x":"hidden"}).promise().done(function(){
								T.cont.css({
									height: "100vh",
									transform: "scale(1)rotateY(0deg) translateY(0%)",
									top: "0%",
									"transform-origin": "18% 36%",
								}).promise().done(function(){
									try {
										T.cont.addClass("qt-3dfx-on");
									} catch(e){
									}
									T.cont.css({
										transform: "scale(0.4) rotateY(33deg)  translateY(30%)",
										top: "30%"
									});
									lb.addClass("active");
								});
							});
						}
					} else {
						T.cont.addClass("qt-3dfx-on");
						lb.addClass("active");
					}
				},
				close: function(){
					var ob = $.qtWebsiteObj,
						T = ob.fn.qt3DfxFunction,
						lb = T.lb,
						bt = T.bt;
					T.status = 0;
					bt.removeClass("active");
					if(!ob.fn.isMobile()){
						if(T.iexpl){
							// IE only
							T.cont.removeClass("qt-3dfx-on-IE");
							lb.removeClass("active");
							ob.body.removeClass("qt-body-3dfx-on-IE");
							ob.fn.qtParallaxReinit();
						} else {

							lb.removeClass("active");
							T.cont.css({
								transform: "scale(1) rotateY(0deg)  translateY(0%)",
								top: "0%"
							}).delay(300).promise().done(function(){
								T.perspect.css({perspective: 'none', height: 'auto', "overflow-x":"auto"}).promise().done(function(){
									T.cont.css({
										height: "initial",
										"transform-origin": "initial",
										transform: 'none'
									}).removeClass("qt-3dfx-on");
									T.cont.addClass("qt-3dfx");
									T.perspect.removeClass("qt-3dfx-enabled")
									ob.body.css({height: "auto", 'overflow': 'initial'}).removeClass("qt-body-3dfx-on").promise().done(function(){
										T.cont.removeClass("qt-3dfx");
										ob.fn.qtParallaxReinit();
										if( "undefined" !== typeof($.qtWebsiteObj.skrollrInstance)) {
											$.qtWebsiteObj.skrollrInstance.refresh();
										}
									});
								});
							});
						}

					} else {
						lb.removeClass("active");
						T.cont.removeClass("qt-3dfx-on");
						T.cont.addClass("qt-3dfx");
						ob.body.css({height: "auto", 'overflow': 'initial'}).removeClass("qt-body-3dfx-on").promise().done(function(){
							T.cont.removeClass("qt-3dfx");
							ob.fn.qtParallaxReinit();
						});
					}
				}
			},


							


			/* Card animation
			====================================================================*/
			animObj: false,
			animInterval: false,
			equalizerPath: function(heightsArr, cW, cH) {
				var path = "",
					x = 0,
					y = 0,
					startpoint = false,
					increment = Math.round(cW / (heightsArr.length - 1) );
				path += "M " + [-30,-3];
				heightsArr.forEach(function(item, index){
					y = Math.round(cH / 100 * item );
					x = index * increment;
					if(index == 0){
						x = -1;
						path += "L " + [x, y] + " S ";
						startpoint = [x, y];
					} else {
						path += [x, y]+' ,';
					}
				});
				path += "L " + (cW+1)+',-1';
				path += "L " + [0,0];
				return path;
			},
			doAnimationEq: function(points, timer, object, cw, ch, color){
				var mynewPath = $.qtWebsiteObj.fn.equalizerPath(points, cw, ch);
				var anim = Raphael.animation(
					{
						path: mynewPath
						, stroke: color
					}
					, timer, "<>"
				);
				object.animate (anim, {path: mynewPath + "L"+cw+","+ch+" 0,"+ch+"z", 
				fill: color, stroke: color}, timer, "<>");
			},
			cardAnimDestroy: function(){
				var fn = $.qtWebsiteObj.fn;
				if(fn.animObj !== false){
					fn.animObj.remove();
				}
				if(fn.animInterval !== false){
					clearInterval(fn.animInterval);
				}		
			},
			cardAnimation: function(){
				var fn = $.qtWebsiteObj.fn,
					cont = $(".qt-part-archive-item.qt-open .qt-animation");
				fn.cardAnimDestroy();
				if(cont.length <= 0){
					return;
				}
				cont.attr("id","qtCardAnimation");
				var that,card = $("#qtCardAnimation"),
					color = card.attr("data-color"),
					ch = card.height(),
					cw = card.width(),
					paper = Raphael(cont[0], "100%", "100%"),
					npoints = [];
				for (var i = 0; i < 9; i++) {
					npoints[i] = Math.floor( Math.random() * 60  + 20);
				}
				var origPath = fn.equalizerPath(npoints,cw, ch);
				fn.animObj = paper.path(origPath).attr({ fill: color, stroke: color});
				for (var i = 0; i < 9; i++) {
					npoints[i] = Math.floor((Math.random() * 60) + 20);
				}
				fn.doAnimationEq(npoints, 3000, fn.animObj, cw, ch);
				fn.animInterval = setInterval(
					function(){
						var npoints = [];
						for (var i = 0; i < 9; i++) {
							npoints[i] = Math.floor((Math.random() * 60) + 20);
						}
						fn.doAnimationEq(npoints, 3000, fn.animObj, cw, ch, color);
					}
					, 2300
				);
			},

			
			/* Video controller
			====================================================================*/
			qtVideoBg: function(){ 	
				if($.qtWebsiteObj.fn.isMobile()){
					return;
				}
				var videobg = jQuery('#qtvideobg');
				if(videobg.length == 1){
					var id = videobg.attr("data-id");
					videobg.YTPlayer({
						fitToBackground: true,
						videoId: id,
						mute: videobg.data("mute"),
						playerVars: {
						  modestbranding: 0,
						  autoplay: 1,
						  controls: 0,
						  showinfo: 0,
						  branding: 0,
						  rel: 0,
						  autohide: 0,
						  start: videobg.data("start"),
						  vq: 'large'
						},
						callback: function(){
							videobg.delay(1000).promise().done(function(){
								videobg.animate({opacity: 1}, 1500);
							});
						}
					});
				}
			},

			/* Shrinking header FX
			====================================================================*/
			pageheaderFx: function(){ 	
				$("#qt-pageheader").addClass("active");
			},

			/* Countdown
			====================================================================*/
			countDown: {
				cd: $(".qt-countdown"),
				cdf: this,
				pad: function(n) {
					return (n < 10) ? ("0" + n) : n;
				},
				showclock: function() {
					if($(".qt-countdown").length < 1){
						return;
					}
					if(!$(".qt-countdown").data('date') || !$(".qt-countdown").data('time')){
						return;
					}

					var days, hours, min,
						T = $.qtWebsiteObj.fn.countDown,
						cd = $(".qt-countdown"),
						cdf = T.cdf,
						html = '',
						curDate = new Date(),
						fieldDate = cd.data('date').split('-'),
						fieldTime = cd.data('time').split(':'),
						futureDate = new Date(fieldDate[0],fieldDate[1]-1,fieldDate[2], fieldTime[0], fieldTime[1]),
						sec = futureDate.getTime() / 1000 - curDate.getTime() / 1000;
					if(sec<=0 || isNaN(sec)){
						cd.hide();
						return cd;
					}
					days = Math.floor(sec/86400);
					sec = sec%86400;
					hours = Math.floor(sec/3600);
					sec = sec%3600;
					min = Math.floor(sec/60);
					sec = Math.floor(sec%60);
					if(days != 0){
						html += T.pad(days)+'<span>'+cd.data('days')+'</span> ';
					}
					html += T.pad(hours)+'<span>'+cd.data('hours')+'</span> ';
					html += T.pad(min)+'<span>'+cd.data('minutes')+'</span> ';
					html += T.pad(sec)+'<span>'+cd.data('seconds')+'</span>';
					cd.html(html);
				},
				remove: function(){
					var T = $.qtWebsiteObj.fn.countDown;
					if(T.qtClockInterval){
						clearInterval(T.qtClockInterval);
					}
				},
				init: function() {
					var T = $.qtWebsiteObj.fn.countDown;
					if($(".qt-countdown").length < 1){
						return;
					}
					T.showclock();
					T.qtClockInterval = setInterval(function(){
						T.showclock();	
					},1000);
				}
			},

			/* Masonry
			====================================================================*/
			masonry: function(){
				$('.qt-masonry').each( function(i,c){
					var T = $(c),
						idc = $(c).attr("id"),
						container = document.querySelector('#'+idc);
					if(container){
						T.imagesLoaded().then(function(){
							var msnry = new Masonry( container, {  itemSelector: '.qt-ms-item',   columnWidth: '.qt-ms-item' });
						});
					}
				});
				$('.gallery').each( function(i,c){
					var T = $(c),
						idc = $(c).attr("id"),
						container = document.querySelector('#'+idc);
					if(container){
						T.imagesLoaded().then(function(){
							var msnry = new Masonry( container, {  itemSelector: '.gallery-item',   columnWidth: '.gallery-item' });
						});
					}
				});
				return true;
			},

			/* Sharing
			====================================================================*/
			shareitem: function(){
				var ob = $.qtWebsiteObj,
					B = ob.body,
					sl = $('#qtSharelayer');
				B.off('click', '[data-shareitem]');
				B.on('click', '[data-shareitem]', function(e){
					e.preventDefault();
					var that = $(this),
						url = that.data('shareitem'),
						urlencoded = encodeURIComponent(url);
					$('[data-sharetype-facebook]').attr("href",'https://www.facebook.com/sharer/sharer.php?u='+urlencoded);
					$('[data-sharetype-twitter]').attr("href",'https://twitter.com/home?status='+urlencoded);
					$('[data-sharetype-google]').attr("href",'https://plus.google.com/share?url='+urlencoded);
					$('[data-sharetype-pinterest]').attr("href",'https://www.pinterest.es/pin/create/bookmarklet/?url='+urlencoded);
					sl.addClass("active");
				});
				B.off('click', '#qtSharelayer .qt-close, #qtSharelayer');
				B.on('click', '#qtSharelayer .qt-close, #qtSharelayer', function(e){
					sl.removeClass("active");
				});
			},
			
			/* Card activator
			====================================================================*/
			qtCardActivator: function(){
				var ob = $.qtWebsiteObj,
					B = ob.body,
					fn = ob.fn;
				B.off("click", "[data-activatecard]");
				B.on("click", "[data-activatecard]", function(e){
					e.preventDefault();
					var P = $(this).closest(".qt-interactivecard");
					fn.cardAnimDestroy();
					if(P.hasClass("qt-open")){
						P.removeClass("qt-open");
						fn.transformlinksReverse('#'+P.attr("id"));
					} else {
						fn.transformlinksReverse(".qt-interactivecard.qt-open");
						$(".qt-interactivecard.qt-open").removeClass("qt-open");
						P.addClass("qt-open");
						fn.transformlinks('#'+P.attr("id"), true);
						fn.cardAnimation();
					}
				});		
			},

			/* Loadmore
			====================================================================*/
			loadmore: {
				init : function(){
					var ob = $.qtWebsiteObj,
						body = ob.body,
						f = ob.fn,
						C = '#qtloop',
						L = '#qtloadmore',
						P = '#qtpagination',
						btn = $(L),
						i = btn.find('i'),
						link,
						list;
					i.hide();
					body.off('click','#qtloadmore');
					body.on('click','#qtloadmore', function(e){
						e.preventDefault();
						link = $(L).attr("href");
						i.show();
						$.ajax({
							url: link,
							success:function(data) {
								list = $(C, data);
								$(P).remove();
								$(C).append(list.html());
								$(L).find('i').hide();
								$(C).imagesLoaded().then(function(){
									f.masonry();
									f.YTreszr();
									f.dynamicBackgroundsV4(C);

									f.qtCardActivator();
								});					
							},
							error: function () {
								window.location.replace(link);
							}
						});
					});
				}
			},


			/* PERSPECTIVECARDS
			====================================================================*/
			perspCard: {
				init: function(){
					if($.qtWebsiteObj.fn.isMobile()){
						return;
					}
					$.qtWebsiteObj.fn.perspCard.mousemove();
				},
				generateTranslate: function generateTranslate(el, e, value) {
					el.css({"transform": "translate(" + e.clientX * value + "px, " + e.clientY * value + "px)"});
				},
				mousemove:function(){
					var o = $.qtWebsiteObj,
						pc = o.fn.perspCard,
						gt = pc.generateTranslate,
						cWra = o.body.find(".qt-perspectivecard-wrapper");
					cWra.each(function(i,c){
						var wr = $(c),
							card = wr.find(".qt-perspectivecard"), //document.querySelector(".qt-perspectivecard"),//wrapper.find('.qt-perspectivecard'),
							cover =  wr.find(".qt-perspectivecard__cover"),
							bg2 =  wr.find(".qt-perspectivecard__bg2"),
							bg3 =  wr.find(".qt-perspectivecard__bg3"),
							bg4 =  wr.find(".qt-perspectivecard__bg4"),
							fg1 =  wr.find(".qt-perspectivecard__fg1"),
							fg2 =  wr.find(".qt-perspectivecard__fg2"),
							btn =  wr.find("p"),
							ox = wr.offset().left,
							oy = wr.offset().top,
							x, y,
							w = wr.width(),
							h = wr.height(),
							w2 = w / 2,
							h2 = h / 2,
							mtx,
							ex, ey;
						var lastMove = 0;
						var eventThrottle = 2;
						var now = Date.now();
						wr.off('mousemove');
						wr.on('mousemove', function(e){
							now = Date.now();
							if (now > lastMove + eventThrottle) {
								lastMove = now;
								ex = e.pageX - w2;
								ey = e.pageY - h2;
								x = (ex - ox  / 2) * - 1 / 100;
								y = (ey - oy  / 2) * - 1 / 100;

								mtx = [[1, 0, 0, -x * 0.00003], [0, 1, 0, -y * 0.00003], [0, 0, 1, 1], [0, 0, 0, 1]];
								gt(bg2, e, -0.04);
								gt(bg3, e, -0.03);
								gt(bg4, e, -0.02);
								gt(cover, e, 0.0);
								 gt(fg1, e, 0.02);
								 gt(fg2, e, 0.03);
								gt(btn, e, 0.01);
								card.css({"transform": "matrix3d(" + mtx.toString() + ")"});
							}
						});
					});
				},
			},

			initializeVisualComposerAfterAjax: function(){
				if(typeof vc_toggleBehaviour === "function"){
					vc_toggleBehaviour();
				}
				if(typeof vc_tabsBehaviour === "function"){
					vc_tabsBehaviour();
				}
				if(typeof vc_accordionBehaviour === "function"){
					vc_accordionBehaviour();
				}
				if(typeof vc_initVideoBackgrounds === "function"){
					vc_initVideoBackgrounds();
				}
				if(typeof vc_teaserGrid === "function"){
					vc_teaserGrid();
				}
				if(typeof vc_carouselBehaviour === "function"){
					vc_carouselBehaviour();
				}
				if(typeof vc_slidersBehaviour === "function"){
					vc_slidersBehaviour();
				}
				if(typeof vc_prettyPhoto === "function"){
					vc_prettyPhoto();
				}
				if(typeof vc_googleplus === "function"){
					vc_googleplus();
				}
				if(typeof vc_pinterest === "function"){
					vc_pinterest();
				}
				// $(".not-collapse").on("click", function(e) { e.stopPropagation();  });
				if( typeof($.fn.qtChartvoteInit) === "function") {
					$.fn.qtChartvoteInit();
				}
				$("body [data-bgimagevc]").each(function() {
					var that = $(this),
						bg = that.attr("data-bgimagevc"),
						bgattachment = that.attr("data-bgattachment");
					if (bgattachment === undefined) {
						bgattachment = "static";
					}
					if (bg !== '') {
						that.css({
							"background-image": "url(" + bg + ")",
							"background-attachment": "fixed"
						});
					}
				});
			},

			qtMaterialSlideshow: function(){
				$('.qt-material-slider').each(function(i,c){
					var S = $(c),
						P = S.data("proportion"),
						PM = S.data("proportionmob"),
						height = S.data("height"),
						wnd = $.qtWebsiteObj.window;

					if(wnd.width() < 680){
						P = PM;
					}
					if(P === 'wide'){
						height = S.width()/16*9;
					}
					if(P === 'ultrawide'){
						height = S.width()/2;
					}
					if(P === 'full'){
						height = wnd.height();
					}
					S.slider({
						full_width: true, 
						height: height 
					}).delay(2).promise().done(function(){
						S.addClass("active");
					});
					S.on("click",".prev", function(e){
						e.preventDefault();
						S.slider("prev");
					});
					S.on("click",".next", function(e){
						e.preventDefault();
						S.slider("next");
					});
					S.on("mouseenter",".qt-slideshow-link", function(){
						S.slider("pause");
					}).on("mouseleave",".qt-slideshow-link", function(){
						S.slider("start");
					});
				});
			},

			scrollUpF: function(){
				if($.qtWebsiteObj.fn.isMobile){
					var lst = 0,
						m = $('#qt-mob-navbar');
					document.addEventListener("scroll", function(){ 
					   var st = window.pageYOffset || document.documentElement.scrollTop;
					   if (st > lst){
							m.removeClass('qt-up');
							if(st > 80){
								m.addClass('qt-down');
							} else {
								m.removeClass('qt-down');
							}
					   } else {
							m.removeClass('qt-down');
							m.addClass('qt-up');
					   }
					   lst = st;
					}, false);
				}
			},

			/**====================================================================
			 *
			 * 
			 *  Popup opener (requires library component) 
			 *  
			 * 
			 ====================================================================*/
			qtPopupwindow: function() {
				if(typeof($.fn.popupwindow) !== "undefined"){
					$(".qt-popupwindow").popupwindow();
				}
			},

			qtResizeTimer: function(){
				var resizeTimer,
					o = $.qtWebsiteObj,
					w = o.window,
					ww = w.width(),
					wh = w.height(),
					f = o.fn;
				w.on('resize', function(e) {
					clearTimeout(resizeTimer);
					resizeTimer = setTimeout(function() {
						if (w.width() != ww || w.height() != wh) {
							f.perspCard.init();
						}
						
					}, 150);
				});
			},

			/**====================================================================
			 *
			 *	After ajax page initialization
			 * 	Used by QT Ajax Pageloader. 
			 * 	MUST RETURN TRUE IF ALL OK.
			 * 
			 ====================================================================*/
			initializeAfterAjax: function(){
				qtDebug('-> initializeAfterAjax');
				try {

					qtDebug('Doing');
					var f = $.qtWebsiteObj.fn;
					f.perspCard.init();
					f.slickGallery();
					f.qtActivates();
					f.dynamicBackgroundsV4();
					f.qtParallaxV8();
					if( "undefined" !== typeof($.qtWebsiteObj.skrollrInstance)) {
						$.qtWebsiteObj.skrollrInstance.refresh();
					} else {
						f.qtSkrollrInit();
					}
					f.transformlinks("#maincontent", false);
					f.transformlinks("#qtFooterWidgets", false);
					
					$('.qt-collapsible').collapsible();
					jQuery('ul.tabs').tabs({"swipeable":false});
					f.smoothScr();
					f.YTreszr();
					f.qtCardActivator();
					f.qtVideoBg();
					f.qtMaterialSlideshow();
					f.countDown.init();
					f.pageheaderFx();
					f.masonry();
					f.shareitem();
					f.loadmore.init();
					f.qt3DfxFunction.close();
					f.qtPopupwindow();
					if(typeof $.fn.qtDynamicMaps === "function"){
						$.fn.qtDynamicMaps();
					}
					$('.dropdown-button').dropdown({
						inDuration: 300,
						outDuration: 225,
						constrainWidth: false, // Does not change width of dropdown to that of the activator
						hover: false, // Activate on hover
						gutter: 0, // Spacing from edge
						belowOrigin: true, // Displays dropdown below the button
						alignment: 'left', // Displays dropdown with edge aligned to the left of button
						stopPropagation: false // Stops event propagation
					});
					// restore Page Composer animations
					if($.qtWebsiteObj.body.hasClass("qt-animations-enabled")){
						jQuery.fn.waypoint && jQuery(".wpb_animate_when_almost_visible:not(.wpb_start_animation)").waypoint(function() {
							jQuery(this).addClass("wpb_start_animation animated");
						}, {
							offset: "85%"
						});
					}
					jQuery.fn.waypoint && jQuery(".qt-txtfx:not(.qt-txtfxstart)").waypoint(function() {
						qtDebug('waypoint');
						jQuery(this).addClass("qt-txtfxstart");
					}, {
						offset: "80%",
					});
					if(typeof $.fn.qtPlacesInit === "function"){
						$.fn.qtPlacesInit();
					}
					$(window).scroll();

					// if('function' === typeof( $.kentha_wc_price_slider ) ){
					// 	$.kentha_wc_price_slider ();
					// 	jQuery('.woocommerce-product-gallery').animate({opacity: 1});
					// }
					return true;
				} catch(e) {
					qtDebug('errors happening');
					return false;
				}
			},
			/**====================================================================
			 *
			 * 
			 *  Functions to run once on first page load
			 *  
			 *
			 ====================================================================*/
			init: function() {
				qtDebug('====== KENTHA INITIALIZATION =======');
				var f = $.qtWebsiteObj.fn;
				$(".button-collapse").sideNav();
				$.qtWebsiteObj.body.on("click", ".qt-closesidenav", function(e) {
					e.preventDefault();
					$('.button-collapse').sideNav('hide');
				});
				f.qtMobileNav();
				f.qt3DfxFunction.init();
				f.scrollUpF();
				f.initializeAfterAjax();
				f.qtResizeTimer();
			},
		}
		/**
		 * ======================================================================================================================================== |
		 * 																																			|
		 * 																																			|
		 * END SITE FUNCTIONS 																														|
		 * 																																			|
		 *																																			|
		 * ======================================================================================================================================== |
		 */
	};
	/**====================================================================
	 *
	 *	Page Ready Trigger
	 * 	This needs to call only $.qtWebsiteObj.fn.qtInitTheme
	 * 
	 ====================================================================*/
	jQuery(document).ready(function() {
		$.qtWebsiteObj.fn.init();		
	});

	$( window ).resize(function() {
		$.qtWebsiteObj.fn.YTreszr();
	});
})(jQuery);