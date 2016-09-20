require "spec"
require "mocks"
require "mocks/spec"
require "../src/concourse-summary/pipeline"

Mocks.create_double "Response" do
  mock status_code().as(Int32)
  mock body().as(String)
end
Mocks.create_double "Client" do
  mock get(path).as(Response)
end


describe "Pipeline" do
  describe ".all" do
    it "returns requested pipelines" do
      response = Mocks.double("Response", returns(status_code, 200), returns(body, %([{"name":"fred","url":"","paused":false},{"name":"jane","url":"","paused":false}])))
      client = Mocks.double("Client", returns(get("/api/v1/pipelines"), response))

      pipelines = Pipeline.all(client)
      pipelines.map(&.name).should eq ["fred","jane"]
    end

    it "raises exception if 401 status code is returned" do
      response = Mocks.double("Response", returns(status_code, 401))
      client = Mocks.double("Client", returns(get("/api/v1/pipelines"), response))

      expect_raises Unauthorized do
        Pipeline.all(client)
      end
    end
  end
end
