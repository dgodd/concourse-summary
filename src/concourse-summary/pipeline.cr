require "json"
require "./exceptions"

class Pipeline
  JSON.mapping(
    name: String,
    url: String,
    paused: Bool
  )

  def self.all(client, filters)
    response = client.get("/api/v1/pipelines")
    raise Unauthorized.new if response.status_code == 401
    all_the_pipes = Array(Pipeline).from_json(response.body)
    unless filters.empty?
      all_the_pipes.select! { |p| filters.includes?(p.name) }
    end
    all_the_pipes
  end
end
