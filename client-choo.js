const choo = require('choo')
const html = require('choo/html')
const http = require('choo/http')
const app = choo()

app.model({
  state: { countdown: 0, statuses: [] },
  reducers: {
    update: (data, state) => ({ title: data }),
    decrement: (data, state) => ({ countdown: state.countdown - 1 }),
    receive: (data, state) => {
      console.log(data)
      return { statuses: data }
    }
  },
  effects: {
    fetch: (data, state, send, done) => {
      http('/hosta.json', (err, res, body) => {
        send('receive', JSON.parse(body), done)
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
      }, 2000)
    }
  ]
})

const statusView = (state) => html`
  <a href="https://ci.concourse.ci/teams/main/pipelines/main?groups=develop" target="_blank" class="outer running">
    <div class="status">
      <div class="aborted" style="width: 7%;"></div>
      <div class="errored" style="width: 0%;"></div>
      <div class="failed" style="width: 7%;"></div>
      <div class="succeeded" style="width: 85%;"></div>
    </div>
    <div class="inner">${state.pipeline}<br>${state.group}</div>
  </a>
`

const mainView = (state, prev, send) => html`
  <main>
    <h1>Title: ${state.title}</h1>
    <h2>Countdown: ${state.countdown}</h2>
    <div>${state.statuses.map(status => statusView(status))}</div>
    <input
      type="text"
      oninput=${(e) => send('update', e.target.value)}>
  </main>
`

app.router((route) => [
  route('/', mainView)
])

const tree = app.start()
document.body.appendChild(tree)

var link=document.createElement('link');
link.href='public/styles.css';
link.rel='stylesheet';
document.head.appendChild(link);
