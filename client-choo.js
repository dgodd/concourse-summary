const choo = require('choo')
const html = require('choo/html')
const http = require('choo/http')
const app = choo()
const refreshInterval = 30;

app.model({
  state: { host: 'ci.concourse.ci', countdown: 0, statuses: [] },
  reducers: {
    set_host: (data, state) => {
      return { host: data, countdown: 0, statuses: [] };
    },
    decrement: (data, state) => ({ countdown: state.countdown - 1 }),
    receive: (data, state) => {
      return { statuses: data, countdown: refreshInterval }
    }
  },
  effects: {
    fetch: (data, state, send, done) => {
      http(`http://localhost:3000/host/${state.host}`, {json:true}, (err, res, body) => {
        send('receive', body, done)
      })
    }
  },
  subscriptions: [
    (send, done) => {
      setInterval(() => {
        send('decrement', {}, (err) => {
          if (err) return done(err)
        })
      }, 1000)
    },
    (send, done) => {
      send('fetch', {}, () => {})
      done();
    },
    (send, done) => {
      setInterval(() => {
        send('fetch', {}, (err) => {
          if (err) return done(err)
        })
      }, refreshInterval * 1000)
    }
  ]
})

const statusPercent = (name, statuses) => {
  var total = 0;
  for(var i in statuses) total += statuses[i];
  const perc = statuses[name] * 100 / total;
  return html`<div class="${name}" style="width: ${perc}%;"></div>`;
};

const statusView = (host, state) => html`
  <a href="http://${host}${state.url}" target="_blank" class="outer${state.running ? ' running' : ''}">
    <div class="status">
      ${statusPercent("aborted", state.statuses)}
      ${statusPercent("errored", state.statuses)}
      ${statusPercent("failed", state.statuses)}
      ${statusPercent("succeeded", state.statuses)}
    </div>
    <div class="inner">${state.pipeline}<br>${state.group}</div>
  </a>
`

const mainView = (state, prev, send) => html`
  <main>
    <div class="time"><input style="" value="${state.host}" oninput=${(e) => { send('set_host', e.target.value); send('fetch'); }} /> (<span id="countdown">${state.countdown}</span>)<a href="https://github.com/dgodd/concourse-summary" target="_blank" style="position:absolute;right:0;top:0;"><img src="/public/github.png"></a></div>
    <div>${state.statuses.map(status => statusView(state.host, status))}</div>
  </main>
`

app.router((route) => [
  route('/', mainView),
])

const tree = app.start()
document.body.appendChild(tree)

var link=document.createElement('link');
link.href='public/styles.css';
link.rel='stylesheet';
document.head.appendChild(link);
