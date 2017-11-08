require "http/client"
require "json"

def giphy(q : String) : String?
  if ENV["GIPHY_API_KEY"]?
    response = HTTP::Client.get "https://api.giphy.com/v1/gifs/search?api_key=#{ENV["GIPHY_API_KEY"]}&limit=1&offset=#{Random.rand(100)}&rating=G&lang=en&q=#{URI.escape(q)}"
    data = JSON.parse(response.body)
    data["data"][0]["images"]["fixed_width"]["webp"].as_s
  end
end
