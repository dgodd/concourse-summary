$( '.outer' ).each(function ( i, box ) {
  var canvas = document.createElement('canvas');
  var ctx = canvas.getContext("2d");
  var font_family = $('body').css('font-family');
  var font_size_px = $('body').css('font-size');
  var font_size = parseInt(font_size_px.split("px")[0], 10);
  var ctx_font = font_size + "px " + font_family
  ctx.font = ctx_font
  var box_text = box.innerText || box.textContent;
  var split_box_text = box_text.split(/\r?\n/)
  var last_line = split_box_text[split_box_text.length -1]
  var width = ctx.measureText(last_line).width;
  var linewidth = $( box ).width();

  var inner = $( '.inner' );
  html = '<span class="' + last_line + '" style="font_size: ' + font_size + 'px"></span>',
  line = $( box ).wrapInner( html ).children()[ 0 ];

  while ( width > linewidth ) {
    --font_size
    $( '.' + last_line ).css( 'font-size', font_size );
    ctx_font = font_size + "px " + font_family
    ctx.font = ctx_font
    width = ctx.measureText(last_line).width
  }
});
