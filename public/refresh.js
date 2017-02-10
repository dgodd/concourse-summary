window.refresh_interval = window.refresh_interval || 30;
var favicon=new Favico({
    animation:'none'
});
var scaleboxes = function() {
  var numRunning = document.querySelectorAll('div.scalable a.outer.running').length;
  favicon.badge(numRunning);

  var mult = 1.0;
  while(window.innerHeight < document.body.clientHeight) {
    mult = mult * 0.95
    var x = document.querySelectorAll('div.scalable a.outer');
    for (var i = 0; i < x.length; i++) {
      var y = x[i];
      y.style.width = Math.floor(200 * mult) + "px";
      y.style.height = Math.floor(120 * mult) + "px";
    }
  }

  setTimeout(function(){
    var x = document.querySelectorAll('div.scalable a.outer div.inner');
    for (var i = 0; i < x.length; i++) {
      var y = x[i];
      y.style.height = Math.floor(120 * mult) + "px";
      y.style.lineHeight = Math.floor(120 * mult / 4) + "px";
      y.style.fontSize = Math.floor(120 * mult / 6) + "px";
    }

    var x = document.querySelectorAll('div.scalable .inner > span > span')
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
};
var onsuccess = function(request) {
  var doc = document.implementation.createHTMLDocument("example");
  doc.documentElement.innerHTML = request.response;
  document.head.innerHTML=doc.head.innerHTML;
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

window.addEventListener("load", function() {
  scaleboxes()
});
