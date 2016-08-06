class Client
  def initialize(@client : HTTP::Client)
  end

  def pipelines
    response = @client.get("/api/v1/pipelines")
    raise Unauthorized.new if response.status_code == 401
    Array(Pipeline).from_json(response.body)
  end

  def jobs(pipeline : String)
    response = @client.get("/api/v1/pipelines/#{pipeline}/jobs")
    Array(Job).from_json(response.body) rescue [] of Job
  end
end