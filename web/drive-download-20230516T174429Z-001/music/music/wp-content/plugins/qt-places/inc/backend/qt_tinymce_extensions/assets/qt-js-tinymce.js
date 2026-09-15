// Admin Scripts for QantumThemes Functions
(function() {
    tinymce.create("tinymce.plugins.qtplaces_button_plugin", {
        init : function(ed, url) {
            ed.addButton('qtplaces', {
                type: 'button',
                text: ' QT Places',
                icon: ' wp-menu-image dashicons-before dashicons-location-alt',
                tooltip: 'Add QT Places map',
                fixedWidth: false,
                onclick: function(e) {
                    ed.focus();
                    var return_text = '[qtplaces mapid="" template="1" open="1" limit="" mapheight="500" mapheightmobile="" autozoom="1" streetview="1" getdirections="Open in Google Maps" mapcolor="normal" listimages="1" showfilters="1" posttype="" taxonomy="" terms="" debug="0" mousewheel="0" buttoncolor="" buttonbackground="" listbackground="" markercolor=""]';
                    ed.execCommand("mceInsertContent", 0, return_text);  
                },
                onPostRender: function() {
                    ed.my_control = this; // ui control element
                }
            });
        },
        createControl : function(n, cm) {
            return null;
        },
        getInfo : function() {
            return {
                longname : "Extra Buttons",
                author : "QantumThemes",
                version : "1"
            };
        }
    });
    tinymce.PluginManager.add("qtplaces_shortcodes_plugin", tinymce.plugins.qtplaces_button_plugin);
})();
