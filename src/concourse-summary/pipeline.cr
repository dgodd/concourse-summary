require "json"

class Pipeline
  JSON.mapping(
    name: String,
    paused: Bool
  )
end
