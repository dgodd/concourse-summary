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

  def self.get_data(host, username, password)
    client = HTTP::Client.new(host, tls: true)
    client.basic_auth(username, password)

    Pipeline.all(client).map do |pipeline|
      Job.all(client, pipeline.url).map do |job|
        {pipeline, job}
      end
    end.flatten
  end

  def self.remove_group_info(data)
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
end
