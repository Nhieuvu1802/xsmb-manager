=== Kentha ===
Contributors: QantumThemes
Requires at least: WordPress 5.4
Tested up to: WordPress 5.5.1
Version: 2.2.8
Tags: two-columns, right-sidebar

== Description ==
Kentha: professional music WordPress theme

* Mobile-first, Responsive Layout
* Custom Colors
* Custom Header
* Social Links
* Post Formats
* The GPL v2.0 or later license.

== Installation ==
1. Login to your website in /wp-admin
2. Go to Appearance > Themes
3. Click Install Themes and then Upload
4. Click on the “Browse” button and select the zipped folder of the theme from your computer.
5. Upload the theme called kentha.zip but DO NOT ACTIVATE IT
6. Once done click on “Return to themes”
6. Click “add new” and upload the theme kentha-child.zip
7. Activate kentha-child.zip
8. Install the required plugins (http://qantumthemes.xyz/manuals/kentha/knowledge-base/required-plugins-installation/)


== Documentation ==
http://qantumthemes.xyz/manuals/kentha/

== Copyright ==
Kentha WordPress Theme, Copyright 2018 QantumThemes.xyz

== Developers info ==

* ===================================================================
* 
* IMPORTANT INFO FOR DEVELOPERS AHEAD:
*
* ===================================================================
* 
* If the debugger is disabled in the wp customizer and you don't have any library conflict
* this loads a minified JS file containing all the libraries (excluding the WP default ones)
* as per Envato quality requirements. 
* 
* ===================================================================
*
* This is the list of js included in the framework materialize-src/js/bin/materialize.min.js
* ---
* components/modernizr/modernizr-custom.js
* components/materialize-src/js/initial.js
* components/materialize-src/js/global.js
* components/materialize-src/js/velocity.min.js
* components/materialize-src/js/animation.js
* components/materialize-src/js/sideNav.js
* components/materialize-src/js/hammer.min.js
* components/materialize-src/js/jquery.hammer.js
* components/materialize-src/js/collapsible.js
* components/materialize-src/js/jquery.easing.1.3.js
* components/materialize-src/js/tabs.js
* components/materialize-src/js/forms.js
* components/materialize-src/js/slider.js
* components/materialize-src/js/dropdown.js
*
* NON MATERIALIZE SCRIPTS INCLUDED IN MINIFIED FILE QT-MAIN-MIN.JS:
* ---
* components/slick/slick.min.js
* components/skrollr/skrollr.min.js
* components/raphael/raphael.min.js
* components/ytbg/src/min/jquery.youtubebackground-min.js

== Changelog ==

2.2.8 [2020 September 19]
[x] ADMIN: Now plugin updates are not dismissable anymore, because of users disabling the message and complaining for having outdated plugins
[x] TGMPA Dismiss link removed 'dismiss'  => $this->dismissable 
[x] TGM REMOVED LINE 1111 class-tgmpa-plugin-activation.php // || get_user_meta( get_current_user_id(), 'tgmpa_dismissed_notice_' . $this->id, true ) 
[x] UPDATED WPBakery to 6.4.0
[x] UPDATED Envato Market plugin
[x] FIXED Demo 10 data for home page search box align
[x] UPDATED AND IMPROVED WooCommerce Royalty Free shop products playlist adding Music genre when playing tracks and fixed duplicated track title


2.2.7 [2020 September 05]
[x] Player udpate for iOS 13.5
[x] WooCommerce templates updates
[x] CSS updates for player


2.2.6 [2020 August 12]
[x] Updated plugin TTG Core for wp 5.5
[x] Updated plugin QT Places for wp 5.5. Please udapte your plugins
No changes were made to the theme.


2.2.5 [2020 August 04]
[x] Remote.php check plugins only in the installation page (avoid multiple connections)



2.2.4 [2020 June 23]
[x] WooCommerce table min width
[x] WooCommerce update
[x] Remove duplicated button if is a variable product kentha/woocommerce-helpers/kentha-woocommerce-moreinfo.php


2.2.3 [2020 May 13]
[x] Plugins versions

2.2.2 [2020 May 12]
[x] Software title in part-archivetitle.php
[x] ADDED More Info button in tracks playlist WooCommerce
[x] UPDATED WPBakery

2.2.1 [2020 March 26]
[x] Bug fix functions.php:1204 removed

2.1.9 [2020 March 18]
[x] ADDED support for HTTP shoutcast for KenthaRadio [single-radiochannel.php, part-playlist-radio.php and shortcode-playbutton.php]

2.1.8 [2020 March 08]
[x] ADDED link to artist in product track template and single product details
[x] UPDATED: Qt-Swipebox plugin: fixed touch event issue clicking behind the close button
[x] UPDATED WooCommerce compatibility tempaltes
[x] REMOVEC Revo Slider update nag

2.1.7 [2020 February 18]
[x] single-event.php: removed Coming Soon text for past events and added better artist search

2.1.6 [2020 February 14]
[x] FIXED Album and playlist linking for releases on part-playlist.php

2.1.5 [2020 February 12]
[x] FIXED pagination

2.1.4 [2020 January 31]
[x] ADDED software taxonomy to products, visible only after enabling the Single tracks option
[x] ADDED Software taxonomy thumbnail
[x] ADDED Software thumbnail to the "product track" list and "product track" cards
[x] ADDED Software detail in the single track detail table
[x] ADDED Track products tab in artist single pages
[x] ADDED custom template for the Software taxonomy
[x] ADDED new shortcode Product Search in Page Builder
[x] FIXED availability output for Ghost tracks products (with stock management)
[x] UPDATED WooCommerce templates for version 3.9
[x] added part-pagination-tracklist.php
[x] CSS reduced cards shadow size
[x] UPDATED Kentha Music Player plugin
[x] CSS WooCommerce audio products styles improved
[x] IMPROVED WooCommerce tracks
[x] FIXED conflict on Video Background with WPBakery Page Builder 6.1
[x] REMOVED youtube iframe api hard enqueue in jquery.yourubebackground.js
[x] REMOVED foceful enqueuing of youtube api in functions.php
[x] ADDED getScript for iframe_api in jquery.yourubebackground.js  version 1.0.6 


2.0.2 [2020 January 07]
[x] Page Builder update
[x] Fixed WooCommerce slideshows compatibility issue

2.0.1 [2019 December 11]
[x] Fixed stock check on files
phpincludes/part-archive-item-product-singletrack-card.php
phpincludes/part-archive-item-product-singletrack-small.php
phpincludes/part-archive-item-product-singletrack.php


2.0.0 [2019 December 03]
[x] ADDED: WooCommerce: "music genre" "taxonomy
[x] ADDED: WooCommerce: "Single Track" checkbox option to product fields
[x] ADDED: WooCommerce: "royalty type" taxonomy
[x] ADDED: WooCommerce: product artist, label, BPM and duration options (for single track products)
[x] ADDED: Page Builder: shortcode for Single Track products lists
[x] ADDED: Page Builder: shortcode for Single Track products lists small (variant)
[x] ADDED: Page Builder: shortcode for Single Track products cards
[x] ADDED: customizer WooCommerce settings for Single Track shop
[x] ADDED: documentation Single Track Product section
[x] UPDATED PLUGIN Kentha Player
[x] UPDATED PLUGIN Ajax Page Loader

1.7.3 [2019 October 07]
[x] WPBakery Page Builder update 

1.7.2 [2019 August 31]
[x] support link fix in tgm conf.php
[x] WPBakery Page Builder update 

1.7.1 [2019 July 04]
[x] UPDATED Plugin QT ServerCheck: now working also on GoDaddy and other providers
[x] UPDATED Purchase Code authentication url for better hsoting compatibility

1.7.0 [2019 June 27]
[x] UPDATED: TGM Framework
[x] ADDED Authentication screen
[x] ADDED New demo import screen
[x] REMOVED theme dashboard

1.6.3 [2019 June 24]
[x] UPDATED: plugins

1.6.2 [2019 June 17]
[x] UPDATED: Kentha music player plugin [playlist issue]
[x] UPDATED WPBakery Page Builder 

1.6.1 [2019 June 04 open]
[x] UPDATED functions.php to allow hide old events in default archives 

1.6.0 [2019 May 27] 
[x] UPDATED Ajax Page Load plugin for Page Builder compatibility

1.5.9 [2019 May 23] 
[x] UPDATED Music Player
[x] ADDED template podcast item mini
[x] ADDED direct podcast play to player
[x] FIXED player bug playing same track on page change
[x] ADDED podcasts tab in single artist
[x] ADDED podcast list by artist name in functions.php
[x] UPDATED WooCommerce compatibility to 3.6.2
[x] UPDATED Page Builder to 6.0.2

1.5.8 [2019 April 18] 
[x] UPDATED WooCommerce compatibility to 3.6.1
[x] UPDATED Music Player

1.5.7 [2019 April 03] 
[x] IMPROVED page Builder ajax compatibility for video backgrounds
[x] REMOVED social icon google plus
[x] ADDED popup libraries and initialization for sharing to fix lightbox pinterest
[x] UPDATED plugin Kentha Share

1.5.6 [2019 February 13]
[x] UPDATED Revo Slider and Page Builder

1.5.5 [2019 February 05]
[x] UPDATED js soundcloud height fix

1.5.4 [2019 January 17]
[x] UPDATED plugin Kentha Player

1.5.3 [2019 January 11]
[x] UPDATED Kentha Radio plugin compatibility
[x] IMPROVED responsivity for soundcloud embedded in charts tracklist
[x] UPDATED plugin Kentha Widgets to 1.0.7 (now supporting hide past events)
[x] UPDATED plugin Kentha Player to 1.9.5
    * ADDED track delete button (desktop only, no space in mobile)
    * ADDED preload spinner on first load for better user experience
    * FIXED chrome audio policy for chrome 71
[x] ADDED custom types to Rest API

1.5.2 [2018 December 19]
[x] UPDATED Kentha Player to fix compatibility with Chrome 71 and music spectrum analyzer

1.5.1 [2018 December 10]
[x] Fixed CSS alignment with ellipsis
[x] Fixed php issue in part-lineup.php

1.5.0 [2018 December 08]
[x] UPDATED WooCommerce compatibility to 3.5.2
[x] UPDATED Page Composer (Visual Composer) 5.6
[x] UPDATED to Wordpress 5.0
[x] ADDED Classic Editor plugin
[x] ADDED Chart Voting plugin for KenthaRadio plugin (separate product)

1.4.1 [2018 November 28]
[x] UPDATE phpincludes/part-playlist-radio.php
[x] UPDATE template name in archive-radiochannel.php

1.4.0 [2018 October 29]
[x] UPDATE Page Builder plugin to 5.5.5
[x] UPDATE QT Places to 1.8.1
[x] UPDATE Kentha contact form
[x] UPDATE Kentha for WooCommerce 3.5.0


1.3.9 [2018 September 17]
[x] UPDATE Page Builder plugin to latest version
[x] UPGRADE Open player when loading a new track
[x] UPGRADE Podcast added download link 
[x] UPGRADE Podcast added icon option link 
[x] UPGRADE Podcast added price link
[x] UPGRADE Internal menu smoothscroll (HOW-TO: edit menu, enable CSS classes, add "smoothscroll noajax")
[x] FIXED Soundcloud podcast too high in single podcast page 
[x] FIXED Podcast and release main artist now appears also if there is no artist with this name in database
[x] FIXED Secondary layer some items in mobile may go under the player
[x] FIXED Play next on track finish (mobile) 
[x] FIXED Shortcode playlist added price attribute


1.3.8 [28 August 2018]
[x] Added new social icons: Blogger, Skype, RSS, Linkedin
[x] Updated Envato market plugin
[x] Updated plugins repository URL

1.3.7 [06 August 2018]
[x] UPDATED Player plugin (removed double price) to Kentha Player v. 1.9.1

1.3.6 [03 August 2018]
[x] ADDED playlist manager in customizer, manage releases, podcast and custom playlists
[x] ADDED  podcast  in player
[x] ADDED track prices in playlist 
[x] ADDED shortcode: interactive card grids
[x] UPDATE kentha player to 1.9.0 in tgm: better performance while idle
[x] UPDATE TTG Core to 1.3.2 in tgm

1.3.5 [20 July 2018]
[x] FIXED short gallery multimedia fixed undefined index title
[x] ADDED template " Blog cards with sidebar"
[x] FIXED WooCommerce loading icon positioning in buttons
[x] FIXED WooCommerce php7.2 compatibility
[x] INTERNATIONALIZED DATE part-event-inline-compact.php
[x] INTERNATIONALIZED DATE part-related.php
[x] UPDATED QT Ajax Pageload plugin to add exclusion class for menu items
[x] UPDATED CSS qt-woocommerce.css (.product h2)

1.3.4 [02 July 2018]
[x] FIXED internationalization of date in part-event-inine.php
[x] UPDATED QT Ajax Pageload plugin to fix regex

1.3.3 [28 June 2018]
[x] FIXED WooCommerce dropdowns 
[x] UPDATED QT Ajax Pageload plugin to fix WooCommerce product download
[x] UPDATED Slider Revolution plugin
[x] UPDATED Page Builder plugin


1.3.2 [07 June 2018]
[x] UPDATED plugins

1.3.1 [03 June 2018]
[x] IMPROVED artist releases query in functions.php


1.3.0 [03 June 2018]
[x] ADDED WooCommerce custom field "playlist" to add tracks from existing album
[x] ADDED WooCommerce function buy link playlist normal e drop-in product
[x] ADDED WooCommerce function buy link ajax added in "listen on" in right sidebar
[x] ADDED WooCommerce function event buy link in header and sidebar ajax add to cart support added
[x] ADDED WooCommerce function release buy link in header and sidebar ajax add to cart support added
[x] ADDED WooCommerce shortcode styling
[x]	ADDED WooCommerce products shortcode
[x] ADDED WooCommerce flash sale icon
[x] ADDED WooCommerce added layout columns option in customizer
[x] ADDED WooCommerce cart menu
[x] ADDED WooCommerce product page
[x] ADDED WooCommerce search widget
[x] ADDED WooCommerce price range widget
[x] ADDED WooCommerce added product slideshow shortcode
[x] ADDED WooCommerce added cart action to chart tracks
[x] ADDED Privacy field comment form
[x]	ADDED Playlist shortcode kentha-playlist [kentha-playlist id=""]
[x] IMPROVED artist release better accuracy
[x]	ADDED new shortcode SOCIAL ICONS
[x] ADDED new shortcode CUSTOM PLAYLIST in Visual Composer
[x] ADDED interaction buttons in ALBUM ARCHIVE SMALL
[x] UPDATED .pot
[x] UPDATED Ajax Plugin rar regex
[x] UPDATED Kentha Player Plugin to 1.8.5 with fixes for Chrome 66
[x] PLAYER: HIDE IF NO RELEASES + ADD PLAYER IN LANDING PAGE TO ACTIVATE AUTOPLAY
[x] UPDATED Documentation manual (Shortcode)

1.2.2 [16 may 2018]
* UPDATED KenthaPlayer
* ADDED basic WooCommerce support. Will provide a much wider and cooler support in next theme release. 
	- This one was in rush due to new Chrome policies about audio that forced us to make a new player

1.2.1 [07 may 2018]
* UPDATED plugins folder

1.2.0 [02 may 2018] *** REQUIRES PLUGINS UPDATE ***

This update also adds the support for the upcoming Kentha Radio plugin.
The radio support won't add any extra weight for the websites not using this plugin.

HOW TO UPDATE PROPERLY:
https://qantumthemes.xyz/manuals/kentha/knowledge-base/how-to-update-the-theme/

[x] ADDED QT Places archive template
[x] ADDED Event: create artists manually in the lineup
[x] ADDED Single artist: Tab events with automated list of events(from event lineup)
[x] ADDED KUVO social also to artists
[x] ADDED Events logo in header
[x] ADDED Video manuals
[x] ADDED New demo 8
[x] ADDED Support for upcoming Kentha Radio plugin
[x] FIX 404 page colors and added default background
[x] FIX Customizer letter spacing .qt-btn fix
[x] FIX empty buttons creating buy link and deleting them in events and releases
[x] UPDATE DOCUMENTATION: how to manually add an artist to event lineup
[x] UPDATED Kentha Player Plugin

1.1.5 [06 Apr 2018]
[x] Customizer: add Hi Quality Parallax option in general
[x] New parallax Hi Quality function
[x] Add 3d release PSD pack
[x] Updated Contact Form 7 css for fropdown and select fields
[x] customizations.php:120 updated menu color selectors
[x] functions.php added browser recognition
[x] functions.php added custom social icons for author


1.1.4 [27 Mar 2018]
[x] Comments text fix
[x] Code tag fix
[x] Header effect option added


1.1.3 [21 Mar 2018]
[x] Comment cancel link fix
[x] Menu padding fix
[x] Items padding fix
[x] Social links code removed from functions.php


1.1.2 [21 Mar 2018]
[x] Replaced 'if ( class_exists( 'Kirki' ) )' with  'if( !function_exists( 'ttg_core_active' ) ){ ' in functions.php l 289


1.1.1 [18 Mar 2018]
[x] Fixed tab.js library from Materialize framework https://github.com/Dogfalo/materialize/issues/2137
[x] Recompiled minified theme script

1.1.0 [16 Mar 2018]
[x] Installation process check

1.0.9 [14 Mar 2018]
[x] Removed browser recognition function.php

1.0.8 [10 Mar 2018]
[x] Page composer update
[x] escaping comments strings in comments.php


1.0.7 [07 Mar 2018]
[x] Fixed pingbacks/trackbacks
[x] Fixed pages pagination
[x] Added translatability to the 404 number in the 404 error page


1.0.6 [05 Mar 2018]
[x] Better menu widget styling
[x] PHP issue fixed in kentha-tgm-activation
[x] Off canvas shadow fix
[x] x-index improvement
[x] comments.php fix


1.0.5 [01 Mar 2018]
[x] Updated style and script handler names
[x] Updated WordPress spelling
[x] Updated Ajax and Player plugins to match the handler updates
[x] Renamed folders with inconsistent naming

1.0.4 [27 Feb 2018]
[x] Fixed translation in comments
[x] Better escaping functions
[x] Updated POT file
[x] PHP error fixed in part-background.php


1.0.3 [23 Feb 2018]
[x] Fixed validation, contrast, footer, icons, textdomain, sharing in plugin


1.0.1 [14 Feb 2018]
[x] Better parallax
[x] Improved performance
[x] Improved header animation rendering
[x] Removed animations on scroll

1.0.0 Initial release