require "http/client"
require "json"
require "kemal"

require "./concourse-summary/*"

get "/host/:host" do |env|
  host = env.params.url["host"]
  username = env.store["credentials_username"]?
  password = env.store["credentials_password"]?
  statuses = MyData.get_data(host, username, password)
  p statuses
  render "views/host.ecr"
end

get "/" do |env|
  hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  render "views/index.ecr"
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
