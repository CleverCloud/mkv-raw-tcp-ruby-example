#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'

def format_response(response)
  response
    .gsub(/^[+*:]/, '')
    .gsub(/, \+/, ', ')
end

def read_response(socket)
  response = socket.gets("\r\n")
  if response.start_with?('$')
    length = response[1..].to_i
    response = socket.read(length + 2)
  elsif response.start_with?('*')
    length = response[1..].to_i
    response = (1..length).map { socket.gets("\r\n").strip }.join(', ')
  end
  response
end

begin
  mkv_host = 'materiakv.eu-fr-1.services.clever-cloud.com'
  mkv_port = 6378
  mkv_password = ENV['KV_TOKEN']

  raise 'KV_TOKEN is not set' if mkv_password.nil?

  commands = [
    { name: 'AUTH', command: "*2\r\n$4\r\nAUTH\r\n$#{mkv_password.length}\r\n#{mkv_password}\r\n" },
    { name: 'PING', command: "*1\r\n$4\r\nPING\r\n" },
    { name: 'SET1', command: "*3\r\n$3\r\nSET\r\n$6\r\nmy_key\r\n$9\r\nthe_value\r\n" },
    { name: 'SET2', command: "*3\r\n$3\r\nSET\r\n$7\r\nmy_key2\r\n$9\r\nthe_value\r\n" },
    { name: 'SET3', command: "*3\r\n$3\r\nSET\r\n$7\r\nmy_key3\r\n$9\r\nthe_value\r\n" },
    { name: 'KEYS', command: "*2\r\n$4\r\nKEYS\r\n$1\r\n*\r\n" },
    { name: 'GET', command: "*2\r\n$3\r\nGET\r\n$7\r\nmy_key2\r\n" },
    { name: 'DEL', command: "*2\r\n$3\r\nDEL\r\n$7\r\nmy_key3\r\n" },
    { name: 'FLUSHDB', command: "*1\r\n$7\r\nFLUSHDB\r\n" }
  ]

  socket = TCPSocket.open(mkv_host, mkv_port)

  commands.each do |cmd|
    socket.write(cmd[:command])
    response = read_response(socket)
    puts "#{cmd[:name]}: #{format_response(response)}"
  end

  socket.close
rescue StandardError => e
  puts "Error: #{e.message}"
end