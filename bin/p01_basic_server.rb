require 'webrick'

server = WEBrick::HTTPServer.new Port: 8000

trap('INT') { server.shutdown }

server.mount_proc '/' do |request, response|
  response.body = request.path
  response.content_type = 'text/text'
end

server.start

