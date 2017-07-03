require "spec"
require "../src/concourse-summary/resource"

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
    path.should eq @path
    @response
  end
end

describe "Resource" do
  describe ".all" do
    it "returns requested pipelines" do
      response = Response.new(200, %([{"name":"fred"},{"name":"jane","failing_to_check":true}]))
      client = Client.new("/api/v1/some/path/resources", response)

      resources = Resource.all(client, "/some/path")
      resources.map(&.name).should eq ["fred","jane"]
    end
  end

  describe "#broken" do
    it "returns hash of broken resources" do
      response = Response.new(200, %([{"name":"fred"},{"name":"jane","failing_to_check":true}]))
      client = Client.new("/api/v1/some/path/resources", response)

      resources = Resource.broken(client, "/some/path")
      resources["fred"].should eq false
      resources["jane"].should eq true
    end
  end
end
