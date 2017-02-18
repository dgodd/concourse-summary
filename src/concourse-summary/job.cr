require "json"
require "./status"

class Job
  JSON.mapping(
    name: String,
    groups: Array(String?),
    paused: Bool?,
    next_build: Status?,
    finished_build: Status?,
  )

  def groups
    return [nil] if @groups.size == 0
    @groups
  end

  def clear_groups
    @groups = [] of String?
  end

  def running
    !!next_build
  end

  def status
    paused.try do |p|
      return "paused_job" if p
    end
    finished_build.try do |build|
      build.status
    end
  end

  def self.all(client, job_url : String)
    response = client.get("/api/v1#{job_url}/jobs")
    begin
      Array(Job).from_json(response.body)
    rescue ex
      puts "EXCEPTION: #{job_url}"
      [] of Job
    end
  end
end
