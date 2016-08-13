require "json"
require "./status"

class Job
  JSON.mapping(
    name: String,
    groups: Array(String),
    next_build: Status | Nil,
    finished_build: Status | Nil,
  )

  def group
    groups.first?
  end

  def running
    !!next_build
  end

  def status
    finished_build.try do |build|
      build.status
    end
  end

  def self.all(client, pipeline : String)
    response = client.get("/api/v1/pipelines/#{pipeline}/jobs")
    Array(Job).from_json(response.body) rescue [] of Job
  end
end
