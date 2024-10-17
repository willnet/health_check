require 'spec_helper'

RSpec.describe HealthCheck, type: :request do
  context '/custom_route_prefix' do
    it 'works with smtp server and valid custom_check' do
      enable_custom_check do
        start_smtp_server do
          get '/custom_route_prefix'
          expect(response).to be_ok
        end
      end
    end

    it 'fails with no smtp server and valid custom_check' do
      enable_custom_check do
        get '/custom_route_prefix'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end

    it 'fails with smtp server and invalid custom_check' do
      start_smtp_server do
        get '/custom_route_prefix'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end
  end

  context '/custom_route_prefix/all' do
    it 'works with smtp server and valid custom_check' do
      enable_custom_check do
        start_smtp_server do
          get '/custom_route_prefix/all'
          expect(response).to be_ok
        end
      end
    end

    it 'fails with no smtp server and valid custom_check' do
      enable_custom_check do
        get '/custom_route_prefix/all'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end

    it 'fails with smtp server and invalid custom_check' do
      start_smtp_server do
        get '/custom_route_prefix/all'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end
  end

  context '/custom_route_prefix/migration' do
    after do
      Dir.glob('spec/dummy/db/migrate/*').each do |f|
        FileUtils.rm(f)
      end
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::Tasks::DatabaseTasks.drop_current
      end
    end

    it 'works with no migration files' do
      get '/custom_route_prefix/migration'
      expect(response).to be_ok
    end

    it 'fails with pending migration files' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        get '/custom_route_prefix/migration'
      end
      expect(response.status).to eq(550)
    end

    it 'works with applied migration files' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
        get '/custom_route_prefix/migration'
      end
      expect(response).to be_ok
    end
  end

  describe '/custom_route_prefix/database' do
    after do
      Dir.glob('spec/dummy/db/migrate/*').each do |f|
        FileUtils.rm(f)
      end
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::Tasks::DatabaseTasks.drop_current
      end
    end

    it 'works with no database' do
      get '/custom_route_prefix/database'
      expect(response).to be_ok
    end

    it 'works with valid database' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
        get '/custom_route_prefix/database'
      end
      expect(response).to be_ok
    end

    it 'fails with invalid database' do
      ActiveRecord::Tasks::DatabaseTasks.migration_connection.disconnect!
      Rails.root.join('db/test.sqlite3').write('invalid')
      get '/custom_route_prefix/database'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end
  end

  describe '/custom_route_prefix/email' do
    it 'works with smtp server' do
      start_smtp_server do
        get '/custom_route_prefix/email'
        expect(response).to be_ok
      end
    end

    it 'fails with no smtp server' do
      get '/custom_route_prefix/email'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end
  end

  describe '/custom_route_prefix/pass (a custom check does nothing)' do
    it 'works if another custom check is invalid' do
      get '/custom_route_prefix/pass'
      expect(response).to be_ok
    end

    it 'works if another custom check is valid' do
      enable_custom_check do
        get '/custom_route_prefix/pass'
        expect(response).to be_ok
      end
    end
  end

  describe '/heath_check/custom' do
    it 'works with valid custom check' do
      enable_custom_check do
        get '/custom_route_prefix/custom'
      end
      expect(response).to be_ok
    end

    it 'fails with invalid custom check' do
      get '/custom_route_prefix/custom'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end

    context 'specified format' do
      it 'returns plain text if client requests html format' do
        enable_custom_check do
          get '/custom_route_prefix/custom.html'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('text/plain')
      end

      it 'returns json if client requests json format' do
        enable_custom_check do
          get '/custom_route_prefix/custom.json'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('application/json')
        expect(response.parsed_body).to include('healthy' => true, 'message' => 'custom_success_message')
      end

      it 'returns json if client requests json format and custom check is invalid' do
        get '/custom_route_prefix/custom.json'
        expect(response.status).to eq(555) # config.http_status_for_error_object = 555
        expect(response.content_type).to include('application/json')
        expect(response.parsed_body).to include('healthy' => false)
      end

      it 'returns xml if client requests xml format' do
        enable_custom_check do
          get '/custom_route_prefix/custom.xml'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('application/xml')
        expect(response.body).to include('<healthy type="boolean">true</healthy>')
        expect(response.body).to include('<message>custom_success_message</message>')
      end

      it 'returns xml if client requests xml format and custom check is invalid' do
        get '/custom_route_prefix/custom.xml'
        expect(response.status).to eq(555) # config.http_status_for_error_object = 555
        expect(response.content_type).to include('application/xml')
        expect(response.body).to include('<healthy type="boolean">false</healthy>')
      end
    end
  end

  describe '/custom_route_prefix/middleware' do
    if ENV['MIDDLEWARE'] == 'true'
      context 'when using middleware' do
        it 'works with valid custom check' do
          enable_custom_check do
            get '/custom_route_prefix/middleware'
          end
          expect(response).to be_ok
        end
      end
    end
    if ENV['MIDDLEWARE'] != 'true'
      context 'when not using middleware' do
        it 'fails with invalid custom check' do
          get '/custom_route_prefix/middleware'
          expect(response.status).to eq(550)
          expect(response.body).to include 'health_check failed'
        end
      end
    end
  end

  context 'whitelisted ip' do

  end
end
