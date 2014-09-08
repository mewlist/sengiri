require 'active_record'

shard = ENV['SHARD']
rails_env = ENV['RAILS_ENV']
if rails_env
  rails_env_list = [rails_env]
else
  rails_env_list = ['development', 'test']
end

namespace :sengiri do
  db_ns = namespace :db do
    task :load_config do
    end
  end

  namespace shard do

    namespace :db do

      dbconfs = Rails.application.config.database_configuration.select {|name|
        /^#{shard}/ =~ name
      }.select {|name|
        rails_env_list.select {|env|
          /_#{env}$/ =~ name
        }.present?
      }
      switch_db_config = lambda do
        puts "now on '#{shard}' shard."

        shard_group_dir = "db/sengiri/#{shard}"
        ActiveRecord::Base.configurations = dbconfs
        Rails.application.config.paths.add shard_group_dir

        ActiveRecord::Tasks::DatabaseTasks.seed_loader            = Rails.application
        ActiveRecord::Tasks::DatabaseTasks.env                    = Rails.env
        ActiveRecord::Tasks::DatabaseTasks.db_dir                 = Rails.application.config.paths["db"].first
        ActiveRecord::Tasks::DatabaseTasks.database_configuration = dbconfs
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths       = Rails.application.paths[shard_group_dir].to_a
        ActiveRecord::Tasks::DatabaseTasks.fixtures_path          = File.join Rails.root, 'test', 'fixtures'
      end

      execute_on_shards = lambda do |task|
        dbconfs.each do |k,dbconf|
          ActiveRecord::Base.establish_connection dbconf
          db_ns[task].execute
        end
      end

      execute_with_dbtask_env = lambda do |task|
        dbconfs.each do |k,dbconf|
          ActiveRecord::Tasks::DatabaseTasks.env = k
          db_ns[task].execute
        end
      end

      task :load_config => ['sengiri:load_task'] do
        switch_db_config.call
        db_ns['load_config'].invoke
      end

      desc "create on '#{shard}' databases"
      task :create => [:environment, :load_config] do
        execute_with_dbtask_env.call :create
      end

      desc "drop on '#{shard}' databases"
      task :drop => [:environment, :load_config] do
        execute_with_dbtask_env.call :drop
      end

      desc "migrate on '#{shard}' databases"
      task :migrate => [:environment, :load_config] do
        execute_on_shards.call :migrate
      end

      desc "rollback on '#{shard}' databases"
      task :rollback => [:environment, :load_config] do
        execute_on_shards.call :rollback
      end

      namespace :migrate do
        task :redo => [:environment, :load_config] do
          execute_on_shards.call 'migrate:redo'
        end

        # desc 'Resets your database using your migrations for the current environment'
        task :reset => [:environment, :load_config] do
          Rake::Task["sengiri:#{shard}:db:drop"]   .execute
          Rake::Task["sengiri:#{shard}:db:create"] .execute
          Rake::Task["sengiri:#{shard}:db:migrate"].execute
        end

        # desc 'Runs the "up" for a given migration VERSION.'
        task :up => [:environment, :load_config] do
          execute_on_shards.call 'migrate:up'
        end

        # desc 'Runs the "down" for a given migration VERSION.'
        task :down => [:environment, :load_config] do
          execute_on_shards.call 'migrate:down'
        end

        desc 'Display status of migrations'
        task :status => [:environment, :load_config] do
          execute_on_shards.call 'migrate:status'
        end
      end
    end
  end
end

