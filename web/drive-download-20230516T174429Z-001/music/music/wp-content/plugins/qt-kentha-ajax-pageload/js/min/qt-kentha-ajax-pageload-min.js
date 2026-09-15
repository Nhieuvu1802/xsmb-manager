/**====================================================================
 *
 *  QT Ajax Page Loader main script
 *  @author QantumThemes
 *  
 ====================================================================**/
!function($){"use strict";$("body").append('<div id="qtajaxpreloadericon" class="qt-kenthapreloader-icon"><div class="preloader-wrapper big active"><div class="spinner-layer spinner-white-only"><div class="circle-clipper left"><div class="circle"></div></div><div class="gap-patch"><div class="circle"></div></div><div class="circle-clipper right"><div class="circle"></div></div></div></div></div>');var qtAplSelector="#maincontent",qtBreadcrumbSelector="#qtBreadcrumb",qtAplMaincontent=$(qtAplSelector),atAplPreloader=$("#qtajaxpreloadericon");
/**
	 * [Before switching content let's scroll to top]
	 * @return {[bol]}
	 */$.fn.qtAplScrollTop=function(){return $("html, body").animate({scrollTop:0},100,"easeOutExpo"),!0},
/**
	 * [Main ajax initialization function]
	 */
$.fn.qtAplInitAjaxPageLoad=function(){
/**
		 * [ajax call]
		 * @param  {[text]} link [url to load]
		 * @return {[bol]}
		 */
function qtAplExecuteAjaxLink(link){var docClass,parser;return $.ajax({url:link,success:function(data){
/*
					*   Retrive the contents
					*/
$.ajaxData=data,parser=new DOMParser,$.qtAplAjaxContents=$($.ajaxData).find(qtAplSelector).html(),$.qtAplAjaxBreadcrumb=$($.ajaxData).find(qtBreadcrumbSelector).html(),$.qtAplAjaxTitle=$($.ajaxData).filter("title").text(),docClass=$($.ajaxData).filter("body").attr("class"),$.qtAplBodyMatches=data.match(/<body.*class=["']([^"']*)["'].*>/),void 0!==$.qtAplBodyMatches?docClass=$.qtAplBodyMatches[1]:window.location.replace(link);
// New method better working: 
var modifiedAjaxResult=data.replace(/<body/i,'<div id="re_body"').replace(/<\/body/i,"</div"),bodyClassesNew=$(modifiedAjaxResult).filter("#re_body").attr("class"),
//20190527
//Custom css change id
js_composer_front_css=$(modifiedAjaxResult).filter("#js_composer_front-inline-css").text();if(bodyClassesNew&&(docClass=bodyClassesNew.split("qt-body-preloading").join(""),0<=bodyClassesNew.indexOf("qtapl-skip")))return window.location.replace(link);$.wpadminbar=$($.ajaxData).filter("#wpadminbar").html(),$.qtCustomTextFxStyles=$($.ajaxData).filter("#kentha-textfx-inline-css"),$("html").remove("#kentha-textfx-inline-css"),0<$.qtCustomTextFxStyles.length&&$("head").append('<style id="kentha-textfx-inline-css" >'+$.qtCustomTextFxStyles.text()+"</style>"),$.visual_composer_styles=$($.ajaxData).filter("style[data-type=vc_shortcodes-custom-css]").text(),
/**
					 * [if we have WPML plugin language selector]
					 */
$("#qwLLT")&&($.langswitcher=$($.ajaxData).find("#qwLLT").html())
/*
					*   Start putting the data in the page
					*/,void 0!==docClass&&void 0!==$.qtAplAjaxContents?($("body").attr("class",docClass),$("title").text($.qtAplAjaxTitle),$("#wpadminbar").html($.wpadminbar),$("#qwLLT").html($.langswitcher),$.qtAplAjaxBreadcrumb&&$(qtBreadcrumbSelector)&&$(qtBreadcrumbSelector).html($.qtAplAjaxBreadcrumb),$("head").remove("#qt_ajax_vc_shortcodes_customcss"),0<$("style[data-type=vc_shortcodes-custom-css]").length?$("style[data-type=vc_shortcodes-custom-css]").append($.visual_composer_styles):$("head").append('<style id="qt_ajax_vc_shortcodes_customcss" data-type="vc_shortcodes-custom-css">'+$.visual_composer_styles+"</style>"),
// 2019 may 27 js composer update css
""!=js_composer_front_css&&0!=js_composer_front_css&&null!=js_composer_front_css?0<$("style#js_composer_front-inline-css").length?$("style#js_composer_front-inline-css").html(js_composer_front_css):$("head").append('<style id="js_composer_front-inline-css">'+js_composer_front_css+"</style>"):$("head style#js_composer_front-inline-css").remove(),qtAplMaincontent.html($.qtAplAjaxContents).delay(100).promise().done(function(){var scripts=qtAplMaincontent.find("script");0<scripts.length&&scripts.each(function(){eval($(this).html())}),!0===$.qtWebsiteObj.fn.initializeAfterAjax()?($.qtWebsiteObj.fn.initializeVisualComposerAfterAjax(),$(".wp-playlist").each(function(){return new WPPlaylistView({el:this})}),atAplPreloader.removeClass("qt-visible"),qtAplMaincontent.fadeTo("fast",1).promise().done(function(){
// After reloading we scroll till the place of the anchor
// Since 2019 04 18 + support internal links
var t=link.split("#"),e=!1;if(1<t.length){var a=$("#"+t[1]);if(0<a.length){var s=a.offset().top;return void $("html, body").animate({scrollTop:s},1500,"swing")}}}),
// Reload woocommerce scripts
/**
								 * Skip ajax for WooCommerce endpoints
								 * Scripts are listed from qt-kentha-ajax-pageload/_woocommerce-support.php 
								 * PHP function qt_ajax_pageload_wc_script_reload
								 */
$.each($("#qt-ajax-pageload-woocommerce-scripts").data(),function(t,e){$.getScript(e)})):window.location.replace(link)})):window.location.replace(link)},error:function(){
//Go to the link normally
window.location.replace(link)}}),!0}
/**
		 * Manage browser back and forward arrows
		 */
// return;
$("body").off("click","a"),
/**
		 * [Bind click function to all the links]
		 */
$("body").on("click","a",function(a){var t=$(this),s=$(this).attr("href");if(void 0===s)return a;if(""===s)return a;
/**
			 * Skip ajax for WooCommerce endpoints
			 */$.each($("#qt-ajax-pageload-woocommerce-urls").data(),function(t,e){if(s===e)
// alert('WooCommerce endpoint');
return a});
/**
			 * [exceptions that will skip ajax loading]
			 */
var e=/(\/respond|\/wp-admin|mailto:|\.zip|\.jpg|\.gif|\.mp3|\.pdf|\.png|\.rar|#noajax|noajax|download_file)/;if(t.hasClass("ajax_add_to_cart")||t.parent().hasClass("noajax")||!s.match(document.domain)||"_blank"===t.attr("target")||t.hasClass("noajax")||"submit"===t.attr("type")||"button"===t.attr("type")||s.match(e))
// alert('Non ajax loading for this link');
return a;if(s.match(document.domain)){if(a.preventDefault(),window.history.pushState){var o=s;o!==window.location&&window.history.pushState({path:o,state:"new"},"",o)}
/**
				 * Close the sidebar and player
				 */$(".button-collapse").sideNav("hide"),$(".button-playlistswitch").sideNav("hide"),$("li.current_page_item").removeClass("current_page_item"),t.closest("li").addClass("current_page_item"),atAplPreloader.addClass("qt-visible"),qtAplMaincontent.fadeTo("fast",0,function(){$.fn.qtAplScrollTop()}).promise().done(function(){qtAplExecuteAjaxLink(s)})}}),$(window).on("popstate",function(t){var e;t.originalEvent.state,void 0!==(e=location.href)&&(e.match(document.domain)?qtAplMaincontent.fadeTo("fast",0,function(){$.fn.qtAplScrollTop()}).promise().done(function(){qtAplExecuteAjaxLink(e)}):window.location.replace(e))})},// $.fn.qtAplInitAjaxPageLoad
/**====================================================================
	 *
	 *	Page Ready Trigger
	 * 	This needs to call only $.fn.qtInitTheme
	 * 
	 ====================================================================*/
jQuery(document).ready(function(){$.fn.qtAplInitAjaxPageLoad()})}(jQuery);
//# sourceMappingURL=qt-kentha-ajax-pageload-min.js.map