require 'json'
require 'webrick'

class Flash
  # find the cookie for this app
  # deserialize the cookie into a hash
  attr_reader :now

  def initialize(req)
    cookie = req.cookies.find do |cookie|
      cookie.name == '_rails_lite_app_flash'
    end
    @now = cookie ? JSON.parse(cookie.value) : Hash.new
    @next = Hash.new
  end


  def [](key)
    @now[key]
  end

  def []=(key, val)
    @now[key] = val
    @next[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_flash(res)
    res.cookies << WEBrick::Cookie.new('_rails_lite_app_flash', @next.to_json)
  end
end
