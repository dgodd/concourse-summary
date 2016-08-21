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
  data = MyData.get_data(host, username, password)
  if (ignore_groups)
    data = MyData.remove_group_info(data)
  end
  statuses = MyData.statuses(data)
  if env.request.headers["Accept"] == "application/json" || true
    env.response.headers["Access-Control-Allow-Origin"] = "*"
    env.response.content_type = "application/json"
    statuses.to_json
  else
    render "views/host.ecr", "views/layout.ecr"
  end
end

get "/env" do |env|
  env.response.content_type = "application/json"
  env.request.headers.inspect
end

get "/" do |env|
  hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  render "views/index.ecr", "views/layout.ecr"
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
