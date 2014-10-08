require_relative '../phase8/controller_base'

module Phase9
  class ControllerBase < Phase8::ControllerBase
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
end
