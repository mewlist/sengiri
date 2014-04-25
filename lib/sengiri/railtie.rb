module Sengiri
  class Railtie < Rails::Railtie
    rake_tasks do
      dbdir = Rails.application.config.paths["db"].first
      dirs = Dir.glob(dbdir + '/sengiri/*').select do |f|
        FileTest::directory? f
      end
      sharding_names = dirs.map{|dir| dir.split('/').last }
      sharding_names.each do |name|
        ENV['SHARD'] = name
        load "sengiri/railties/sharding.rake"
      end

      namespace :sengiri do
        task :load_task do
          Rake.application.in_namespace(:sengiri) do
            # load activerecord databasees task in namespace
            spec     = Gem::Specification.find_by_name("activerecord")
            rakefile = spec.gem_dir + "/lib/active_record/railties/databases.rake"
            Rake.load_rakefile rakefile
          end
        end
      end
    end

    generators do
      require "sengiri/generators/sharding_generator"
      require "sengiri/generators/migration_generator"
      require "sengiri/generators/model_generator"
    end
  end
end
