/**
 * @package QT Chartvote
 * Script for the Qantumthemes Love It plugin
 */
!function(n){"use strict";n.fn.qtChartvoteInit=function(){
// var post_id, heart;
n("body a.qt-chartvote-link").off("click"),n("body a.qt-chartvote-link").on("click",function(t){t.preventDefault(),t.stopPropagation();var a=n(this),e="voted-"+a.data("chartid")+"-"+a.data("position");n.ajax({type:"post",url:chartvote_ajax_var.url,cache:!1,data:"action=track-vote&nonce="+chartvote_ajax_var.nonce+"&position="+a.data("position")+"&move="+a.data("move")+"&chartid="+a.data("chartid"),success:function(t){if(console.log(n.cookie(e)),"1"!==n.cookie(e)){var o=jQuery.parseJSON(t);console.log("SUCCESS!"),console.log(o),a.parent().find(".qt-chartvote-number").html(o.newvalue),n.cookie(e,"1",{path:"/"})}else alert("You already voted for this track")},error:function(t){console.log(t.Error)}})})},jQuery(document).ready(function(){n.fn.qtChartvoteInit()})}(jQuery);