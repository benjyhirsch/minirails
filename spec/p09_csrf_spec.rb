require 'uri'
require 'webrick'
require 'phase9/controller_base'

describe Phase9::ControllerBase do
  before(:all) do
    class CatsController < Phase9::ControllerBase
      protect_from_forgery

      def action
        render_content "responded", "text/text"
      end
    end
  end
  after(:all) { Object.send(:remove_const, "CatsController") }

  let(:req) { WEBrick::HTTPRequest.new(Logger: nil) }
  let(:res) { WEBrick::HTTPResponse.new(HTTPVersion: '1.0') }
  let(:cats_controller) { CatsController.new(req, res) }

  describe '#protect_from_forgery' do
    it "initializes authenticity token" do
      expect(cats_controller.form_authenticity_token).not_to be_nil
    end

    it "responds to get request" do
      allow(req).to receive(:request_method).and_return("GET")
      expect { cats_controller.invoke_action(:action) }.not_to raise_error
    end

    it "raises exception when request does not give valid token" do
      body = URI.encode_www_form("authenticity_token" => "invalid")
      allow(req).to receive(:body).and_return(body)
      allow(req).to receive(:request_method).and_return("POST")
      expect do
        cats_controller.invoke_action(:action)
      end.to raise_error "invalid authenticity token"
    end

    it "responds to request with valid token" do
      allow(req).to receive(:request_method).and_return("GET")
      cats_controller.invoke_action(:action)

      req2 = WEBrick::HTTPRequest.new(Logger: nil)
      res2 = WEBrick::HTTPResponse.new(HTTPVersion: '1.0')

      token = cats_controller.form_authenticity_token
      body = URI.encode_www_form("authenticity_token" => token)

      allow(req2).to receive(:cookies).and_return(res.cookies)
      allow(req2).to receive(:body).and_return(body)
      allow(req2).to receive(:request_method).and_return("POST")

      cats_controller2 = CatsController.new(req2, res2)

      expect { cats_controller2.invoke_action(:action) }.not_to raise_error
    end
  end
end
