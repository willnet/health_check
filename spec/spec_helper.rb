Bundler.setup
require 'rails'
require 'rails/all'
require 'health_check'
require 'fake_app'
Bundler.require
require 'rspec/rails'

RSpec.configure do |config|
end
