#! /usr/bin/env ruby
# socket通信を用いてチャットを行うRubyスクリプト（サーバサイド）

require 'socket'

# サーバクラス
class Server
  @status = 0

  def initialize(port)
    @port = port
  end

  def start
    @status = 1

    puts("mojat-server start... on:#{@port}")
    @socket = TCPServer.open(@port)

    channel = Channel.new
    while @status == 1
      connection = @socket.accept
      channel.add_user(connection)
    end

    @socket.close
  end

  def stop
    @status = 0
  end
end

# チャットを管理するクラス
class Channel
  def initialize
    @users = []
  end

  def add_user(user)
    puts("#{user} connected!")
    @users.push(user)

    Thread.start(user) do
      while (message = user.gets)
        message = "#{user.remote_address.ip_address}: #{message}"
        puts(message)
        cast(message)
      end

      remove_user(user)
    end
  end

  def remove_user(user)
    puts("#{user} disconnected!")
    @users.delete(user)
    user.close
  end

  def cast(message)
    @users.each do |user|
      user.puts(message)
    end
  end
end

# main_task
my_server = Server.new(20_000)
my_server.start
