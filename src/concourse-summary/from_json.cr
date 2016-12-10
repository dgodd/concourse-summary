def Hash.new(pull : JSON::PullParser)
  hash = new
  pull.read_object do |key|
    hash[key] = V.new(pull)
  end
  hash
end

alias GroupHash = Hash(String, Hash(String, Array(String)?)?)

def parse_groups(cs_groups : String)
  Hash(String, GroupHash).from_json(cs_groups)
end

