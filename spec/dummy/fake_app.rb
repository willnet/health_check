FakeApp = Class.new(Rails::Application)
ENV['RAILS_ENV'] ||= 'test'
FakeApp.config.session_store :cookie_store, key: '_myapp_session'
FakeApp.config.root = File.dirname(__FILE__)
FakeApp.config.action_mailer.delivery_method = :smtp
FakeApp.config.action_mailer.smtp_settings = { address: "localhost", port: 3555, openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE, enable_starttls_auto: true }
FakeApp.initialize!


