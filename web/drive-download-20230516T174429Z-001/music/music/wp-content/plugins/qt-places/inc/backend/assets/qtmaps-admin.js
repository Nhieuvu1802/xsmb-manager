(function($){
	"use strict";

	$(".settings_page_qtMAPS_settings #SettingsForm a.submatic-tabtitle").click(function(e){
		e.preventDefault();
		var sid = $(this).attr("data-section");
		$("#SettingsForm .submatic-section").removeClass("open");
		$("#SettingsForm #"+sid).addClass("open");
	});

	jQuery(document).ready(function($){
	    $('.meta_box_color').wpColorPicker();
	});


})(jQuery);



