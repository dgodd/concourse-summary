macro json_or_html(obj, view)
  if env.request.headers["Accept"] == "application/json"
    env.response.headers["Access-Control-Allow-Origin"] = "*"
    env.response.content_type = "application/json"
    {{obj}}.to_json
  else
    render "views/#{{{view}}}.ecr", "views/layout.ecr"
  end
end
