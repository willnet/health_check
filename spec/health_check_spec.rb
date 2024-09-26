require 'spec_helper'

RSpec.describe HealthCheck, type: :request do
  it 'works' do
    get '/health_check'
    expect(response).to be_ok
  end

  context '/migration' do
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

  describe '/database' do
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
end
