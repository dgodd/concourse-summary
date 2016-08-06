class Job
  JSON.mapping(
    name: String,
    groups: Array(String),
    next_build: Status | Nil,
    finished_build: Status | Nil,
  )

  def group
    groups.first?
  end

  def running
    !!next_build
  end

  def status
    finished_build.try do |build|
      build.status
    end
  end
end
