require "http/client"
require "openssl/ssl/context"

class HttpClient
  @client : HTTP::Client

  def initialize(host, username, password, login_form = false)
    if ENV["SKIP_SSL_VALIDATION"]?
      context = OpenSSL::SSL::Context::Client.new
      context.verify_mode=(OpenSSL::SSL::VerifyMode::None)
    else
      context = true
    end
    @client = HTTP::Client.new(host, tls: context)

    if username.to_s.size > 0
      if login_form
        @client.basic_auth(username.to_s, password.to_s)
        resp = @client.get("/api/v1/teams/main/auth/token")
        cookie = resp.headers["Set-Cookie"].split(";").first
        @client.before_request { |request| request.headers["Cookie"] = cookie }
      else
        @client.basic_auth(username, password)
      end
    end
  end

  def get(url : String)
    begin
      @client.get(url)
    rescue OpenSSL::SSL::Error
      HTTP::Client::Response.new(500, "")
    end
  end
end

