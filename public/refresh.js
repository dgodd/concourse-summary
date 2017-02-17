window.refresh_interval = window.refresh_interval || 30;

var styles = document.createElement("style");
document.head.appendChild(styles);

var scaleboxes = function() {
  var x = document.querySelectorAll('a.outer');
  var notboxes = 32 + (32 * document.querySelectorAll('.group').length);
  var y = ((window.innerHeight - notboxes) * window.innerWidth) / x.length;
  var w = Math.floor(Math.sqrt(y)) - 4;
  var h = Math.floor(w * 2 / 3);

  // Correct for too long
  var perColumn = Math.floor(window.innerWidth / (w + 4));
  var numRows = Math.ceil(x.length / perColumn)
  var heightRequired = numRows * (h + 4) + notboxes;
  if (heightRequired > window.innerHeight) {
    numRows -= 1;
    perColumn = Math.ceil(x.length / numRows);
    w = Math.floor(window.innerWidth / perColumn) - 8;
    h = Math.floor(w * 2 / 3);
    document.body.style.overflow = 'hidden';
  }

  // Set styles
  boxStyle = "a.outer {";
  boxStyle += "width:"+w+"px;";
  boxStyle += "height: "+h+"px;";
  boxStyle += "}";
  boxStyle += "a.outer div.inner {";
  boxStyle += "height: " + h + "px;";
  boxStyle += "line-height: " + Math.floor(h / 4) + "px;";
  boxStyle += "font-size: " + Math.floor(h / 6) + "px;";
  boxStyle += "}";
  styles.innerHTML = boxStyle;

  var numRunning = document.querySelectorAll('a.outer.running').length;
  var favicon = new Favico({ animation:'none' });
  favicon.badge(numRunning);

  setTimeout(function(){
    var x = document.querySelectorAll('a.outer .inner > span > span')
    for (var i = 0; i < x.length; i++) {
      var y = x[i];
      var z = y.parentNode
      var multi = (z.offsetWidth * 0.8) / y.offsetWidth
      if (multi < 1) {
        y.style.fontSize = (multi * 100) + '%'
      }
    }
  }, 0);
};

window.addEventListener("load", function() { scaleboxes() });
window.addEventListener("resize", function() { scaleboxes() });
