require "spec"
require "../src/concourse-summary/job"

class Response
  @status_code : Int32
  @body : String?
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
    assert { path == @path }
    @response
  end
end

describe "Job" do
  describe ".all" do
    it "returns requested pipelines" do
      response = Response.new(200, %([{"name":"fred","groups":[],"next_build":null,"finished_build":null},{"name":"jane","groups":[],"next_build":null,"finished_build":null}]))
      client = Client.new("/api/v1/some/path/jobs", response)

      jobs = Job.all(client, "/some/path")
      jobs.map(&.name).should eq ["fred","jane"]
    end
  end

  describe "#groups" do
    it "returns groups" do
      job = Job.from_json(%({"name":"fred","groups":["A"],"next_build":null,"finished_build":null}))
      job.groups.should eq ["A"]
    end

    it "turns empty group array in to array of one nil" do
      job = Job.from_json(%({"name":"fred","groups":[],"next_build":null,"finished_build":null}))
      job.groups.should eq [nil]
    end
  end
end
