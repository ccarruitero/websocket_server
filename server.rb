require 'faye/websocket'

@clients = []
KEEPALIVE_TIME = ENV['KEEP_ALIVE']

App = lambda do |env|
  ws = Faye::WebSocket.new(env)

  ws.on :open do |event|
    p [:open, ws.object_id]
    @clients << ws
  end

  ws.on :message do |event|
    p [:message, event.data]
    @clients.each do |cli|
      cli.send(event.data)
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    @clients.delete(ws)
    ws = nil
  end

  # Return async Rack response
  puts 'websocket server initiated'
  ws.rack_response

end
