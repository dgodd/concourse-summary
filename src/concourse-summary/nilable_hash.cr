require "json"

class NilableHash(K,V) < Hash(K,V)
end
def NilableHash.new(pull : JSON::PullParser)
  hash = new
  pull.read_object do |key|
    if pull.kind == :null
      hash[key] = nil
      pull.read_next
    else
      hash[key] = V.new(pull)
    end
  end
  hash
end
