require "json"
require "kemal"
require "./concourse-summary/*"

data = MyData.get_data("buildpacks.ci.cf-app.com", nil, nil)
jobs = data.map do |pipeline,job|
  JobInfo.new(pipeline, job)
end.select do |info|
  info.running || (!(info.status == "succeeded" || info.status.nil?) && !info.paused)
end.select do |info|
  info.running
end
p jobs

