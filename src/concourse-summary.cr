require "http/client"
require "json"
require "kemal"

require "./concourse-summary/*"

REFRESH_INTERVAL = (ENV["REFRESH_INTERVAL"]? || 30).to_i

get "/host/:host" do |env|
  refresh_interval = REFRESH_INTERVAL
  host = env.params.url["host"]
  username = env.store["credentials_username"]?
  password = env.store["credentials_password"]?
  client = HTTP::Client.new(host, tls: true)
  client.basic_auth(username, password)

  statuses = MyData.get_data(client)
  p statuses
  render "views/host.ecr", "views/layout.ecr"
end

get "/" do |env|
  hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  render "views/index.ecr", "views/layout.ecr"
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
