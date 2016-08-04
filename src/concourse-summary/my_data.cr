class MyData
  @pipeline : String?
  @group : String?
  @running = false
  getter running
  setter running
  @statuses = Hash(String, Int32).new(0)

  def initialize(@pipeline, @group)
  end

  def inc(status : String | Nil)
    status.try do |status|
      @statuses[status] += 1
    end
  end

  def labels
    [@pipeline, @group].compact
  end

  def href
    "/pipelines/#{@pipeline}" + (@group ? "?groups=#{@group}" : "")
  end

  def percent
    return 0 if @statuses.size == 0
    (@statuses["succeeded"].to_f / @statuses.values.sum * 100).round.to_i
  end

  def self.get_data(host, username, password)
    hash = Hash(Tuple(String, String | Nil), MyData).new do |_, key|
      pipeline, group = key
      MyData.new(pipeline, group)
    end
    client = HTTP::Client.new(host, tls: true)
    client.basic_auth(username, password)

    Pipeline.all(client).each do |pipeline|
      puts pipeline.name
      Job.all(client, pipeline.name).each do |job|
        key = {pipeline.name, job.group}
        data = hash[key]
        data.running ||= job.running
        data.inc(job.status)
        hash[key] = data
      end
    end
    hash.values
  end
end
