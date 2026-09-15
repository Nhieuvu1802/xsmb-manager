<?php

/* = Custom css added in html head
=============================================================*/

if(!function_exists('qtMAPS_customstylesx')){
function qtMAPS_customstylesxDISABLED(){
		$qtMAPS_overlay_color = get_option('qtMAPS_overlay_color');
		$alpha = get_option('qtMAPS_overlay_opacity');
		$titlecolor = get_option('qtMAPS_title_color');
		$qtMAPS_tags_color = get_option('qtMAPS_tags_color');
		$qtMAPS_filters_color = get_option('qtMAPS_filters_color');
		$qtMAPS_filters_bordercolor = get_option('qtMAPS_filters_bordercolor');
		$qtMAPS_filters_bordershape = get_option('qtMAPS_filters_bordershape');
		$qtMAPS_filters_fontsize = get_option('qtMAPS_filters_fontsize');
		$qtMAPS_title_size_mobile = get_option('qtMAPS_title_size_mobile');
		$qtMAPS_filters_bgcolor = get_option('qtMAPS_filters_bgcolor');
		$qtMAPS_filters_bgcolorh = get_option('qtMAPS_filters_bgcolorh');
		$qtMAPS_preview_background = get_option('qtMAPS_preview_background');
		$qtMAPS_preview_text_color = get_option('qtMAPS_preview_text_color');
		$qtMAPS_preview_buttons_color = get_option('qtMAPS_preview_buttons_color');
		$qtMAPS_preview_buttons_color_h = get_option('qtMAPS_preview_buttons_color_h');
			
		echo '
		<!-- CSS styles added by QT Map Plugin -->
		<style type="text/css">
			'.(($qtMAPS_overlay_color!='')? '.qtMap-subpages-item  a .detail {background: rgba('.qtHexToRGBA(get_option('qtMAPS_overlay_color')).','.(($alpha != '')? (get_option('qtMAPS_overlay_opacity')/100) : ".8").') !important;} ':'').'
			.qtMap-subpages-item  a .detail .title {font-size:'.get_option( 'qtMAPS_title_size', "13" ).'px; '.(($titlecolor!='')? ' color:'.$titlecolor.' !important;':'').'}
			'.(($qtMAPS_tags_color != '')? ".qtMap-subpages-item  a .detail p.trmlist span.trm {border-color:".$qtMAPS_tags_color ." !important;color:".$qtMAPS_tags_color ."!important;}" : "").'
			.qtMap-subpages-item  a .detail {padding-top:'.get_option( 'qtMAPS_hover_top', "45" ).'px !important;}
			.qtMap-subpages-container ul.qtMap-subpages-tagcloud li a {
				'.(($qtMAPS_filters_fontsize != '')? "font-size:".$qtMAPS_filters_fontsize."px;" : "").'
				'.(($qtMAPS_filters_color != '')? "color:".$qtMAPS_filters_color .";" : "").'
				'.(($qtMAPS_filters_bgcolor != '')? "background-color:".$qtMAPS_filters_bgcolor .";" : "").'
				'.(($qtMAPS_filters_bordercolor != '')? "border-color:".$qtMAPS_filters_bordercolor ."; " : "").'
				'.(($qtMAPS_filters_bordershape != '')? "border-radius:".$qtMAPS_filters_bordershape ."px;" : "").'
			}
			.qtMap-subpages-container ul.qtMap-subpages-tagcloud li a:hover {'.(($qtMAPS_filters_bgcolorh != '')? "background-color:".$qtMAPS_filters_bgcolorh .";" : "").'}
			'.(($qtMAPS_preview_background != '')? ".qtMap-preview-container.open .qtMap-preview-content {background-color: ".$qtMAPS_preview_background.";}" : "").'
			'.(($qtMAPS_preview_text_color != '')? ".qtMap-preview-container.open .qtMap-preview-content {color: ".$qtMAPS_preview_text_color.";}" : "").'
			'.(($qtMAPS_preview_buttons_color != '')? ".qtMap-preview-container.open .qtMap-preview-prev,.qtMap-preview-container.open .qtMap-preview-next,.qtMap-preview-container .qtMap-preview-content a.qtMap-project-link, .qtMap-preview-content::-webkit-scrollbar-thumb {background-color: ".$qtMAPS_preview_buttons_color." !important;}
			  img.qtMap-imgpreview {border-color:".$qtMAPS_preview_buttons_color." !important;} " : "").'
			'.(($qtMAPS_preview_buttons_color_h != '')? ".qtMap-preview-container.open a.qtMap-preview-prev:hover, .qtMap-preview-container.open a.qtMap-preview-next:hover, .qtMap-preview-container .qtMap-preview-content a.qtMap-project-link:hover {background-color: ".$qtMAPS_preview_buttons_color_h." !important;}" : "").'
			@media (max-width: 768px){
				.qtMap-elementcontents a.qtMap-link .detail .title {'.(($qtMAPS_title_size_mobile != '')? "font-size:".$qtMAPS_title_size_mobile."px;" : "").'}
			}
			'.get_option('qtMAPS_customcss').'
		</style>
		';	
	}
}
//add_action('wp_head','qtMAPS_customstylesx',99999999);