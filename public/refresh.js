window.refresh_interval = window.refresh_interval || 30;

var styles = document.createElement("style");
document.head.appendChild(styles);

var scaleboxes = function() {
  var x = document.querySelectorAll('a.outer');
  var notboxes = 32 + (32 * document.querySelectorAll('.group').length);
  var y = ((window.innerHeight - notboxes) * window.innerWidth) / x.length;
  var w = Math.floor(Math.sqrt(y)) - 4;
  var h = w * 2 / 3;
  var h = Math.floor(w * 2 / 3);

  // Correct if too long
  var perColumn = Math.floor(window.innerWidth / (w + 4));
  var numRows = Math.ceil(x.length / perColumn)
  var heightRequired = numRows * (h + 4) + notboxes;
  if (heightRequired > window.innerHeight) {
    numRows -= 1;
    perColumn = Math.ceil(x.length / numRows);
    w = Math.floor(window.innerWidth / perColumn) - 8;
    h = Math.floor(w * 2 / 3);
  }

 // Set styles
  boxStyle = "body{overflow:hidden}";
  boxStyle += "a.outer {";
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
  }, 10);
};

var onerror = function() {
  document.body.innerHTML = '<div class="time">' + Date() + ' (<span id="countdown">' + refresh_interval + '</span>)</div><h1>ERROR</h1>';
  document.head.setAttribute("rel", "error");
};
var onsuccess = function(request) {
  var doc = document.implementation.createHTMLDocument("example");
  doc.documentElement.innerHTML = request.response;
  if (document.head.getAttribute("rel") != doc.head.getAttribute("rel")) {
    window.location.reload();
  }
  document.body.innerHTML=doc.body.innerHTML;

  scaleboxes()
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

window.addEventListener("load", function() { scaleboxes() });
window.addEventListener("resize", function() { scaleboxes() });
