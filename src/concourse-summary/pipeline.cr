require "json"
require "./exceptions"

class Pipeline
  JSON.mapping(
    name: String,
    url: String,
    paused: Bool
  )

  def self.all(client)
    response = client.get("/api/v1/pipelines")
    raise Unauthorized.new if response.status_code == 401
    return [] of Pipeline if response.status_code == 500
    Array(Pipeline).from_json(response.body)
  end
end
