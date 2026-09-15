/*
 * YoutubeBackground - A wrapper for the Youtube API - Great for fullscreen background videos or just regular videos.
 *
 * Licensed under the MIT license:
 *   http://www.opensource.org/licenses/mit-license.php
 *
 *
 * Version:  1.0.6
 *
 */
// Chain of Responsibility pattern. Creates base class that can be overridden.
"function"!=typeof Object.create&&(Object.create=function(t){function e(){}return e.prototype=t,new e}),function(d,s,t){var n=d(s),i=function t(e){
/**
			 * Since Page builder 6.1 this was breaking the video loading
			 * 1.0.6 removed and added getScript in a page ready event
			 */
// Load Youtube API
// var tag = document.createElement('script'),
// head = document.getElementsByTagName('head')[0];
// tag.src = '//www.youtube.com/iframe_api';
// head.appendChild(tag);
// // Clean up Tags.
// head = null;
// tag = null;
o(e)},o=function t(e){
// Listen for Gobal YT player callback
"undefined"==typeof YT&&void 0===s.loadingPlayer?(
// Prevents Ready Event from being called twice
s.loadingPlayer=!0,
// Creates deferred so, other players know when to wait.
s.dfd=d.Deferred(),s.onYouTubeIframeAPIReady=function(){s.onYouTubeIframeAPIReady=null,s.dfd.resolve("done"),e()}):"object"==typeof YT?e():s.dfd.done(function(){e()})},
// YTPlayer Object
a={player:null,
// Defaults
defaults:{ratio:16/9,videoId:"iGpuQ0ioPrM",mute:!0,repeat:!0,width:d(s).width(),playButtonClass:"YTPlayer-play",pauseButtonClass:"YTPlayer-pause",muteButtonClass:"YTPlayer-mute",volumeUpClass:"YTPlayer-volume-up",volumeDownClass:"YTPlayer-volume-down",start:0,pauseOnScroll:!1,fitToBackground:!0,playerVars:{iv_load_policy:3,modestbranding:1,autoplay:1,controls:0,showinfo:0,wmode:"opaque",branding:0,autohide:0},events:null},
/**
			 * @function init
			 * Intializes YTPlayer object
			 */
init:function t(e,o){var a=this;return a.userOptions=o,a.$body=d("body"),a.$node=d(e),
// self.$window = $(window);
// Setup event defaults with the reference to this
a.defaults.events={onReady:function(t){a.onPlayerReady(t),
// setup up pause on scroll
a.options.pauseOnScroll&&a.pauseOnScroll(),
// Callback for when finished
"function"==typeof a.options.callback&&a.options.callback.call(this)},onStateChange:function(t){1===t.data?(a.$node.find("img").fadeOut(400),a.$node.addClass("loaded")):0===t.data&&a.options.repeat&&// video ended and repeat option is set true
a.player.seekTo(a.options.start)}},a.options=d.extend(!0,{},a.defaults,a.userOptions),a.options.height=Math.ceil(a.options.width/a.options.ratio),a.ID=(new Date).getTime(),a.holderID="YTPlayer-ID-"+a.ID,a.options.fitToBackground?a.createBackgroundVideo():a.createContainerVideo(),
// Listen for Resize Event
n.on("resize.YTplayer"+a.ID,function(){a.resize(a)}),i(a.onYouTubeIframeAPIReady.bind(a)),a.resize(a),a},
/**
			 * @function pauseOnScroll
			 * Adds window events to pause video on scroll.
			 */
pauseOnScroll:function t(){var e=this;n.on("scroll.YTplayer"+e.ID,function(){var t;1===e.player.getPlayerState()&&e.player.pauseVideo()}),n.scrollStopped(function(){var t;2===e.player.getPlayerState()&&e.player.playVideo()})},
/**
			 * @function createContainerVideo
			 * Adds HTML for video in a container
			 */
createContainerVideo:function t(){var e=this,o=d('<div id="ytplayer-container'+e.ID+'" >\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<div id="'+e.holderID+'" class="ytplayer-player-inline"></div> \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</div> \t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<div id="ytplayer-shield" class="ytplayer-shield"></div>');
/*jshint multistr: true */e.$node.append(o),e.$YTPlayerString=o,o=null},
/**
			 * @function createBackgroundVideo
			 * Adds HTML for video background
			 */
createBackgroundVideo:function t(){
/*jshint multistr: true */
var e=this,o=d('<div id="ytplayer-container'+e.ID+'" class="ytplayer-container background">\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<div id="'+e.holderID+'" class="ytplayer-player"></div>\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t</div>\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t<div id="ytplayer-shield" class="ytplayer-shield"></div>');e.$node.append(o),e.$YTPlayerString=o,o=null},
/**
			 * @function resize
			 * Resize event to change video size
			 */
resize:function t(e){
//var self = this;
var o=d(s);e.options.fitToBackground||(o=e.$node);var a=o.width(),n,// player width, to be defined
i=o.height(),r,// player height, tbd
l=d("#"+e.holderID);
// when screen aspect ratio differs from video, video must center and underlay one dimension
a/e.options.ratio<i?(n=Math.ceil(i*e.options.ratio),// get new player width
l.width(n).height(i).css({left:(a-n)/2,top:0})):(// new video width < window width (gap to right)
r=Math.ceil(a/e.options.ratio),// get new player height
l.width(a).height(r).css({left:0,top:(i-r)/2})),o=l=null},
/**
			 * @function onYouTubeIframeAPIReady
			 * @ params {object} YTPlayer object for access to options
			 * Youtube API calls this function when the player is ready.
			 */
onYouTubeIframeAPIReady:function t(){var e=this;e.player=new s.YT.Player(e.holderID,e.options)},
/**
			 * @function onPlayerReady
			 * @ params {event} window event from youtube player
			 */
onPlayerReady:function t(e){this.options.mute&&e.target.mute(),e.target.playVideo()},
/**
			 * @function getPlayer
			 * returns youtube player
			 */
getPlayer:function t(){return this.player},
/**
			 * @function destroy
			 * destroys all!
			 */
destroy:function t(){var e=this;e.$node.removeData("yt-init").removeData("ytPlayer").removeClass("loaded"),e.$YTPlayerString.remove(),d(s).off("resize.YTplayer"+e.ID),d(s).off("scroll.YTplayer"+e.ID),e.$body=null,e.$node=null,e.$YTPlayerString=null,e.player.destroy(),e.player=null}};
// Scroll Stopped event.
d.fn.scrollStopped=function(t){var e=d(this),o=this;e.scroll(function(){e.data("scrollTimeout")&&clearTimeout(e.data("scrollTimeout")),e.data("scrollTimeout",setTimeout(t,250,o))})},
// Create plugin
d.fn.YTPlayer=function(o){return this.each(function(){var t=this;d(t).data("yt-init",!0);var e=Object.create(a);e.init(t,o),d.data(t,"ytPlayer",e)})},
/**
	 * @since 1.0.6
	 * Added to prevent Page Builder conflict
	 */
jQuery(t).ready(function(){d.getScript("//www.youtube.com/iframe_api")})}(jQuery,window,document);