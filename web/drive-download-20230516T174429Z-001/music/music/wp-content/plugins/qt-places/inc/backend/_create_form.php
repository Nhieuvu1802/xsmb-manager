<?PHP
/**
 *
 *	Admin settings page
 *
 *
 *
 *
 * 
 */

/*

____________________ CICLO PER LA GENERAZIONE DEI FORM E PER IL SALVATAGGIO ______________________
*/

if (!function_exists('qt_create_maps_settings')){
function qt_create_maps_settings(){
	$QTMAPS_opt_form = '';
	$error='';
	$QTMAPS_varnames=array(	  
        array('submaticGeneral', __('General settings',"qt-places")	,'section'),
        array('qtmap_associated_types' ,__('Add map capabilities to the following types',"qt-places")	,'typeselect'),
		array('',''	,'sectionclose'),


		array('submaticGeneral', __('Google Mapr API settings',"qt-places")	,'section'),
        array('qtGoogleMapsApiKey',__('Google Maps API Key (mandatory) <a target="_blank" href="https://console.developers.google.com/apis">https://console.developers.google.com/apis</a>',"qt-places")	,'text'),
        array('qtmap_disable_googlemaps',__('Disable Google Maps script (Set YES if the theme or other plugins are already loading it)',"qt-places")	,'bol'),
        array('qtmap_disable_googlemapsjs',__('Disable Google Maps JS API (Set YES if the theme or other plugins are already loading it)',"qt-places")	,'bol'),
		array('',''	,'sectionclose'),
	);

	/**
	 *
	 *
	 *	ATTENTION WE SAVE THE POST TYPE HERE!
	 *
	 * 
	 */
	$args = array(
	   'public'   => true,
	   '_builtin' => false
	);
	$post_types = get_post_types( $args, 'names' ); 
	$post_types[] = 'post';
	$post_types[] = 'page';
	if(isset($_POST['qtmap_associated_types'])){
		foreach ( $post_types as $post_type ) {
			$typename_var = 'qtmaps_typeselect_'.$post_type;
			if(isset($_POST[$typename_var])){
				if($_POST[$typename_var] == "1")
				update_option($typename_var,"1");
			}else {
				update_option($typename_var,"");
			}
		}
	}


	/**
	 *
	 *
	 *	SAVING AND FORM CREATION
	 *
	 * 
	 */
	foreach($QTMAPS_varnames as $bv){			//1_salvataggio delle variabili // variables saving to db
			//echo '-> '. $bv[0].' - '.get_option($bv[0]).' - '.$_POST[$bv[0]].'<br />';
			
			if(isset($_POST[$bv[0]])){
				if(!update_option($bv[0],$_POST[$bv[0]])){
					$error.='<br />Error updating variable ';
				}
			}
			//2_generazione del form delle opzioni
		switch ($bv[2]){
			case 'section':
			  	$QTMAPS_opt_form.='<div class="submatic-section open" id="'.$bv[0].'"><h3>'.$bv[1].'</h3>
			  	<div class="submatic-sectioncontent">'; 
			  	break;
			case 'sectionclose':
			  	$QTMAPS_opt_form.='</div></div>'; 
				break;
			case 'color':
			 	$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong><br />';
			  	$QTMAPS_opt_form.='<input type="text" class="meta_box_color" size="100" name="'.$bv[0].'" value="'.get_option($bv[0]).'" />'; 
				break;
			case 'number':
			 	$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong><br />';
			  	$QTMAPS_opt_form.='<input type="number"   name="'.$bv[0].'" value="'.get_option($bv[0]).'" min="'.$bv[3].'" max="'.$bv[4].'" />'; 
				break;
			case 'bol':
			 	$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong><br />';
				$QTMAPS_opt_form.=' <input style="" type="radio" name="'.$bv[0].'" value="1" ';
				if(get_option($bv[0])=='1'){$QTMAPS_opt_form.=' checked = "checked" ';}
				$QTMAPS_opt_form.=' />  Yes '; 
				$QTMAPS_opt_form.='<input style="" type="radio" name="'.$bv[0].'" value="0" ';
				if(get_option($bv[0])=='0'){$QTMAPS_opt_form.=' checked = "checked" ';}
				$QTMAPS_opt_form.=' /> No </p>'; 
				break;
			case 'typeselect':
				$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong></p>';
				$args = array(
				   'public'   => true,
				   '_builtin' => false
				);
				$post_types = get_post_types( $args, 'names' ); 
				$post_types[] = 'post';
				$post_types[] = 'page';
				foreach ( $post_types as $post_type ) {
					if($post_type == 'event' || $post_type == 'place'){
						continue;
					}
					$QTMAPS_opt_form.='
					<p><input type="checkbox" value="1" name="qtmaps_typeselect_'.$post_type.'"  ';

					if(get_option('qtmaps_typeselect_'.$post_type) == '1'){
						$QTMAPS_opt_form.=' checked = "checked" ';
					}

					$QTMAPS_opt_form.=' >'.$post_type.'</p>';
				   
				}
				// we add a hidden field just to tell to save these fields
				$QTMAPS_opt_form.='<input type="hidden" name="'.$bv[0].'" value="qtmaps" />'; 
				break;
		case 'textarea':
		 	$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong><br />';
			$QTMAPS_opt_form.='<textarea name="'.$bv[0].'" id="'.$bv[0].'" rows="10" cols="50" >'.get_option($bv[0]).'</textarea>'; 
			break;
		case 'static':
			break;
		default:
			$QTMAPS_opt_form.='<p class="submatic-title"><strong>'.$bv[1].'</strong><br />';
		  	$QTMAPS_opt_form.='<input type="text" size="100" name="'.$bv[0].'" value="'.get_option($bv[0]).'" />'; 
		}	
	}
	return $QTMAPS_opt_form;
}}

?>