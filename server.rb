require 'websocket'
require 'socket'

module WebSocketExample
  class Server
    attr_accessor :clients

    def initialize host='localhost', port='2000'
      @tcp_server = TCPServer.new(host, port)
      @clients = []
    end

    def accept
      socket = @tcp_server.accept
      handshake = WebSocket::Handshake::Server.new

      while line = socket.gets
        handshake << line
        break if handshake.finished?
      end

      client = Client.new(socket, handshake)
      close(client) unless handshake.valid?
      @clients << client
      client.socket.write handshake
      client
    end

    def close client
      @clients.delete client
      client.socket.close
    end

    def read message, client
      # parse message from socket and send to others clients
      client.frame << message
      msg = client.frame.next

      if msg.type == :close
        close client
      else
        send(msg, client)
      end
    end

    def send msg, owner
      # send message to clients except message owner
      @clients.each do |client|
        if client.socket != owner.socket
          # TODO: allow more types
          frame = WebSocket::Frame::Outgoing::Server.new(:version => client.handshake.version, :data => msg, :type => :text)
          client.socket.write frame
        end
      end
    end
  end

  class Client
    # To store socket data that would be used later
    attr_accessor :socket, :handshake, :frame

    def initialize socket, handshake
      @socket = socket
      @handshake = handshake
      @frame = WebSocket::Frame::Incoming::Server.new(:version => handshake.version)
    end
  end
end

server = WebSocketExample::Server.new

loop do
  Thread.new(server.accept) do |client|
    while (d = client.socket.recvfrom(2000))
      server.read(d[0], client)
    end
  end
end
