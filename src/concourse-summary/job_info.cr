class JobInfo
  JSON.mapping(
    pipeline: String,
    name: String,
    groups: Array(String),
    url: String,
    paused: Bool,
    running: Bool,
    status: String?,
    start_time: Int64?,
    run_time: String?,
    latest_build_num: String,
  )
  def initialize(pipeline : Pipeline, job : Job)
    @pipeline = pipeline.name
    @name = job.name
    @url = pipeline.url
    @groups = job.groups.select { |x| x.is_a?(String) }.map { |x| x.as(String) }
    @paused = pipeline.paused
    @running = !job.next_build.nil?
    @status = job.status
    job.finished_build.try do |build|
      build.start_time.try do |start_time|
        @start_time = start_time
        build.end_time.try do |end_time|
          run_time = end_time - start_time
          @run_time = Time::Span.new(0, 0, run_time.to_i64).to_s
        end
      end
    end
    job.next_build.try do |build|
      build.start_time.try do |start_time|
        @start_time = start_time
        run_time = Time.now.epoch - start_time
        @run_time = Time::Span.new(0, 0, run_time.to_i64).to_s
      end
    end

    @latest_build_num = "NA"
    job.finished_build.try do |build|
      @latest_build_num = build.name
    end
    job.next_build.try do |build|
      @latest_build_num = build.name
    end
  end

  def start_time_ago_days
    start_time.try do |start|
      (Time.now - Time.epoch(start)).days
    end
  end

  def latest_build

  end
end

