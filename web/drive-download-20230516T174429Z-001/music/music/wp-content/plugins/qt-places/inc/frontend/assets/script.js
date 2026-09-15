function stripslashes(str) {
  return (str + '')
    .replace(/\\(.?)/g, function(s, n1) {
      switch (n1) {
        case '\\':
          return '\\';
        case '0':
          return '\u0000';
        case '':
          return '';
        default:
          return n1;
      }
    });
}


(function($){
	"use strict";


	/* Googl Maps Richmarker
	=================================================================*/
	if(typeof($.fn.createRichMarker) !== "function" && google.maps != undefined) {
		$.fn.createRichMarker = function(){
		    (function(){var b=true,f=false;function g(a){var c=a||{};this.d=this.c=f;if(a.visible==undefined)a.visible=b;if(a.shadow==undefined)a.shadow="7px -3px 5px rgba(88,88,88,0.7)";if(a.anchor==undefined)a.anchor=i.BOTTOM;this.setValues(c)}g.prototype=new google.maps.OverlayView;window.RichMarker=g;g.prototype.getVisible=function(){return this.get("visible")};g.prototype.getVisible=g.prototype.getVisible;g.prototype.setVisible=function(a){this.set("visible",a)};g.prototype.setVisible=g.prototype.setVisible;
		    g.prototype.s=function(){if(this.c){this.a.style.display=this.getVisible()?"":"none";this.draw()}};g.prototype.visible_changed=g.prototype.s;g.prototype.setFlat=function(a){this.set("flat",!!a)};g.prototype.setFlat=g.prototype.setFlat;g.prototype.getFlat=function(){return this.get("flat")};g.prototype.getFlat=g.prototype.getFlat;g.prototype.p=function(){return this.get("width")};g.prototype.getWidth=g.prototype.p;g.prototype.o=function(){return this.get("height")};g.prototype.getHeight=g.prototype.o;
		    g.prototype.setShadow=function(a){this.set("shadow",a);this.g()};g.prototype.setShadow=g.prototype.setShadow;g.prototype.getShadow=function(){return this.get("shadow")};g.prototype.getShadow=g.prototype.getShadow;g.prototype.g=function(){if(this.c)this.a.style.boxShadow=this.a.style.webkitBoxShadow=this.a.style.MozBoxShadow=this.getFlat()?"":this.getShadow()};g.prototype.flat_changed=g.prototype.g;g.prototype.setZIndex=function(a){this.set("zIndex",a)};g.prototype.setZIndex=g.prototype.setZIndex;
		    g.prototype.getZIndex=function(){return this.get("zIndex")};g.prototype.getZIndex=g.prototype.getZIndex;g.prototype.t=function(){if(this.getZIndex()&&this.c)this.a.style.zIndex=this.getZIndex()};g.prototype.zIndex_changed=g.prototype.t;g.prototype.getDraggable=function(){return this.get("draggable")};g.prototype.getDraggable=g.prototype.getDraggable;g.prototype.setDraggable=function(a){this.set("draggable",!!a)};g.prototype.setDraggable=g.prototype.setDraggable;
		    g.prototype.k=function(){if(this.c)this.getDraggable()?j(this,this.a):k(this)};g.prototype.draggable_changed=g.prototype.k;g.prototype.getPosition=function(){return this.get("position")};g.prototype.getPosition=g.prototype.getPosition;g.prototype.setPosition=function(a){this.set("position",a)};g.prototype.setPosition=g.prototype.setPosition;g.prototype.q=function(){this.draw()};g.prototype.position_changed=g.prototype.q;g.prototype.l=function(){return this.get("anchor")};g.prototype.getAnchor=g.prototype.l;
		    g.prototype.r=function(a){this.set("anchor",a)};g.prototype.setAnchor=g.prototype.r;g.prototype.n=function(){this.draw()};g.prototype.anchor_changed=g.prototype.n;function l(a,c){var d=document.createElement("DIV");d.innerHTML=c;if(d.childNodes.length==1)return d.removeChild(d.firstChild);else{for(var e=document.createDocumentFragment();d.firstChild;)e.appendChild(d.firstChild);return e}}function m(a,c){if(c)for(var d;d=c.firstChild;)c.removeChild(d)}
		    g.prototype.setContent=function(a){this.set("content",a)};g.prototype.setContent=g.prototype.setContent;g.prototype.getContent=function(){return this.get("content")};g.prototype.getContent=g.prototype.getContent;
		    g.prototype.j=function(){if(this.b){m(this,this.b);var a=this.getContent();if(a){if(typeof a=="string"){a=a.replace(/^\s*([\S\s]*)\b\s*$/,"$1");a=l(this,a)}this.b.appendChild(a);var c=this;a=this.b.getElementsByTagName("IMG");for(var d=0,e;e=a[d];d++){google.maps.event.addDomListener(e,"mousedown",function(h){if(c.getDraggable()){h.preventDefault&&h.preventDefault();h.returnValue=f}});google.maps.event.addDomListener(e,"load",function(){c.draw()})}google.maps.event.trigger(this,"domready")}this.c&&
		    this.draw()}};g.prototype.content_changed=g.prototype.j;function n(a,c){if(a.c){var d="";if(navigator.userAgent.indexOf("Gecko/")!==-1){if(c=="dragging")d="-moz-grabbing";if(c=="dragready")d="-moz-grab"}else if(c=="dragging"||c=="dragready")d="move";if(c=="draggable")d="pointer";if(a.a.style.cursor!=d)a.a.style.cursor=d}}
		    function o(a,c){if(a.getDraggable())if(!a.d){a.d=b;var d=a.getMap();a.m=d.get("draggable");d.set("draggable",f);a.h=c.clientX;a.i=c.clientY;n(a,"dragready");a.a.style.MozUserSelect="none";a.a.style.KhtmlUserSelect="none";a.a.style.WebkitUserSelect="none";a.a.unselectable="on";a.a.onselectstart=function(){return f};p(a);google.maps.event.trigger(a,"dragstart")}}
		    function q(a){if(a.getDraggable())if(a.d){a.d=f;a.getMap().set("draggable",a.m);a.h=a.i=a.m=null;a.a.style.MozUserSelect="";a.a.style.KhtmlUserSelect="";a.a.style.WebkitUserSelect="";a.a.unselectable="off";a.a.onselectstart=function(){};r(a);n(a,"draggable");google.maps.event.trigger(a,"dragend");a.draw()}}
		    function s(a,c){if(!a.getDraggable()||!a.d)q(a);else{var d=a.h-c.clientX,e=a.i-c.clientY;a.h=c.clientX;a.i=c.clientY;d=parseInt(a.a.style.left,10)-d;e=parseInt(a.a.style.top,10)-e;a.a.style.left=d+"px";a.a.style.top=e+"px";var h=t(a);a.setPosition(a.getProjection().fromDivPixelToLatLng(new google.maps.Point(d-h.width,e-h.height)));n(a,"dragging");google.maps.event.trigger(a,"drag")}}function k(a){if(a.f){google.maps.event.removeListener(a.f);delete a.f}n(a,"")}
		    function j(a,c){if(c){a.f=google.maps.event.addDomListener(c,"mousedown",function(d){o(a,d)});n(a,"draggable")}}function p(a){if(a.a.setCapture){a.a.setCapture(b);a.e=[google.maps.event.addDomListener(a.a,"mousemove",function(c){s(a,c)},b),google.maps.event.addDomListener(a.a,"mouseup",function(){q(a);a.a.releaseCapture()},b)]}else a.e=[google.maps.event.addDomListener(window,"mousemove",function(c){s(a,c)},b),google.maps.event.addDomListener(window,"mouseup",function(){q(a)},b)]}
		    function r(a){if(a.e){for(var c=0,d;d=a.e[c];c++)google.maps.event.removeListener(d);a.e.length=0}}
		    function t(a){var c=a.l();if(typeof c=="object")return c;var d=new google.maps.Size(0,0);if(!a.b)return d;var e=a.b.offsetWidth;a=a.b.offsetHeight;switch(c){case i.TOP:d.width=-e/2;break;case i.TOP_RIGHT:d.width=-e;break;case i.LEFT:d.height=-a/2;break;case i.MIDDLE:d.width=-e/2;d.height=-a/2;break;case i.RIGHT:d.width=-e;d.height=-a/2;break;case i.BOTTOM_LEFT:d.height=-a;break;case i.BOTTOM:d.width=-e/2;d.height=-a;break;case i.BOTTOM_RIGHT:d.width=-e;d.height=-a}return d}
		    g.prototype.onAdd=function(){if(!this.a){this.a=document.createElement("DIV");this.a.style.position="absolute"}if(this.getZIndex())this.a.style.zIndex=this.getZIndex();this.a.style.display=this.getVisible()?"":"none";if(!this.b){this.b=document.createElement("DIV");this.a.appendChild(this.b);var a=this;google.maps.event.addDomListener(this.b,"click",function(){google.maps.event.trigger(a,"click")});google.maps.event.addDomListener(this.b,"mouseover",function(){google.maps.event.trigger(a,"mouseover")});
		    google.maps.event.addDomListener(this.b,"mouseout",function(){google.maps.event.trigger(a,"mouseout")})}this.c=b;this.j();this.g();this.k();var c=this.getPanes();c&&c.overlayImage.appendChild(this.a);google.maps.event.trigger(this,"ready")};g.prototype.onAdd=g.prototype.onAdd;
		    g.prototype.draw=function(){if(!(!this.c||this.d)){var a=this.getProjection();if(a){var c=this.get("position");a=a.fromLatLngToDivPixel(c);c=t(this);this.a.style.top=a.y+c.height+"px";this.a.style.left=a.x+c.width+"px";a=this.b.offsetHeight;c=this.b.offsetWidth;c!=this.get("width")&&this.set("width",c);a!=this.get("height")&&this.set("height",a)}}};g.prototype.draw=g.prototype.draw;g.prototype.onRemove=function(){this.a&&this.a.parentNode&&this.a.parentNode.removeChild(this.a);k(this)};
		    g.prototype.onRemove=g.prototype.onRemove;var i={TOP_LEFT:1,TOP:2,TOP_RIGHT:3,LEFT:4,MIDDLE:5,RIGHT:6,BOTTOM_LEFT:7,BOTTOM:8,BOTTOM_RIGHT:9};window.RichMarkerPosition=i;
		    })();
		}
	}


	/* dynamic Maps
	=================================================================*/

	$.fn.qtPlaceDynamicMaps = function(targetContainer){
		if(targetContainer === undefined) {
			targetContainer = ".qtPlaces-container";
		}
	    var map, mapElement, myLatlng, mapOptions;
	    if(typeof google !== 'undefined'){

	        $.fn.createRichMarker();
	        var googleMapsColorLight    = [{"featureType":"water","elementType":"geometry","stylers":[{"color":"#ff0000"},{"lightness":2}]},{"featureType":"landscape","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"stylers":[{"hue":"#00aaff"},{"saturation":-100},{"gamma":2.15},{"lightness":12}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"visibility":"on"},{"lightness":24}]},{"featureType":"road","elementType":"geometry","stylers":[{"lightness":57}]}];
	        var googleMapsColorDark     = [{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":17}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":20}]},{"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#000000"},{"lightness":17}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#000000"},{"lightness":29},{"weight":0.2}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":18}]},{"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":16}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":21}]},{"elementType":"labels.text.stroke","stylers":[{"visibility":"on"},{"color":"#000000"},{"lightness":16}]},{"elementType":"labels.text.fill","stylers":[{"saturation":36},{"color":"#000000"},{"lightness":40}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":19}]},{"featureType":"administrative","elementType":"geometry.fill","stylers":[{"color":"#000000"},{"lightness":20}]},{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#000000"},{"lightness":17},{"weight":1.2}]}];
	        // Array with all the locations:
	        
	      //  google.maps.event.addDomListener(window, 'load', 
	           // function () {
	           // 
            
            $(targetContainer).each(function(i,c){

                // per ogni mappa
                var that = $(this),
                    target = that.attr("data-dynamicmap"),
                    mapcolor = that.attr("data-mapcolor"),
                    currentMapId = that.attr("id"),
                    mousewheel = that.attr("data-mousewheel"),
                    getdirections = that.attr("data-getdirections");


                var themapcolor = googleMapsColorDark;
                if (mapcolor === "light"){
                    themapcolor = googleMapsColorLight;
                }
                if (mapcolor === "normal" || mapcolor === "natural"){
                    themapcolor = '';
                }


                
                mapOptions = {
                        zoom: 4,
                        styles: themapcolor,
                        panControl: true,
                        scrollwheel: mousewheel,
                        zoomControl: true,
                        draggable: true,
                        zoomControlOptions: {
                            style: google.maps.ZoomControlStyle.LARGE,
                            position: google.maps.ControlPosition.LEFT_CENTER
                        },
                        mapTypeControl: false,
                        scaleControl: true,
                        streetViewControl:  that.attr("data-streetview"),
                        overviewMapControl: true 
                    };
                mapElement = document.getElementById(target);
                that.map = new google.maps.Map(mapElement, mapOptions);

                that.bounds = new google.maps.LatLngBounds ();
              
                
                  
                
                that.find(".qtPlaces-marker").each(function(i,c){
                    // Adding markers
                    var mapitem = $(this);
                    mapitem.lat = mapitem.attr("data-lat"),
                    mapitem.lon = mapitem.attr("data-lon");
                    

                    if( mapitem.lat !== "" && mapitem.lon !== ""){
                        myLatlng = new google.maps.LatLng(mapitem.lat, mapitem.lon);
                        that.bounds.extend (myLatlng);
                        //
                        //  MARKER // hidden
                        //  ============================================

                        var markerid = mapitem.attr("data-markerid"),
                            mapid = mapitem.attr("data-mapid"),
                            clicktarget = mapitem.attr("data-clicktarget"),
                            markertitle = mapitem.attr("data-markertitle"),
                            markerimg = mapitem.attr("data-markerimg"),
                            hidethumbnail = mapitem.attr("data-hidethumbnail"),
                            filters = mapitem.attr("data-filters"),
                            markerdate = mapitem.attr("data-markerdate"),
                            markerlink = mapitem.attr("data-markerlink"),
                            markerphone = mapitem.attr("data-markerphone"),
                            markerlink = mapitem.attr("data-markerlink"),
                            markerlocation = mapitem.attr("data-markerlocation"),
                            markericon = mapitem.find("i").attr("class"),
                            markeremail = mapitem.attr("data-markeremail"),
                            fulladdress = mapitem.attr("data-markeraddress")+" "+mapitem.attr("data-markercity")+" "+mapitem.attr("data-markercountry").split("++").join("");

                        if(markerimg != ''){
                            markerimg = '<img src="'+markerimg+'" class="'+hidethumbnail+'">';
                        }
                        var markercontent = '<div id="mapmarker'+markerid+'" class="qtPlaces-mapmarker all '+filters+'">'
                        	+'<a class="qtPlaces-marker-img qtIndicator" data-mapct="'+markerid+'">'
                            +markerimg
                            +'<i class="'+markericon+'"></i></a>'
                            +'<div class="markercontents">';
							if(markertitle != ''){
                            	markercontent +='<h5 class="locationname"><a href="'+mapitem.attr("href")+'">'+stripslashes(markertitle)+'</a></h5>';
                            }
                            if(markertitle === markerlocation) {
                            	markerlocation = '';
                            }
                            markercontent +='<p class="location"><span>'+stripslashes(markerlocation)+'</span>'+stripslashes(mapitem.attr("data-markeraddress"))+' '+stripslashes(mapitem.attr("data-markercity"))+ ' '+stripslashes(mapitem.attr("data-markercountry"))+' </p>';
                            if(markerlink != ''){
                            	markercontent +='<p class="det"><i class="fa fa-external-link"></i><a href="'+markerlink+'" class="qtPlaces-button" target="_blank">'+markerlink+'</a></p>';
                            }
                            if(markerphone != ''){
                            	markercontent +='<p class="det"><i class="fa fa-phone"></i><a href="tel:'+markerphone+'" class="qtPlaces-button" target="_blank">'+markerphone+'</a></p>';
                            }
                            if(markeremail != ''){
                            	markercontent +='<p class="det"><i class="fa fa-envelope-o"></i><a href="mailto:'+markeremail+'" class="qtPlaces-button" target="_blank">'+markeremail+'</a></p>';
                            }

                            if(getdirections != ''){
                                markercontent +='<p class="det"><i class="fa fa-compass"></i> <a href="https://www.google.com/maps/dir/Current+Location/'+fulladdress.split(" ").join("+")+'" class="qtPlaces-button" target="_blank">'+getdirections+'</a></p>';
                            }
                            markercontent +='<i class="fa fa-close close"></i></div></div>';

                        if( mapitem.marker = new RichMarker({  position: myLatlng, map: that.map,  draggable: false, content: markercontent }) ){


                        	//  CLICK on the List button
	                        //  ============================================
	                        mapitem.click(function(e){
	                            e.preventDefault();
	                            var theitem = $(this);
	                            var theid = theitem.attr("data-markerid");
	                            var themapid = theitem.attr("data-mapid");
	                            var themap = $("#"+themapid);
	                            $("#"+themapid+" .qtPlaces-mapmarker").removeClass("active");
	                            $("#"+themapid+" #mapmarker"+theid).addClass("active"); 
	                            var lat = theitem.attr("data-lat"),
	                                lon = theitem.attr("data-lon");
	                            myLatlng = new google.maps.LatLng(lat, lon);
	                            that.map.setCenter(myLatlng);
	                            that.map.panTo(myLatlng);
                                if(theitem.attr("data-autozoom") === "1") {
                                    that.map.setZoom(5);  
                                }

                                if($(window).width() < 1024) {
                                    that.closest(".qtPlaces-container").removeClass("open").find(".qtPlaces-menuswitch i").addClass("fa-bars").removeClass("fa-close");
                                }
	                           //     
	                        });


	                        that.on("click", ".qtPlaces-mapmarker .close", function(e){
	                        	e.preventDefault();
	                        	$(this).closest(".qtPlaces-mapmarker").removeClass("active");
	                        } );
                        }
                    }
                }); // LOOP: data-mapitem each
                that.map.fitBounds (that.bounds);
            
            }).delay(1000).promise().done(function(){ 
               /**/ 
               $("a.qtIndicator").click(function(e){

                	e.preventDefault();
                    var buttonid = $(this).attr("data-mapct");
                    $("#"+$(this).attr("data-mapct")).click();
                });
            }); // data DYNAMICMAP EACH
	    }
	}

	/**
	 * [qtPlaceMenuswitch switch menu open close]
	 * @return {[boolean]} [success]
	 */
	$.fn.qtPlaceMenuswitch = function(){
        $("body").off("click", ".qtPlaces-menuswitch");
		$("body").on("click", ".qtPlaces-menuswitch", function(e){
			e.preventDefault();
			var that = $(this);
			that.closest(".qtPlaces-container").toggleClass("open");
			that.find("i").toggleClass("fa-bars").toggleClass("fa-close");
		});
		return true;
	}

	/**
	 * [qtPlaceFilterResults applies a category filter to the selected map]
	 * @param  {[string]} target [id of the selected map]
	 * @param  {[string]} filter [taxonomy unique ID]
	 * @return {[boolean]}        [success]
	 */
	$.fn.qtPlaceFilterResults = function(target, filter){
		// 1 Filtering of the list results
		$("#" + target + " .qtPlaces-entry").each(function(i,c){
			var that = $(c);

			if(that.hasClass(filter)) {
				that.show().promise().done(function(){
					that.animate({opacity:1}, 500);
				});
			} else {
				that.animate({opacity:0}, 500).promise().done(function(){
					that.hide();
				});
			};
		});

		$("#" + target + " .qtPlaces-mapmarker").each(function(i,c){
			var that = $(c);

			if(that.hasClass(filter)) {
				that.show().promise().done(function(){
					that.animate({opacity:1}, 500);
				});
			} else {
				that.animate({opacity:0}, 500).promise().done(function(){
					that.hide();
				});
			};
		});
		return true;
	};


	/**
	 * [qtPlaceFilter filters the results based on the clicked tag]
	 * @param  {[string]} targetContainer [map selector]
	 * @return {[boolean]}                 [success]
	 */
	$.fn.qtPlaceFilter = function(targetContainer){
		if(targetContainer === undefined) {
			targetContainer = ".qtPlaces-container";
		}
		$("body").off("click", targetContainer+" [data-placefilter]");
		$("body").on("click", targetContainer+" [data-placefilter]", function(e){
			e.preventDefault();
			var that = $(this),
				target = that.attr("data-targetmap"),
				filter = that.attr("data-placefilter");
			if(that.hasClass("active")){
				that.removeClass("active");
				$.fn.qtPlaceFilterResults(target, "all");
			} else {
				that.siblings().removeClass("active");
				that.addClass("active");
				$.fn.qtPlaceFilterResults(target, filter);
			}
		});
		return true;
	};

	/**
	 * [qtPlaceAutoBg automatically adds background images]
	 * @return {[type]} [description]
	 */
	$.fn.qtPlaceAutoBg = function(targetContainer){
		if(targetContainer === undefined) {
			targetContainer = ".qtPlaces-container";
		}
		$(targetContainer+" [data-qtautobg]").each(function(i){
			var that = $(this),
				bg = that.attr("data-qtautobg");
			that.css({"background-image": "url("+bg+")"});
		});
	}

	/**
	 * [qtPlacesInit initialization. Contains all the needed functions to run the map. Can be called again for ajax initialization]
	 * @return {[type]} [description]
	 */
	$.fn.qtPlacesInit = function(){
		$.fn.qtPlaceMenuswitch();
		$.fn.qtPlaceFilter();
		$.fn.qtPlaceAutoBg();
		$.fn.qtPlaceDynamicMaps();
	};





      /**====================================================================
     *
     * 
     *  19. Dynamic maps
     *  
     * 
     ====================================================================*/

    var QT_map_light    = [{"featureType":"landscape","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"stylers":[{"hue":"#00aaff"},{"saturation":-100},{"gamma":2.15},{"lightness":12}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"visibility":"on"},{"lightness":24}]},{"featureType":"road","elementType":"geometry","stylers":[{"lightness":57}]}];
    var QT_map_dark     = [{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":17}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":20}]},{"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#000000"},{"lightness":17}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#000000"},{"lightness":29},{"weight":0.2}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":18}]},{"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":16}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":21}]},{"elementType":"labels.text.stroke","stylers":[{"visibility":"on"},{"color":"#000000"},{"lightness":16}]},{"elementType":"labels.text.fill","stylers":[{"saturation":36},{"color":"#000000"},{"lightness":40}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#000000"},{"lightness":19}]},{"featureType":"administrative","elementType":"geometry.fill","stylers":[{"color":"#000000"},{"lightness":20}]},{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#000000"},{"lightness":17},{"weight":1.2}]}];
    $.fn.qtDynamicMaps = function(targetContainer){
        if(undefined === targetContainer) {
                targetContainer = "body";
        }
        var map, mapOptions;
        $(targetContainer+" .qt_dynamicmaps").each(function(i,c){
            var that = $(c),
                coord = that.attr("data-coord").split(","),
                mylat = coord[0],
                mylon = coord[1],
                mapid = that.attr("id"),
                colors = that.attr("data-colors"),
                height = that.attr("data-height"),
                locationname = that.attr("data-locationname");

            that.height(height);
            var map = new google.maps.Map(document.getElementById(mapid), {
                zoom: 16, 
                height: height,
                // styles: QT_map_dark, 
                center: new google.maps.LatLng(mylat, mylon), 
                mapTypeId: google.maps.MapTypeId.ROADMAP
            });
            var infowindow = new google.maps.InfoWindow();
            var marker, i;
            marker = new google.maps.Marker({
                position: new google.maps.LatLng(mylat,mylon),
                map: map
            });
            google.maps.event.addListener(marker, 'click', (function(marker, i) {
                return function() {
                    infowindow.setContent(locationname);
                    infowindow.open(map, marker);
                }
            })(marker, i));
        });
    }
   


	$(window).ready(function(){
        if(typeof(google) !== "undefined") {
            $.fn.qtDynamicMaps();
            $.fn.qtPlacesInit();
        }
		
	});


})(jQuery);