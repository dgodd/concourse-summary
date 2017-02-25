require "spec"
require "../src/concourse-summary/pipeline"

class Response
  @status_code : Int32
  @body : String
  getter status_code
  getter body
  def initialize(@status_code, @body)
  end
end
class Client
  @path : String
  @response : Response
  def initialize(@path, @response)
  end
  def get(path)
    it { path == @path }
    @response
  end
end


describe "Pipeline" do
  describe ".all" do
    it "returns requested pipelines" do
      response = Response.new(200, %([{"name":"fred","url":"","paused":false},{"name":"jane","url":"","paused":false}]))
      client = Client.new("/api/v1/pipelines", response)

      pipelines = Pipeline.all(client)
      pipelines.map(&.name).should eq ["fred","jane"]
    end

    it "raises exception if 401 status code is returned" do
      response = Response.new(401, "")
      client = Client.new("/api/v1/pipelines", response)

      expect_raises Unauthorized do
        Pipeline.all(client)
      end
    end
  end
end
