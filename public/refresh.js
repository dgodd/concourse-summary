window.refresh_interval = window.refresh_interval || 30;
var onerror = function() {
  document.body.innerHTML = '<div class="time">' + Date() + ' (<span id="countdown">' + refresh_interval + '</span>)</div><h1>ERROR</h1>';
};
var onsuccess = function(request) {
  var doc = document.implementation.createHTMLDocument("example")
  doc.documentElement.innerHTML = request.response;
  document.head.innerHTML=doc.head.innerHTML
  document.body.innerHTML=doc.body.innerHTML
};
setInterval(function() {
  var request = new XMLHttpRequest();
  request.open('GET', location.href, true);
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      onsuccess(request)
    } else {
      onerror();
    }
  };
  request.onerror = onerror;
  request.send();
}, refresh_interval * 1000)
setInterval(function() {
  var el = document.getElementById('countdown');
  if(el) {
    var counter = parseInt(el.innerText, 10);
    el.innerText = counter - 1;
  }
}, 1000)
