require "json"
require "./status"

class Resource
  JSON.mapping(
    name: String,
    broken: {type: Bool, default: false, key: "failing_to_check"},
  )

  def self.broken(client, url : String): Hash(String, Bool)
    hash = Hash(String, Bool).new(false)
    self.all(client, url).each do |r|
      hash[r.name] = r.broken if r.broken
    end
    hash
  end

  def self.all(client, url : String)
    response = client.get("/api/v1#{url}/resources")
    begin
      Array(Resource).from_json(response.body)
    rescue ex
      puts "EXCEPTION: #{url}"
      [] of Resource
    end
  end
end
