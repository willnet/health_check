Bundler.setup
require 'rails'
require 'rails/all'
require 'health_check'
Bundler.require
require_relative './dummy/fake_app'
require 'rspec/rails'
require 'fake_smtp_server'

RSpec.configure do |config|
  config.before(:suite) do
    FileUtils.rm(ON_SUCCESS_FILE_PATH) if File.exist?(ON_SUCCESS_FILE_PATH)
    FileUtils.rm(ON_FAILURE_FILE_PATH) if File.exist?(ON_FAILURE_FILE_PATH)
  end
end

def start_smtp_server
  Thread.start do
    FakeSmtpServer.new(3555).start
  end
  sleep 1
end

def stop_smtp_server
  socket = TCPSocket.open('localhost', 3555)
  socket.write('QUIT')
  socket.close
end
