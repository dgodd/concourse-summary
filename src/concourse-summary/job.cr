require "json"
require "./status"

class Job
  JSON.mapping(
    name: String,
    groups: Array(String?),
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
    finished_build.try do |build|
      build.status
    end
  end

  def self.all(client, job_url : String)
    response = client.get("/api/v1#{job_url}/jobs")
    Array(Job).from_json(response.body) rescue [] of Job
  end
end
