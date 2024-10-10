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

def start_smtp_server(&block)
  th = Thread.start do
    server = FakeSmtpServer.new(3555)
    server.start
    server.finish
  end
  sleep 1
  block.call
  socket = TCPSocket.open('localhost', 3555)
  socket.write('QUIT')
  socket.close
  th.join
end

def enable_custom_check(&block)
  File.write(CUSTOM_CHECK_FILE_PATH, 'hello')
  block.call
ensure
  FileUtils.rm(CUSTOM_CHECK_FILE_PATH)
end
