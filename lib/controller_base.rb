require 'active_support/inflector'

class ControllerBase
  attr_reader :req, :res, :params

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @already_built_response = false
    @params = Params.new(req, route_params)
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "already built response" if already_built_response?
    @res.status = 302
    @res['location'] = url
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, type)
    raise "already built response" if already_built_response?
    @res.body = content
    @res.content_type = type
    @already_built_response = true
    session.store_session(res)
    flash.store_flash(res)
  end

  def render(template_name)
    ivar_binding = binding
    controller_name = self.class.name.underscore
    f = File.read("views/#{controller_name}/#{template_name}.html.erb")
    html = ERB.new(f).result(ivar_binding)
    render_content(html, 'text/html')
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render name unless already_built_response?
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # method exposing a `Flash` object
  def flash
    @flash ||= Flash.new(req)
  end

  # csrf protection
  def self.protect_from_forgery
    class_eval(<<-RUBY)
      def form_authenticity_token
        session["authenticity_token"]
      end

      def invoke_action(name)
        unless req.request_method.downcase == 'get' ||
          params["authenticity_token"] == session["authenticity_token"]
          raise "invalid authenticity token"
        end
        super
      end

      def session
        super["authenticity_token"] ||= SecureRandom.urlsafe_base64
        @session
      end
    RUBY
  end
end
