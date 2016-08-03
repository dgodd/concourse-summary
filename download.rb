#!/usr/bin/env ruby
require 'faraday'
require 'json'
require 'rack'

def gen_html(base_url)
  data = {}
  conn = Faraday.new(url: base_url)
  JSON.load(conn.get('/api/v1/pipelines').body).each do |pipeline|
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
    <meta http-equiv="refresh" content="30">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-32x32.png" sizes="32x32">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/android-chrome-192x192.png" sizes="192x192">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-96x96.png" sizes="96x96">
    <link rel="icon" type="image/png" href="https://buildpacks.ci.cf-app.com/public/favicons/favicon-16x16.png" sizes="16x16">
    <style>
      body { margin:0; padding:0; }
      a.outer { display:block; width: 200px; height: 120px; color: white; background: #090; position: relative; margin: 8px; float: left; }
      div.red { position: absolute; top:0; bottom: 0; left:0;  background: #900; }
      div.inner { position: absolute; top:0; bottom: 0; left:0; width: 100%; text-align: center; line-height: 120px; }
      div.inner { font-family: sans-serif; font-size: 20px; white-space: nowrap; }
    </style>
  </head>
  <body>
EOF

  data.each do |key, value|
    next unless value['finished'] && value['finished'].values.first

    succeeded = value['finished']['succeeded'].to_f
    value = succeeded / value['finished'].values.reduce(:+).to_f

    p [ key, value ]
    html += <<-EOF
    <a href="#{base_url}/pipelines/#{key}" target="_blank" class="outer">
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


base_url = ENV['BASE_URL'] or raise "Set BASE_URL"

app = Proc.new do |env|
  ['200', {'Content-Type' => 'text/html'}, [gen_html(base_url)]]
end
Rack::Handler::WEBrick.run app
