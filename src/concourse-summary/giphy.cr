require "http/client"
require "json"

CACHE = Hash(String, Array(String)).new

def giphy(q : String) : Array(String)?
  if ENV["GIPHY_API_KEY"]?
    return CACHE[q] if CACHE.has_key?(q)
    response = HTTP::Client.get "https://api.giphy.com/v1/gifs/search?api_key=#{ENV["GIPHY_API_KEY"]}&limit=100&rating=G&lang=en&q=#{URI.escape(q)}"
    data = JSON.parse(response.body)
    CACHE[q] = data["data"].map do |img|
      img["images"]["fixed_width"]["url"].as_s
    end
  end
end
