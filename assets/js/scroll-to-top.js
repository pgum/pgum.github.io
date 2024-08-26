jQuery(document).ready(function($) {

    $(window).scroll(function() {
        if($(this).scrollTop() > 200) {
            $("#scroll-to-top-button").fadeIn(200);
        } else {
            $("#scroll-to-top-button").fadeOut(200);
        }
    });
    
    $("#scroll-to-top-button").click(function() {
        $("html, body").animate({ 
            scrollTop: 0 
        }, "slow");
        return false;
    });
});