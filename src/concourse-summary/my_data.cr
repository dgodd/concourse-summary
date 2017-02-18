require "http/client"
require "openssl/ssl/context"

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

  def self.get_data(host, username, password, pipelines = nil, login_form = false, team_name = "main")
    client = HttpClient.new(host, username, password, login_form, team_name)
    Pipeline.all(client).select do |pipeline|
      pipelines.nil? || pipelines.has_key?(pipeline.name)
    end.lazy_map do |pipeline|
      client = HttpClient.new(host, username, password, login_form, team_name)
      Job.all(client, pipeline.url).map do |job|
        {pipeline, job}
      end
    end.flatten
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

  def self.statuses(data : Array(Tuple(Pipeline, Job)))
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

  def to_json(json : JSON::Builder)
    json.object do
      json.field "pipeline", @pipeline || nil
      json.field "group", @group || nil
      json.field "url", href
      json.field "running", @running
      json.field "paused", @paused
      json.field "statuses", @statuses.to_json
    end
  end
end

class Array[String?]
  def &(other : Nil)
    Array(String?).new # Should be [nil] i think
  end
end
