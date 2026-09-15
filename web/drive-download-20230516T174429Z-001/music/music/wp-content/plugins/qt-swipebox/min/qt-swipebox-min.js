// https://raw.githubusercontent.com/splitbrain/dokuwiki-plugin-gallery/master/swipebox/js/jquery.swipebox.js
/*! Swipebox v1.4.5 | Constantin Saguin csag.co | MIT License | github.com/brutaldesign/swipebox */
!function(c,b,x,u){x.swipebox=function(o,e){
// Default options
var a,t={useCSS:!0,useSVG:!0,initialIndexOnArray:0,removeBarsOnMobile:!0,hideCloseButtonOnMobile:!1,hideBarsDelay:3e3,videoMaxWidth:1140,vimeoColor:"cccccc",beforeOpen:null,afterOpen:null,afterClose:null,afterMedia:null,nextSlide:null,prevSlide:null,loopAtEnd:!1,autoplayVideos:!1,queryStringData:{},toggleClassOnLoad:"",titleAttribute:"title",captionAttribute:"data-caption",selector:null},r=this,w=[],// slides array [ { href:'...', title:'...' }, ...],
n,i=navigator.userAgent.match(/(iPad)|(iPhone)|(iPod)|(Android)|(PlayBook)|(BB10)|(BlackBerry)|(Opera Mini)|(IEMobile)|(webOS)|(MeeGo)/i),s=null!==i||b.createTouch!==u||"ontouchstart"in c||"onmsgesturechange"in c||navigator.msMaxTouchPoints,l=!!b.createElementNS&&!!b.createElementNS("http://www.w3.org/2000/svg","svg").createSVGRect,v=c.innerWidth?c.innerWidth:x(c).width(),d=c.innerHeight?c.innerHeight:x(c).height(),m=0,
/* jshint multistr: true */
p='<div id="swipebox-overlay">\t\t\t\t\t<div id="swipebox-container">\t\t\t\t\t\t<div id="swipebox-slider"></div>\t\t\t\t\t\t<div id="swipebox-top-bar">\t\t\t\t\t\t\t<div id="swipebox-title"></div>\t\t\t\t\t\t</div>\t\t\t\t\t\t<div id="swipebox-bottom-bar">\t\t\t\t\t\t\t<div id="swipebox-arrows">\t\t\t\t\t\t\t\t<a id="swipebox-prev"></a>\t\t\t\t\t\t\t\t<a id="swipebox-next"></a>\t\t\t\t\t\t\t</div>\t\t\t\t\t\t</div>\t\t\t\t\t\t<a id="swipebox-close"></a>\t\t\t\t\t</div>\t\t\t</div>';r.settings={},x.swipebox.close=function(){a.closeSlide()},x.swipebox.extend=function(){return a},r.init=function(){r.settings=x.extend({},t,e),x.isArray(o)?(w=o,a.target=x(c),a.init(r.settings.initialIndexOnArray)):x(o).on("click",r.settings.selector,function(e){
// console.log( isTouch );
if("slide current"===e.target.parentNode.className)return!1;var t,i,s;
// Allow for HTML5 compliant attribute before legacy use of rel
a.destroy(),n=null===r.settings.selector?x(o):x(o).find(r.settings.selector),w=[],s||(i="data-rel",s=x(this).attr(i)),s||(i="rel",s=x(this).attr(i)),s&&""!==s&&"nofollow"!==s&&(n=n.filter("["+i+'="'+s+'"]')),n.each(function(){var e=null,t=null,i=null;x(this).attr(r.settings.titleAttribute)&&(e=x(this).attr(r.settings.titleAttribute)),x(this).attr(r.settings.captionAttribute)&&(t=x(this).attr(r.settings.captionAttribute)),x(this).attr("href")&&(i=x(this).attr("href")),w.push({href:i,title:e,caption:t})}),t=n.index(x(this)),e.preventDefault(),e.stopPropagation(),a.target=x(e.target),a.init(t)})},a={
/**
			 * Initiate Swipebox
			 */
init:function(e){r.settings.beforeOpen&&r.settings.beforeOpen(),this.target.trigger("swipebox-start"),x.swipebox.isOpen=!0,this.build(),this.openSlide(e),this.openMedia(e),this.preloadMedia(e+1),this.preloadMedia(e-1),r.settings.afterOpen&&r.settings.afterOpen(e)},
/**
			 * Built HTML containers and fire main functions
			 */
build:function(){var e=this,t;x("body").append(p),l&&!0===r.settings.useSVG&&(t=(t=x("#swipebox-close").css("background-image")).replace("png","svg"),x("#swipebox-prev, #swipebox-next, #swipebox-close").css({"background-image":t})),i&&r.settings.removeBarsOnMobile&&x("#swipebox-bottom-bar, #swipebox-top-bar").remove(),x.each(w,function(){x("#swipebox-slider").append('<div class="slide"></div>')}),e.setDim(),e.actions(),s&&e.gesture(),
// Devices can have both touch and keyboard input so always allow key events
e.keyboard(),e.animBars(),e.resize()},
/**
			 * Set dimensions depending on windows width and height
			 */
setDim:function(){var e,t,i={};
// Reset dimensions on mobile orientation change
"onorientationchange"in c?c.addEventListener("orientationchange",function(){0===c.orientation?(e=v,t=d):90!==c.orientation&&-90!==c.orientation||(e=d,t=v)},!1):(e=c.innerWidth?c.innerWidth:x(c).width(),t=c.innerHeight?c.innerHeight:x(c).height()),i={width:e,height:t},x("#swipebox-overlay").css(i)},
/**
			 * Reset dimensions on window resize envent
			 */
resize:function(){var e=this;x(c).resize(function(){e.setDim()}).resize()},
/**
			 * Check if device supports CSS transitions
			 */
supportTransition:function(){var e="transition WebkitTransition MozTransition OTransition msTransition KhtmlTransition".split(" "),t;for(t=0;t<e.length;t++)if(b.createElement("div").style[e[t]]!==u)return e[t];return!1},
/**
			 * Check if CSS transitions are allowed (options + devicesupport)
			 */
doCssTrans:function(){if(r.settings.useCSS&&this.supportTransition())return!0},
/**
			 * Touch navigation
			 */
gesture:function(){var i=this,s,o,n,a,r,l,d=!1,p=!1,c=10,b=50,u={},h={},g=x("#swipebox-top-bar, #swipebox-bottom-bar"),f=x("#swipebox-slider");g.addClass("visible-bars"),i.setTimeout(),x("body").bind("touchstart",function(e){return x(this).addClass("touching"),s=x("#swipebox-slider .slide").index(x("#swipebox-slider .slide.current")),h=e.originalEvent.targetTouches[0],u.pageX=e.originalEvent.targetTouches[0].pageX,u.pageY=e.originalEvent.targetTouches[0].pageY,x("#swipebox-slider").css({"-webkit-transform":"translate3d("+m+"%, 0, 0)",transform:"translate3d("+m+"%, 0, 0)"}),x(".touching").bind("touchmove",function(e){if(e.preventDefault(),e.stopPropagation(),h=e.originalEvent.targetTouches[0],!p&&(r=n,n=h.pageY-u.pageY,Math.abs(n)>=b||d)){var t=.75-Math.abs(n)/f.height();f.css({top:n+"px"}),f.css({opacity:t}),d=!0}a=o,o=h.pageX-u.pageX,l=100*o/v,!p&&!d&&Math.abs(o)>=c&&(x("#swipebox-slider").css({"-webkit-transition":"",transition:""}),p=!0),p&&(
// swipe left
0<o?
// first slide
0===s?
// console.log( 'first' );
x("#swipebox-overlay").addClass("leftSpringTouch"):(
// Follow gesture
x("#swipebox-overlay").removeClass("leftSpringTouch").removeClass("rightSpringTouch"),x("#swipebox-slider").css({"-webkit-transform":"translate3d("+(m+l)+"%, 0, 0)",transform:"translate3d("+(m+l)+"%, 0, 0)"})):o<0&&(
// last Slide
w.length===s+1?
// console.log( 'last' );
x("#swipebox-overlay").addClass("rightSpringTouch"):(x("#swipebox-overlay").removeClass("leftSpringTouch").removeClass("rightSpringTouch"),x("#swipebox-slider").css({"-webkit-transform":"translate3d("+(m+l)+"%, 0, 0)",transform:"translate3d("+(m+l)+"%, 0, 0)"}))))}),!1}).bind("touchend",function(e){
// Swipe to bottom to close
if(e.preventDefault(),e.stopPropagation(),x("#swipebox-slider").css({"-webkit-transition":"-webkit-transform 0.4s ease",transition:"transform 0.4s ease"}),n=h.pageY-u.pageY,o=h.pageX-u.pageX,l=100*o/v,d)if(d=!1,100<=Math.abs(n)&&Math.abs(n)>Math.abs(r)){var t=0<n?f.height():-f.height();f.animate({top:t+"px",opacity:0},300,function(){i.closeSlide()})}else f.animate({top:0,opacity:1},300);else p?(p=!1,
// swipeLeft
c<=o&&a<=o?i.getPrev():o<=-c&&o<=a&&i.getNext()):// Top and bottom bars have been removed on touchable devices
// tap
g.hasClass("visible-bars")?(i.clearTimeout(),i.hideBars()):(i.showBars(),i.setTimeout());x("#swipebox-slider").css({"-webkit-transform":"translate3d("+m+"%, 0, 0)",transform:"translate3d("+m+"%, 0, 0)"}),x("#swipebox-overlay").removeClass("leftSpringTouch").removeClass("rightSpringTouch"),x(".touching").off("touchmove").removeClass("touching")})},
/**
			 * Set timer to hide the action bars
			 */
setTimeout:function(){if(0<r.settings.hideBarsDelay){var e=this;e.clearTimeout(),e.timeout=c.setTimeout(function(){e.hideBars()},r.settings.hideBarsDelay)}},
/**
			 * Clear timer
			 */
clearTimeout:function(){c.clearTimeout(this.timeout),this.timeout=null},
/**
			 * Show navigation and title bars
			 */
showBars:function(){var e;x("#swipebox-top-bar, #swipebox-bottom-bar").addClass("visible-bars")},
/**
			 * Hide navigation and title bars
			 */
hideBars:function(){var e;x("#swipebox-top-bar, #swipebox-bottom-bar").removeClass("visible-bars")},
/**
			 * Animate navigation and top bars
			 */
animBars:function(){var e=this,t=x("#swipebox-top-bar, #swipebox-bottom-bar");t.addClass("visible-bars"),e.setTimeout(),x("#swipebox-slider").click(function(){t.hasClass("visible-bars")||(e.showBars(),e.setTimeout())}),x("#swipebox-bottom-bar").hover(function(){e.showBars(),t.addClass("visible-bars"),e.clearTimeout()},function(){0<r.settings.hideBarsDelay&&(t.removeClass("visible-bars"),e.setTimeout())})},
/**
			 * Keyboard navigation
			 */
keyboard:function(){var t=this;x(c).bind("keyup",function(e){e.preventDefault(),e.stopPropagation(),37===e.keyCode?t.getPrev():39===e.keyCode?t.getNext():27===e.keyCode&&t.closeSlide()})},
/**
			 * Navigation events : go to next slide, go to prevous slide and close
			 */
actions:function(){var t=this,e="touchend click";// Just detect for both event types to allow for multi-input
w.length<2?(x("#swipebox-bottom-bar").hide(),u===w[1]&&x("#swipebox-top-bar").hide()):(x("#swipebox-prev").bind(e,function(e){e.preventDefault(),e.stopPropagation(),t.getPrev(),t.setTimeout()}),x("#swipebox-next").bind(e,function(e){e.preventDefault(),e.stopPropagation(),t.getNext(),t.setTimeout()})),x("#swipebox-close").bind(e,function(e){e.preventDefault(),e.stopPropagation(),t.closeSlide()})},
/**
			 * Set current slide
			 */
setSlide:function(e,t){t=t||!1;var i=x("#swipebox-slider");m=100*-e,this.doCssTrans()?i.css({"-webkit-transform":"translate3d("+100*-e+"%, 0, 0)",transform:"translate3d("+100*-e+"%, 0, 0)"}):i.animate({left:100*-e+"%"}),x("#swipebox-slider .slide").removeClass("current"),x("#swipebox-slider .slide").eq(e).addClass("current"),this.setTitle(e),t&&i.fadeIn(),x("#swipebox-prev, #swipebox-next").removeClass("disabled"),0===e?x("#swipebox-prev").addClass("disabled"):e===w.length-1&&!0!==r.settings.loopAtEnd&&x("#swipebox-next").addClass("disabled"),
// reshow bars on each navigation
this.showBars(),this.setTimeout()},
/**
			 * Open slide
			 */
openSlide:function(e){x("html").addClass("swipebox-html"),s?(x("html").addClass("swipebox-touch"),r.settings.hideCloseButtonOnMobile&&x("html").addClass("swipebox-no-close-button")):x("html").addClass("swipebox-no-touch"),x(c).trigger("resize"),// fix scroll bar visibility on desktop
this.setSlide(e,!0)},
/**
			 * Set a time out if the media is a video
			 */
preloadMedia:function(e){var t=this,i=null;w[e]!==u&&(i=w[e].href),t.isVideo(i)?t.openMedia(e):setTimeout(function(){t.openMedia(e)},1e3)},
/**
			 * Open
			 */
openMedia:function(e){var t=this,i,s;if(w[e]!==u&&(i=w[e].href),e<0||e>=w.length)return!1;s=x("#swipebox-slider .slide").eq(e),t.isVideo(i)?(s.html(t.getVideo(i)),r.settings.afterMedia&&r.settings.afterMedia(e)):(s.addClass("slide-loading"),t.loadMedia(i,function(){s.removeClass("slide-loading"),s.html(this),r.settings.afterMedia&&r.settings.afterMedia(e)}))},
/**
			 * Set link title attribute as caption
			 */
setTitle:function(e){var t=null,i=null;if(x("#swipebox-title").empty(),w[e]!==u&&(t=w[e].title,i=w[e].caption),t||i){if(x("#swipebox-top-bar").show(),t){var s=x("<div></div>").addClass("title").text(t);x("#swipebox-title").append(s)}if(i){var o=x("<div></div>").addClass("caption").text(i);x("#swipebox-title").append(o)}}else x("#swipebox-top-bar").hide()},
/**
			 * Check if the URL is a video
			 */
isVideo:function(e){if(e){if(e.match(/(youtube\.com|youtube-nocookie\.com)\/watch\?v=([a-zA-Z0-9\-_]+)/)||e.match(/vimeo\.com\/([0-9]*)/)||e.match(/youtu\.be\/([a-zA-Z0-9\-_]+)/))return!0;if(0<=e.toLowerCase().indexOf("swipeboxvideo=1"))return!0}},
/**
			 * Parse URI querystring and:
			 * - overrides value provided via dictionary
			 * - rebuild it again returning a string
			 */
parseUri:function(e,t){var i=b.createElement("a"),s={};
// Decode the URI
// Return querystring as a string
return i.href=decodeURIComponent(e),
// QueryString to Object
i.search&&(s=JSON.parse('{"'+i.search.toLowerCase().replace("?","").replace(/&/g,'","').replace(/=/g,'":"')+'"}')),
// Extend with custom data
x.isPlainObject(t)&&(s=x.extend(s,t,r.settings.queryStringData)),x.map(s,function(e,t){if(e&&""<e)return encodeURIComponent(t)+"="+encodeURIComponent(e)}).join("&")},
/**
			 * Get video iframe code from URL
			 */
getVideo:function(e){var t="",i=e.match(/((?:www\.)?youtube\.com|(?:www\.)?youtube-nocookie\.com)\/watch\?v=([a-zA-Z0-9\-_]+)/),s=e.match(/(?:www\.)?youtu\.be\/([a-zA-Z0-9\-_]+)/),o=e.match(/(?:www\.)?vimeo\.com\/([0-9]*)/),n="";return t=i||s?(s&&(i=s),n=a.parseUri(e,{autoplay:r.settings.autoplayVideos?"1":"0",v:""}),'<iframe width="560" height="315" src="//'+i[1]+"/embed/"+i[2]+"?"+n+'" frameborder="0" allowfullscreen></iframe>'):o?(n=a.parseUri(e,{autoplay:r.settings.autoplayVideos?"1":"0",byline:"0",portrait:"0",color:r.settings.vimeoColor}),'<iframe width="560" height="315"  src="//player.vimeo.com/video/'+o[1]+"?"+n+'" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'):'<iframe width="560" height="315" src="'+e+'" frameborder="0" allowfullscreen></iframe>','<div class="swipebox-video-container" style="max-width:'+r.settings.videoMaxWidth+'px"><div class="swipebox-video">'+t+"</div></div>"},
/**
			 * Load image
			 */
loadMedia:function(e,t){
// Inline content
if(0===e.trim().indexOf("#"))t.call(x("<div>",{class:"swipebox-inline-container"}).append(x(e).clone().toggleClass(r.settings.toggleClassOnLoad)));else if(!this.isVideo(e)){var i=x("<img>").on("load",function(){t.call(i)});i.attr("src",e)}},
/**
			 * Get next slide
			 */
getNext:function(){var e=this,t,i=x("#swipebox-slider .slide").index(x("#swipebox-slider .slide.current"));i+1<w.length?(t=x("#swipebox-slider .slide").eq(i).contents().find("iframe").attr("src"),x("#swipebox-slider .slide").eq(i).contents().find("iframe").attr("src",t),i++,e.setSlide(i),e.preloadMedia(i+1),r.settings.nextSlide&&r.settings.nextSlide(i)):!0===r.settings.loopAtEnd?(t=x("#swipebox-slider .slide").eq(i).contents().find("iframe").attr("src"),x("#swipebox-slider .slide").eq(i).contents().find("iframe").attr("src",t),i=0,e.preloadMedia(i),e.setSlide(i),e.preloadMedia(i+1),r.settings.nextSlide&&r.settings.nextSlide(i)):(x("#swipebox-overlay").addClass("rightSpring"),setTimeout(function(){x("#swipebox-overlay").removeClass("rightSpring")},500))},
/**
			 * Get previous slide
			 */
getPrev:function(){var e=x("#swipebox-slider .slide").index(x("#swipebox-slider .slide.current")),t;0<e?(t=x("#swipebox-slider .slide").eq(e).contents().find("iframe").attr("src"),x("#swipebox-slider .slide").eq(e).contents().find("iframe").attr("src",t),e--,this.setSlide(e),this.preloadMedia(e-1),r.settings.prevSlide&&r.settings.prevSlide(e)):(x("#swipebox-overlay").addClass("leftSpring"),setTimeout(function(){x("#swipebox-overlay").removeClass("leftSpring")},500))},
/* jshint unused:false */
nextSlide:function(e){
// Callback for next slide
},prevSlide:function(e){
// Callback for prev slide
},
/**
			 * Close
			 */
closeSlide:function(){x("html").removeClass("swipebox-html"),x("html").removeClass("swipebox-touch"),x(c).trigger("resize"),this.destroy()},
/**
			 * Destroy the whole thing
			 */
destroy:function(){x(c).unbind("keyup"),x("body").unbind("touchstart"),x("body").unbind("touchmove"),x("body").unbind("touchend"),x("#swipebox-slider").unbind(),x("#swipebox-overlay").remove(),x.isArray(o)||o.removeData("_swipebox"),this.target&&this.target.trigger("swipebox-destroy"),x.swipebox.isOpen=!1,r.settings.afterClose&&r.settings.afterClose()}},r.init()},x.fn.swipebox=function(e){if(!x.data(this,"_swipebox")){var t=new x.swipebox(this,e);this.data("_swipebox",t)}return this.data("_swipebox")}}(window,document,jQuery),// @codekit-prepend "swipebox/js/jquery.swipebox.js"
function(e){e(window).on("load",function(){e.qtSwipeboxEnable=!0,// this is for the main jquery file after ajax
e('.swipebox, .gallery a, a[href*=".jpg"], a[href*="youtube.com"]:not(.qw_social), a[href*="youtu.be"]:not(.qw_social), a[href*="vimeo.com"]:not(.qw_social), a[href*="jpeg"], a[href*=".png"], a[href*=".gif"], .Collage a').swipebox({beforeOpen:function(){e.swipeboxState=1}// called before opening
})})}(jQuery);