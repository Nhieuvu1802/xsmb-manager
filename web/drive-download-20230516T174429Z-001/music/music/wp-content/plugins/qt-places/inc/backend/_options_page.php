<?php
/* = Create options page
=============================================================*/

add_action('admin_menu', 'qtMAPS_create_optionspage');

if(!function_exists('qtMAPS_create_optionspage')){
function qtMAPS_create_optionspage() {
	add_options_page('QT Places', 'QT Places', 'manage_options', 'qtMAPS_settings', 'qtMAPS_options');
}
}



if(!function_exists('qtMAPS_options')){
function qtMAPS_options() {
	if (!current_user_can('manage_options'))  {
		wp_die( __('You do not have sufficient permissions to access this page.') );
	}
?>
<img class="qt-logo-big" src="<?php echo plugins_url( 'assets/logo.png' , __FILE__ ); ?>" />
<div class="wraps">

    <form method="post" id="SettingsForm" class="qantumthemes_form" action="<?php echo $_SERVER["REQUEST_URI"]; ?>">

    	<h2>Important: how to create your Google Maps API key</h2>
	<p>Please read carefully the instructions here and compile the Google Maps API key below</p>
	<p><a href="https://developers.google.com/maps/documentation/javascript/get-api-key" target="_blank">https://developers.google.com/maps/documentation/javascript/get-api-key</a></p>

        <?php 
			echo qt_create_maps_settings();
		?>
		<p class="submit">
		<input type="submit" name="submit" value="<?php _e('Update options &raquo;'); ?>"  class="button button-primary button-large" />
		</p>
    </form>
    <div class="qtspanel">
    	<h2>Instructions</h2>
    	<p>You can add the shortcode simply clicking the QT Places button in the text editor, or write it directly.</p>
    	<p>To fast display the places, you can simply add <strong>[qtplaces]</strong></p>
    	<h2>Express Shortcode</h2>
    	<p>[qtplaces]</p>
    	<h2>Complete Shortcode</h2>
    	<p>
    	[qtplaces mapid="" template="1" open="1" limit="" mapheight="500" mapheightmobile="" autozoom="1" streetview="1" getdirections="Open in Google Maps" mapcolor="normal" listimages="1" showfilters="1" posttype="place" taxonomy="pcategory" terms="" debug="0" mousewheel="0" buttoncolor="" buttonbackground="" listbackground="" markercolor=""]
    	</p>
	    <h2>Shortcode attributes</h2>
	    <table class="qtsparameters">
	    	<tr>
	    		<th><?php  echo esc_attr("Shortcode attribute", "qt-places"); ?></th>
	    		<th><?php  echo esc_attr("Type", "qt-places"); ?></th>
	    		<th><?php  echo esc_attr("Default", "qt-places"); ?></th>
	    		<th><?php  echo esc_attr("Usage", "qt-places"); ?></th>
	    	</tr>
	    	<tr>
		    	<td>autozoom</td>
	    		<td>boolean</td>
	    		<td>false</td>
	    		<td><?php  echo esc_attr("Set to 1 to zoom a location when clicking a marker", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>background</td>
	    		<td>boolean</td>
	    		<td>1</td>
	    		<td><?php  echo esc_attr("Show background images in the list", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>buttoncolor</td>
	    		<td>string</td>
	    		<td></td>
	    		<td><?php  echo esc_attr("Text Hex color for the buttons, like #FFFFFF", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>buttonbackground</td>
	    		<td>string</td>
	    		<td></td>
	    		<td><?php  echo esc_attr("Background color for the buttons, like #FF0000", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>debug</td>
	    		<td>boolean</td>
	    		<td>false</td>
	    		<td><?php  echo esc_attr("In case of issues, set to 1 or true to display the query", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>getdirections</td>
	    		<td>string</td>
	    		<td>Get directions</td>
	    		<td><?php  echo esc_attr("String used for the link to get the directions. In mobile opens the navigation. Leave empty to hide the link", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>limit</td>
	    		<td>integer</td>
	    		<td>-1</td>
	    		<td><?php  echo esc_attr("Max number of results. -1: show all the listings", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>listimages</td>
	    		<td>boolean</td>
	    		<td>1</td>
	    		<td><?php  echo esc_attr("Show background images in the list", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>listbackground</td>
	    		<td>string</td>
	    		<td></td>
	    		<td><?php  echo esc_attr("Backgorund color for the list items, like #FF0000", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>mapcolor</td>
	    		<td>dark|light|normal</td>
	    		<td>dark</td>
	    		<td><?php  echo esc_attr("Map color", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>mapheight</td>
	    		<td>integer</td>
	    		<td>500</td>
	    		<td><?php  echo esc_attr("Map height (desktop)", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>mapheightmobile</td>
	    		<td>integer</td>
	    		<td>400</td>
	    		<td><?php  echo esc_attr("Map height (mobile)", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>mapid</td>
	    		<td>string</td>
	    		<td>(random if empty)</td>
	    		<td><?php  echo esc_attr("ID of the map. Use only letters. if empty, a random string is used.", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>mousewheel</td>
	    		<td>boolean</td>
	    		<td>false</td>
	    		<td><?php  echo esc_attr("Set to 1 to enable mouse wheel zooming", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>markercolor</td>
	    		<td>string</td>
	    		<td></td>
	    		<td><?php  echo esc_attr("Backgorund color for the map markers, like #FF0000", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>open</td>
	    		<td>boolean</td>
	    		<td>false</td>
	    		<td><?php  echo esc_attr("If using templates 2 or 3, set open to 1 if you want the menu to be open when loading the page", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>posttype</td>
	    		<td>string</td>
	    		<td>place</td>
	    		<td><?php  echo esc_attr("Post type used to extract the listing. Must be enabled in the settings.", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>showfilters</td>
	    		<td>boolean</td>
	    		<td>1</td>
	    		<td><?php  echo esc_attr("Display filters", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>streetview</td>
	    		<td>boolean</td>
	    		<td>false</td>
	    		<td><?php  echo esc_attr("Set to 1 enable the street view function", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>template</td>
	    		<td>integer</td>
	    		<td>1</td>
	    		<td><?php  echo esc_attr("Set 1, 2 or 3 to change map design.", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>taxonomy</td>
	    		<td>string</td>
	    		<td>pcategory</td>
	    		<td><?php  echo esc_attr("Taxonomy to use for the filters, to display only items within a certain taxonomy", "qt-places"); ?></td>
	    	</tr>
	    	<tr>
		    	<td>terms</td>
	    		<td>array of integers</td>
	    		<td></td>
	    		<td><?php  echo esc_attr("Use the ids of the taxonomy to filter the results, like this: 192,32,45", "qt-places"); ?></td>
	    	</tr>
	    	
	    	
	    </table>
	    <h2>Support</h2>
	    <p>For support please visit our helpdesk: <a href="http://qantumthemes.com/helpdesk">http://qantumthemes.com/helpdesk</a></p>
    </div>
    <div class="qtspanel signpanel">
    	<a href="http://www.qantumthemes.com/" target="_blank">
		<img src="<?php echo plugins_url( 'qantum-logo-web.png' , __FILE__ ); ?>" />
		</a>
		<div class="canc"></div>
    </div>
</div>
<?php 
}
}
