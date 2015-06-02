require 'rake/testtask'
require 'config_env/rake_tasks'

task :config do
  ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
end

namespace :db do
  require_relative 'model/gem_version_spec'
  require_relative 'lib/no_sql_store'

  desc 'Create GemSpecDownload table'
  task :create => [:config] do
    begin
      NoSqlStore.new.create_table(GemMiner::GemVersionSpec, 4, 5)
      puts 'GemSpecDownload table created!'
    rescue Aws::DynamoDB::Errors::ResourceInUseException => e
      puts 'GemSpecDownload table already exists'
    rescue => e
      puts "Database error: #{e}"
    end
  end
end

namespace :run do
  task :staging do
    sh 'bundle exec rackup -o 0.0.0.0 &'
  end

  task :killme do
    rackup_id = `ps a | grep rackup`.split.first
    sh "kill -9 #{rackup_id}"
  end
end
