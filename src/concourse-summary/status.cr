class Status
  JSON.mapping(
    status: String,
    name: String,
    start_time: Int64?,
    end_time: Int64?,
  )
end
