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
  ignore_groups = env.params.query.has_key?("ignore_groups")
  filters = (ENV["PIPELINES"]? || "").split(/\s+/)
  data = MyData.get_data(host, username, password, filters)
  if (ignore_groups)
    data = MyData.remove_group_info(data)
  end
  statuses = MyData.statuses(data)
  render "views/host.ecr", "views/layout.ecr"
end

get "/" do |env|
  hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  render "views/index.ecr", "views/layout.ecr"
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
