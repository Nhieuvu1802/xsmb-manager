(function($) {
	"use strict";

	/**
	 * [Main ajax initialization function]
	 */
	$.qtKenthaPreloader = {
		init: function(){
			var body = $('body');
			body.append('<div id="qtkenthapreloader" class="qt-kenthapreloader-window"><div class="qt-kenthapreloader-icon qt-visible"><div class="preloader-wrapper big active"><div class="spinner-layer spinner-white-only"><div class="circle-clipper left"><div class="circle"></div></div><div class="gap-patch"><div class="circle"></div></div><div class="circle-clipper right"><div class="circle"></div></div></div></div></div></div>');
			$(window).load(function() {
				body.removeClass('qt-body-preloading').delay(500).promise().done(function(){
					$("#qtkenthapreloader").addClass('qt-done');	
				});
			});
		}
	};

	/**====================================================================
	 *
	 *	Page Ready Trigger
	 * 	This needs to call only $.fn.qtInitTheme
	 * 
	 ====================================================================*/
	$(document).ready(function() {
		$.qtKenthaPreloader.init();
	});
})(jQuery);