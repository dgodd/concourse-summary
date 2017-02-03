require "json"
require "kemal"
require "./concourse-summary/*"

class JobInfo
  JSON.mapping(
    pipeline: String,
    name: String,
    url: String,
    running: Bool,
    status: String?,
    run_time: String?,
  )
  def initialize(pipeline : Pipeline, job : Job)
    @pipeline = pipeline.name
    @name = job.name
    @url = pipeline.url
    @running = !!job.next_build
    @status = job.status
    job.finished_build.try do |build|
      if build.start_time
        if build.end_time
          run_time = build.end_time - build.start_time
          @run_time = Time::Span.new(0, 0, run_time.to_i64).to_s
        end
      end
    end
  end
end

data = MyData.get_data("buildpacks.ci.cf-app.com", nil, nil)
jobs = data.select do |pipeline,job|
  !pipeline.paused &&
    (job.next_build ||
      (job.finished_build && job.status != "succeeded"))
end.map do |pipeline,job|
  JobInfo.new(pipeline, job)
end
p jobs

