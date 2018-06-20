#! /usr/bin/env ruby
# socket通信を用いてチャットを行うRubyスクリプト（サーバサイド）

require 'socket'

# サーバクラス
class Server
  def initialize(port)
    @status = 0
    @port = port
  end

  def start
    @status = 1

    puts("mojat-server start... on:#{@port}")
    @socket = TCPServer.open(@port)

    id = 0  # TODO: 現在ただの連番なのでなんとかする 一意であればOK
    channel = Channel.new
    while @status == 1
      user = User.new(@socket.accept)
      user.id = id
      user.name = "名無し#{user.id}"  # 初期名
      channel.add_user(user)

      id += 1
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
    puts("#{user.to_s} connected!")
    @users.push(user)

    Thread.start(user) do
      while (message = Message.new(user.gets))
        puts("#{user.to_s}: [#{message.command}] #{message.payload}")
        cast(message.to_s)
      end

      remove_user(user)
    end
  end

  def remove_user(user)
    puts("#{user.to_s} disconnected!")
    @users.delete(user)
    user.close
  end

  def cast(message)
    @users.each do |user|
      user.puts(message)
    end
  end
end

# 接続したユーザを管理するクラス
class User
  attr_accessor(:id, :name)

  def initialize(connection)
    @connection = connection
  end

  # TCPSocketクラスの一部メソッドのラッパ
  def gets
    @connection.gets
  end

  def puts(message)
    @connection.puts(message)
  end

  def ip
    @connection.remote_address.ip_address
  end

  def to_s
    "#{name}\##{id} (#{ip})"
  end
end

# クライアントとやりとりするメッセージのクラス
# プロトコルの策定が面倒なのと、Javaでは標準APIでJSONが扱えないので、移植のことを考えて単純にスペース区切りのStringでメッセージとする。
class Message
  attr_accessor(:command, :payload)

  def initialize(string = '')
    if string
      # TODO: メッセージタイプごとの実装

      tmp = string.split(' ')
      @command = tmp[0]
      @payload = tmp[1]
    end
  end

  def to_s
    "#{@command} #{@payload}"
  end
end

# main_task
my_server = Server.new(20_000)
my_server.start
