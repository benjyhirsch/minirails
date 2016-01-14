require 'json'
require 'webrick'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    cookie = req.cookies.find do |cookie|
      cookie.name == '_minirails_app'
    end
    @attributes = cookie ? JSON.parse(cookie.value) : Hash.new
  end

  def [](key)
    @attributes[key]
  end

  def []=(key, val)
    @attributes[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @attributes.to_json)
  end
end
