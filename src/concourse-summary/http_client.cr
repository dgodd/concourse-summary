require "http/client"
require "openssl/ssl/context"

## FIXME - MonkeyPatch Cookies. Concourse does not accept URI.escape'd values
class HTTP::Cookie
  def to_cookie_header
    "#{@name}=#{value}"
  end
end

class HttpClient
  @client : HTTP::Client

  def initialize(host, username, password, login_form = false, team_name : String = "main")
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
        resp = @client.get("/api/v1/teams/#{team_name}/auth/token")
        cookie = resp.headers["Set-Cookie"]?
        if cookie
          cookie_name, cookie_value = cookie.split(";").first.split(/=/,2)
          @client = HTTP::Client.new(host, tls: context)
          @client.before_request do |request|
            request.cookies << HTTP::Cookie.new(cookie_name, cookie_value)
          end
        end
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

