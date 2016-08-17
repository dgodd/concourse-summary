require "spec"
require "file"
require "../src/concourse-summary/my_data"
require "../src/concourse-summary/pipeline"
require "../src/concourse-summary/job"

describe "MyData" do
  describe "#label" do
    it "group is nil" do
      data = MyData.new("mypipe", nil)
      data.labels.should eq ["mypipe"]
    end
    it "group has data" do
      data = MyData.new("mypipe", "mygroup")
      data.labels.should eq ["mypipe", "mygroup"]
    end
  end

  describe "#percent" do
    it "is 0 by default" do
      data = MyData.new("", nil)
      data.percent("succeeded").should eq 0
    end

    it "is 100 if all succeeded" do
      data = MyData.new("", nil)
      data.inc("succeeded")
      data.percent("pending").should eq 0
      data.percent("succeeded").should eq 100
    end

    it "is 2/3 if all some succeeded" do
      data = MyData.new("", nil)
      data.inc("failed")
      data.inc("succeeded")
      data.inc("succeeded")
      data.percent("failed").should eq 33
      data.percent("succeeded").should eq 66
    end
  end

  describe ".statuses" do
    it "handles nil group" do
      job = Job.from_json("{\"groups\":[], \"name\":\"\", \"next_build\":null, \"finished_build\":null}")
      pipeline = Pipeline.from_json("{\"name\":\"pipeline\",\"paused\":false}")
      statuses = MyData.statuses([ {pipeline, job} ])

      statuses.size.should eq 1
      statuses.first.labels.should eq ["pipeline"]
      statuses.first.paused.should be_false
      statuses.first.running.should be_false
      statuses.first.percent("pending").should eq 100.0
    end

    it "handles single group" do
      job = Job.from_json("{\"groups\":[\"group\"], \"name\":\"\", \"next_build\":null, \"finished_build\":null}")
      pipeline = Pipeline.from_json("{\"name\":\"pipeline\",\"paused\":false}")
      statuses = MyData.statuses([ {pipeline, job} ])

      statuses.size.should eq 1
      statuses.first.labels.should eq ["pipeline", "group"]
      statuses.first.paused.should be_false
      statuses.first.running.should be_false
      statuses.first.percent("pending").should eq 100.0
    end

    it "handles multiple groups" do
      job = Job.from_json("{\"groups\":[\"group1\",\"group2\"], \"name\":\"\", \"next_build\":null, \"finished_build\":null}")
      pipeline = Pipeline.from_json("{\"name\":\"pipeline\",\"paused\":false}")
      statuses = MyData.statuses([ {pipeline, job} ])

      statuses.size.should eq 2
      statuses[0].labels.should eq ["pipeline", "group1"]
      statuses[0].paused.should be_false
      statuses[1].labels.should eq ["pipeline", "group2"]
      statuses[1].paused.should be_false
    end

    it "handles paused" do
      job = Job.from_json("{\"groups\":[], \"name\":\"\", \"next_build\":null, \"finished_build\":null}")
      pipeline = Pipeline.from_json("{\"name\":\"pipeline\",\"paused\":true}")
      statuses = MyData.statuses([ {pipeline, job} ])

      statuses.size.should eq 1
      statuses.first.paused.should be_true
    end
  end
end
