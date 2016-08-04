#!/usr/bin/env ruby
require 'faraday'
require 'json'
require 'rack'
require 'rack/auth/basic'

class Unauthorized < Exception; end
def gen_html(base_url)
  data = {}
  conn = Faraday.new(url: base_url)
  resp = conn.get('/api/v1/pipelines')
  raise Unauthorized.new if resp.status == 401
  JSON.load(resp.body).each do |pipeline|
    name = pipeline['name']
    data[name] = { 'next' => Hash.new(0), 'finished' => Hash.new(0) }
    puts name
    puts "/api/v1/pipelines/#{name}/jobs"
    resp = conn.get("/api/v1/pipelines/#{name}/jobs")
    JSON.load(resp.body).each do |job|
      next_build = job['next_build']
      data[name]['next'][next_build['status']] += 1 if next_build

      finished_build = job['finished_build']
      data[name]['finished'][finished_build['status']] += 1 if finished_build
    end
  end

  p data
  html = <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <title>#{Time.now}</title>
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-32x32.png" sizes="32x32">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/android-chrome-192x192.png" sizes="192x192">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-96x96.png" sizes="96x96">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-16x16.png" sizes="16x16">
    <style>
      body { margin:0; padding:0; font-family: sans-serif; font-size: 20px; }
      .outer { display:block; width: 200px; height: 120px; color: white; background: #090; position: relative; margin: 8px; float: left; }
      .running { border: 7px solid yellow; box-sizing: border-box; outline: 3px solid #699; }
      .red { position: absolute; top:0; bottom: 0; left:0;  background: #900; }
      .inner { position: absolute; top:0; bottom: 0; left:0; right:0; text-align: center; line-height: 120px; white-space: nowrap; text-decoration: none; }
      .running .inner { line-height: 100px; }
    </style>
    <script>
      setInterval(function() {
        fetch(location.pathname, {credentials: 'same-origin'}).then(function(response) {
          return response.text()
        }).then(function(txt) {
          document.body.innerHTML=txt
        }).catch(function(reason) {
          document.body.innerHTML="<h1>Error - " + Date() + "</h1><p>" + reason + "</p>"
        })
      }, 30000)
    </script>
  </head>
  <body>
    <p>#{Time.now}</p>
EOF

  safe_base_url = base_url.gsub(%r{//.*@},'//')
  data.each do |key, value|
    next unless value['finished'] && value['finished'].values.first

    running = value['next'].values.count > 0 ? 'running' : ''
    succeeded = value['finished']['succeeded'].to_f
    value = succeeded / value['finished'].values.reduce(:+).to_f

    p [ key, value ]
    html += <<-EOF
    <a href="#{safe_base_url}/pipelines/#{key}" target="_blank" class="outer #{running}">
      <div class="red" style="width: #{100 - (value * 100).round}%;"></div>
      <div class="inner">#{key}</div>
    </div>
EOF
  end

  html += <<-EOF
  </body>
</html>
EOF
end


if ENV['BASE_HOST']
  BASE_HOST = ENV['BASE_HOST']
elsif ENV['BASE_URL']
  BASE_HOST = URI(ENV['BASE_URL']).host
else
  raise 'Set BASE_HOST. eg. appdog.ci.cf-app.com'
end

class BasicAuth < Rack::Auth::Basic
  def call(env)
    auth = Rack::Auth::Basic::Request.new(env)
    env['REMOTE_USER_AUTH'] = auth.credentials.join(':') if auth.provided?
    begin
      @app.call(env)    
    rescue Unauthorized
      unauthorized(%Q{Basic realm="#{env['REQUEST_PATH']}"})
    end
  end
end

class App
  def call(env)
    if env['REQUEST_PATH']=='/'
      [301, {'Location' => "/host/#{BASE_HOST}"}, []]
    elsif env['REQUEST_PATH'].match(%r{/host/(.+)})
      base_url = "https://#{env['REMOTE_USER_AUTH']}@#{$1}"
      puts base_url
      [200, {'Content-Type' => 'text/html'}, [gen_html(base_url)]]
    else
      [404, {}, []]
    end
  end
end
protected_app = BasicAuth.new(App.new) 
Rack::Handler::WEBrick.run protected_app
