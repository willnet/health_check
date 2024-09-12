Bundler.setup
require 'rails'
require 'rails/all'
require 'health_check'
Bundler.require
require 'fake_app'
require 'rspec/rails'
require 'fake_smtp_server'

RSpec.configure do |config|
  config.before(:suite) do
    Thread.start do
      FakeSmtpServer.new(3555).start
    end
    FileUtils.rm(ON_SUCCESS_FILE_PATH) if File.exist?(ON_SUCCESS_FILE_PATH)
    FileUtils.rm(ON_FAILURE_FILE_PATH) if File.exist?(ON_FAILURE_FILE_PATH)
  end
end
