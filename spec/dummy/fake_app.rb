FakeApp = Class.new(Rails::Application)
ENV['RAILS_ENV'] ||= 'test'
FakeApp.config.session_store :cookie_store, key: '_myapp_session'
FakeApp.config.root = File.dirname(__FILE__)
FakeApp.config.action_mailer.delivery_method = :smtp
FakeApp.config.action_mailer.smtp_settings = { address: "localhost", port: 3555, openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE, enable_starttls_auto: true }
FakeApp.initialize!
ON_SUCCESS_FILE_PATH = 'tmp/health_check_success.txt'
ON_FAILURE_FILE_PATH = 'tmp/health_check_failure.txt'

HealthCheck.setup do |config|
  config.success = "$success"
  config.smtp_timeout = 60.0
  config.http_status_for_error_text = 550
  config.http_status_for_error_object = 555
  config.uri = '$route_prefix'
  config.origin_ip_whitelist = ENV['IP_WHITELIST'].split(',') unless ENV['IP_WHITELIST'].blank?
  config.basic_auth_username = ENV['AUTH_USER'] unless ENV['AUTH_USER'].blank?
  config.basic_auth_password = ENV['AUTH_PASSWORD'] unless ENV['AUTH_PASSWORD'].blank?

  config.add_custom_check do
    File.exist?("spec/dummy/tmp/custom_file") ? '' : 'custom_file is missing!'
  end

  config.add_custom_check('pass') do
    ''
  end

  config.on_failure do |checks, msg|
    File.open(ON_FAILURE_FILE_PATH, 'w') do |f|
      f.puts "FAILED: #{checks}, MESSAGE: #{msg}"
    end
  end

  config.on_success do |checks|
    File.open(ON_SUCCESS_FILE_PATH, 'w') do |f|
      f.puts "PASSED: #{checks}"
    end
  end

  config.include_error_in_response_body = ENV['HIDE_ERROR_RESPONSE'].to_s !~ /^[1tTyY]/
end

