ON_SUCCESS_FILE_PATH = 'tmp/health_check_success.txt'
ON_FAILURE_FILE_PATH = 'tmp/health_check_failure.txt'
CUSTOM_CHECK_FILE_PATH = 'spec/dummy/tmp/custom_file'

HealthCheck.setup do |config|
  config.success = "custom_success_message"
  config.smtp_timeout = 60.0
  config.http_status_for_error_text = 550
  config.http_status_for_error_object = 555
  config.uri = 'custom_route_prefix'

  config.add_custom_check do
    File.exist?(CUSTOM_CHECK_FILE_PATH) ? '' : 'custom_file is missing!'
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
