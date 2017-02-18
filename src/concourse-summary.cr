require "json"
require "kemal"

require "./concourse-summary/*"

serve_static({"gzip" => true, "dir_listing" => false})
gzip true

REFRESH_INTERVAL = (ENV["REFRESH_INTERVAL"]? || 30).to_i
GROUPS = parse_groups(ENV["CS_GROUPS"]? || "{}")

def setup(env)
  refresh_interval = REFRESH_INTERVAL
  username = env.store["credentials_username"]?
  password = env.store["credentials_password"]?

  login_form = env.params.query.has_key?("login_form")
  if login_form && (username.to_s.size == 0 || password.to_s.size == 0)
    raise Unauthorized.new
  end

  collapso_toggle = env.params.query.map {|k,_| k}
  ignore_groups = env.params.query.has_key?("ignore_groups")
  if ignore_groups
    collapso_toggle = collapso_toggle - ["ignore_groups"]
  else
    collapso_toggle = collapso_toggle + ["ignore_groups"]
  end

  team_name = (env.params.query["team"]? || "main").to_s

  {refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name}
end

def process(data, ignore_groups)
  if ignore_groups
    MyData.remove_group_info(data)
  end
  statuses = MyData.statuses(data)
end

get "/host/jobs/:host/**" do |env|
  refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
  host = env.params.url["host"]

  data = MyData.get_data(host, username, password, nil, login_form)
  jobs = data.map do |pipeline,job|
    JobInfo.new(pipeline, job)
  end.select do |info|
    info.running || (!info.status.nil? && info.status != "succeeded" && !info.paused)
  end.sort_by{|a| a.start_time || 0 }

  json_or_html(jobs, "jobs")
end

get "/jobs/match/:keyword/:host/**" do |env|
  refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
  keyword = env.params.url["keyword"]
  host = env.params.url["host"]

  data = MyData.get_data(host, username, password, nil, login_form, team_name)
  jobs = data.map do |pipeline,job|
    JobInfo.new(pipeline, job)
  end.select do |info|
    info.name.includes? keyword
  end.sort_by{|a| a.start_time || 0 }

  json_or_html(jobs, "jobs")
end

get "/host/:host/**" do |env|
  refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)
  host = env.params.url["host"]

  data = MyData.get_data(host, username, password, nil, login_form, team_name)
  statuses = process(data, ignore_groups)

  json_or_html(statuses, "host")
end

get "/group/:key" do |env|
  refresh_interval,username,password,ignore_groups,collapso_toggle,login_form,team_name = setup(env)

  hosts = GROUPS[env.params.url["key"]]
  hosts = hosts.map do |host, pipelines|
    data = MyData.get_data(host, username, password, pipelines)
    data = MyData.filter_groups(data, pipelines)
    statuses = process(data, ignore_groups)
    { host, statuses }
  end

  json_or_html(hosts, "group")
end

get "/" do |env|
  refresh_interval = REFRESH_INTERVAL
  hosts = (ENV["HOSTS"]? || "").split(/\s+/)
  groups = GROUPS.keys

  json_or_html(hosts, "index")
end

Kemal.config.add_handler ExposeUnauthorizedHandler.new
Kemal.run
