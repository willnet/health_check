require 'spec_helper'

RSpec.describe HealthCheck, type: :request do
  context '/health_check' do
    it 'works with smtp server and valid custom_check' do
      enable_custom_check do
        start_smtp_server do
          get '/health_check'
          expect(response).to be_ok
        end
      end
    end

    it 'fails with no smtp server and valid custom_check' do
      enable_custom_check do
        get '/health_check'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end

    it 'fails with smtp server and invalid custom_check' do
      start_smtp_server do
        get '/health_check'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end
  end

  context '/health_check/all' do
    it 'works with smtp server and valid custom_check' do
      enable_custom_check do
        start_smtp_server do
          get '/health_check/all'
          expect(response).to be_ok
        end
      end
    end

    it 'fails with no smtp server and valid custom_check' do
      enable_custom_check do
        get '/health_check/all'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end

    it 'fails with smtp server and invalid custom_check' do
      start_smtp_server do
        get '/health_check/all'
        expect(response.status).to eq(550)
        expect(response.body).to include 'health_check failed'
      end
    end
  end

  context '/health_check/migration' do
    after do
      Dir.glob('spec/dummy/db/migrate/*').each do |f|
        FileUtils.rm(f)
      end
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::Tasks::DatabaseTasks.drop_current
      end
    end

    it 'works with no migration files' do
      get '/health_check/migration'
      expect(response).to be_ok
    end

    it 'fails with pending migration files' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        get '/health_check/migration'
      end
      expect(response.status).to eq(550)
    end

    it 'works with applied migration files' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
        get '/health_check/migration'
      end
      expect(response).to be_ok
    end
  end

  describe '/health_check/database' do
    after do
      Dir.glob('spec/dummy/db/migrate/*').each do |f|
        FileUtils.rm(f)
      end
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::Tasks::DatabaseTasks.drop_current
      end
    end

    it 'works with no database' do
      get '/health_check/database'
      expect(response).to be_ok
    end

    it 'works with valid database' do
      FileUtils.cp('spec/fixtures/migrate/9_create_countries.rb', 'spec/dummy/db/migrate/')
      FileUtils.cd(FakeApp.config.root) do
        ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths).migrate
        get '/health_check/database'
      end
      expect(response).to be_ok
    end

    it 'fails with invalid database' do
      ActiveRecord::Tasks::DatabaseTasks.migration_connection.disconnect!
      Rails.root.join('db/test.sqlite3').write('invalid')
      get '/health_check/database'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end
  end

  describe '/health_check/email' do
    it 'works with smtp server' do
      start_smtp_server do
        get '/health_check/email'
        expect(response).to be_ok
      end
    end

    it 'fails with no smtp server' do
      get '/health_check/email'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end
  end

  describe '/health_check/pass (a custom check does nothing)' do
    it 'works if another custom check is invalid' do
      get '/health_check/pass'
      expect(response).to be_ok
    end

    it 'works if another custom check is valid' do
      enable_custom_check do
        get '/health_check/pass'
        expect(response).to be_ok
      end
    end
  end

  describe '/heath_check/custom' do
    it 'works with valid custom check' do
      enable_custom_check do
        get '/health_check/custom'
      end
      expect(response).to be_ok
    end

    it 'fails with invalid custom check' do
      get '/health_check/custom'
      expect(response.status).to eq(550)
      expect(response.body).to include 'health_check failed'
    end

    context 'specified format' do
      it 'returns plain text if client requests html format' do
        enable_custom_check do
          get '/health_check/custom.html'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('text/plain')
      end

      it 'returns json if client requests json format' do
        enable_custom_check do
          get '/health_check/custom.json'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('application/json')
        expect(response.parsed_body).to include('healthy' => true, 'message' => 'custom_success_message')
      end

      it 'returns xml if client requests xml format' do
        enable_custom_check do
          get '/health_check/custom.xml'
        end
        expect(response).to be_ok
        expect(response.content_type).to include('application/xml')
        expect(response.body).to include('<healthy type="boolean">true</healthy>')
        expect(response.body).to include('<message>custom_success_message</message>')
      end
    end
  end
end
