window.refresh_interval = window.refresh_interval || 30;
var scaletext = function() {
  $( '.outer' ).each(function ( i, box ) {
    var box_text = box.innerText || box.textContent;
    var split_box_text = box_text.split(/\r?\n/);
    split_box_text.forEach(function(linetext) {
      var canvas = document.createElement('canvas');
      var ctx = canvas.getContext("2d");
      var font_family = $('body').css('font-family');
      var font_size_px = $('body').css('font-size');
      var font_size = parseInt(font_size_px.split("px")[0], 10);
      var ctx_font = font_size + "px " + font_family;
      ctx.font = ctx_font;
      var width = ctx.measureText(linetext).width +10;
      var linewidth = $( box ).width();

      while ( width > linewidth ) {
        --font_size;
        $( '.' + linetext ).css( 'font-size', font_size );
        ctx_font = font_size + "px " + font_family;
        ctx.font = ctx_font;
        width = ctx.measureText(linetext).width +10;
      }
    });
  });
};
var onerror = function() {
  document.body.innerHTML = '<div class="time">' + Date() + ' (<span id="countdown">' + refresh_interval + '</span>)</div><h1>ERROR</h1>';
};
var onsuccess = function(request) {
  var doc = document.implementation.createHTMLDocument("example");
  doc.documentElement.innerHTML = request.response;
  document.head.innerHTML=doc.head.innerHTML;
  document.body.innerHTML=doc.body.innerHTML;
  scaletext();
};
setInterval(function() {
  var request = new XMLHttpRequest();
  request.open('GET', location.href, true);
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      onsuccess(request);
    } else {
      onerror();
    }
  };
  request.onerror = onerror;
  request.send();
}, refresh_interval * 1000);
setInterval(function() {
  var el = document.getElementById('countdown');
  if(el) {
    var counter = parseInt(el.innerText, 10);
    el.innerText = counter - 1;
  }
}, 1000);
scaletext();