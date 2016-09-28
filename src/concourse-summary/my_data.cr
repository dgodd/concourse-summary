require "http/client"

class MyData
  @pipeline : String?
  @pipeline_url : String?
  getter pipeline_url
  setter pipeline_url
  @group : String?
  @running = false
  getter running
  setter running
  @paused = false
  getter paused
  setter paused
  @statuses = Hash(String, Int32).new(0)

  def initialize(@pipeline, @group)
  end

  def inc(status : String)
    @statuses[status] += 1
  end

  def labels
    [@pipeline, @group].compact
  end

  def href
    (@pipeline_url ? "#{@pipeline_url}" : "/pipelines/#{@pipeline}") + (@group ? "?groups=#{@group}" : "")
  end

  def percent(status)
    return 0 if @statuses.size == 0
    (@statuses[status].to_f / @statuses.values.sum * 100).floor.to_i
  end

  def self.get_data(host, username, password, pipelines = nil, login_form = false)
    client = get_client(host, username, password, login_form)

    Pipeline.all(client).map do |pipeline|
      next if pipelines && !pipelines.has_key?(pipeline.name)
      Job.all(client, pipeline.url).map do |job|
        {pipeline, job}
      end
    end.flatten.compact
  end

  def self.filter_groups(data, pipelines)
    return data unless pipelines
    single_nil_array = (Array(String | Nil).new << nil)
    data.select do |pipeline, job|
      groups = pipelines[pipeline.name]
      if groups == nil || job.groups.size == 0 || job.groups == single_nil_array
        true
      elsif typeof(job.groups) == Array(Nil)
        true
      else
        job.groups = (job.groups & groups).as(Array(String | Nil))
        job.groups.size > 0 && job.groups != single_nil_array
      end
    end
  end

  def self.remove_group_info(data : Array(Tuple(Pipeline, Job)))
    data.each do |pipeline, job|
      job.clear_groups
    end
  end

  def self.statuses(data)
    hash = Hash(Tuple(String, String | Nil), MyData).new do |_, key|
      pipeline_name, group = key
      MyData.new(pipeline_name, group)
    end
    data.each do |pipeline, job|
      job.groups.each do |group|
        key = {pipeline.name, group}
        data = hash[key]
        data.paused = pipeline.paused
        data.pipeline_url = pipeline.url
        data.running ||= job.running
        data.inc(job.status || "pending")
        hash[key] = data
      end
    end
    hash.values
  end

  def to_json(io : IO)
    io.json_object do |object|
      object.field "pipeline", @pipeline || nil
      object.field "group", @group || nil
      object.field "url", href
      object.field "running", @running
      object.field "paused", @paused
      object.field "statuses", @statuses
    end
  end

  private def self.get_client(host, username, password, login_form = false)
    client = HTTP::Client.new(host, tls: true)
    if username.to_s.size > 0
      if login_form
        resp = client.post_form("/teams/main/login", { "username" => username.to_s, "password" => password.to_s })
        cookie = resp.headers["Set-Cookie"].split(";").first
        client.before_request { |request| request.headers["Cookie"] = cookie }
      else
        client.basic_auth(username, password)
      end
    end
    client
  end
end

class Array[String?]
  def &(other : Nil)
    Array(String?).new # Should be [nil] i think
  end
end
