require "spec"
require "mocks"
require "mocks/spec"
require "../src/concourse-summary/job"

Mocks.create_double "Response" do
  mock status_code().as(Int32)
  mock body().as(String)
end
Mocks.create_double "Client" do
  mock get(path).as(Response)
end

describe "Job" do
  describe ".all" do
    it "returns requested pipelines" do
      response = Mocks.double("Response", returns(status_code, 200), returns(body, %([{"name":"fred","groups":[],"next_build":null,"finished_build":null},{"name":"jane","groups":[],"next_build":null,"finished_build":null}])))
      client = Mocks.double("Client", returns(get("/api/v1/some/path/jobs"), response))

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
