class ExposeUnauthorizedHandler
  include HTTP::Handler

  def call(context)
    begin
      credentials(context)
      call_next context
    rescue ex : Unauthorized
      headers = HTTP::Headers.new
      context.response.status_code = 401
      context.response.headers["WWW-Authenticate"] = "Basic realm=\"Login Required\""
      context.response.print "Could not verify your access level for that URL.\nYou have to login with proper credentials"
    end
  end

  def credentials(context)
    if context.request.headers["Authorization"]?
      if value = context.request.headers["Authorization"]
        if value.size > 0 && value.starts_with?("Basic")
          username, password = Base64.decode_string(value["Basic".size + 1..-1]).split(":")
          context.set "credentials_username", username
          context.set "credentials_password", password
        end
      end
    end
  end
end
