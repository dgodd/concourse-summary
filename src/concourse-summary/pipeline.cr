require "json"
require "./exceptions"

class Pipeline
  JSON.mapping(
    name: String,
    team_name: String,
    paused: Bool
  )

  property url : String = ""

  def self.all(client)
    response = client.get("/api/v1/pipelines")
    raise Unauthorized.new if response.status_code == 401
    return [] of Pipeline if response.status_code == 500
    pipelines = Array(Pipeline).from_json(response.body)
    pipelines.each do |pipeline|
      pipeline.url = "/teams/#{pipeline.team_name}/pipelines/#{pipeline.name}"
    end
    return pipelines
  end
end
