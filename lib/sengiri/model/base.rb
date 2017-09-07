module Sengiri
  module Model
    class Base < ActiveRecord::Base
      self.abstract_class = true
      attr_reader :current_shard

      def sharding_group_name
        self.class.instance_variable_get :@sharding_group_name
      end

      def shard_name
        self.class.instance_variable_get :@shard_name
      end

      def narrowcast(association)
        foreign_key = self.class.table_name.singularize.foreign_key
        association.to_s.classify.constantize.shard(shard_name).where(foreign_key => id)
      end

      class << self
        attr_reader :shard_name, :sharding_group_name

        def shard_classes
          return @shard_class_hash.values if @shard_class_hash
          []
        end

        def sharding_group(group_name, confs: nil, suffix: nil)
          @dbconfs = confs
          @sharding_group_name = group_name
          @shard_class_hash = {}
          @sharding_database_suffix = suffix.presence && "_#{suffix}"

          raise "Databases are not found" if shard_names.blank?

          @sharding_base = true
          @shard_name = shard_names.first
          establish_shard_connection

          shard_names.each do |s|
            klass = Class.new(self)
            module_name = self.name.deconstantize
            module_name = "Object" if module_name.blank?
            module_name.constantize.const_set self.name.demodulize + s, klass

            klass.instance_variable_set :@shard_name, s
            klass.instance_variable_set :@dbconfs,    dbconfs
            klass.instance_variable_set :@sharding_group_name, group_name
            klass.instance_variable_set :@sharding_database_suffix, @sharding_database_suffix

            if klass.connection_specification_name != connection_specification_name
              klass.establish_shard_connection
            end

            if defined? Ardisconnector::Middleware
              Ardisconnector::Middleware.models << klass
            end
            @shard_class_hash[s] = klass
          end
        end

        def connection_specification_name
          "#{@sharding_group_name}_shard_#{@shard_name}"
        end

        def dbconf
          dbconfs["#{connection_specification_name}_#{env}#{@sharding_database_suffix}"]
        end

        def dbconfs
          if defined? Rails
            @dbconfs ||= Rails.application.config.database_configuration.select {|name|
              /^#{@sharding_group_name}/ =~ name
            }.select {|name|
              /#{env}#{@sharding_database_suffix}$/ =~ name
            }

          end
          @dbconfs
        end

        def shard_names
          @shard_names ||= dbconfs.map do |k,v|
            k.gsub("#{@sharding_group_name}_shard_", '').gsub(/_#{env}#{@sharding_database_suffix}$/, '')
          end
        end

        def establish_shard_connection
          resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(Base.configurations)
          spec = resolver.resolve(dbconf).symbolize_keys
          spec[:name] = connection_specification_name

          connection_handler.establish_connection(spec)
        end

        def shard(name)
          if block_given?
            yield @shard_class_hash[name.to_s]
          end
          @shard_class_hash[name.to_s]
        end

        def shards(&block)
          transaction do
            shard_names.each do |shard_name|
              block.call shard(shard_name)
            end
          end
        end

        def transaction(klasses=shard_classes, &block)
          if @sharding_base.nil?
            super &block
          else
            if klasses.length > 0
              klass = klasses.pop
              klass.transaction do
                transaction klasses, &block
              end
            else
              yield
            end
          end
        end

        def broadcast(max_threads=5)
          Sengiri::BroadcastProxy.new(shard_classes, scope: current_scope, max_threads: max_threads)
        end

        def env
          ENV["SENGIRI_ENV"] ||= ENV["RAILS_ENV"] || 'development'
        end

        alias_method :has_many_without_sharding, :has_many
        alias_method :has_one_without_sharding, :has_one
        alias_method :belongs_to_without_sharding, :belongs_to

        def has_many(name, scope = nil, options = {}, &extension)
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: options[:foreign_key] || self.to_s.foreign_key
            })
            klass.has_many_without_sharding(name, scope, new_options, extension) if block_given?
            klass.has_many_without_sharding(name, scope, new_options) unless block_given?
          end
          has_many_without_sharding(name, scope, options, extension) if block_given?
          has_many_without_sharding(name, scope, options) unless block_given?
        end

        def has_one(name, scope = nil, options = {})
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: options[:foreign_key] || self.to_s.foreign_key
            })
            klass.has_one_without_sharding(name, scope, new_options)
          end
          has_one_without_sharding(name, scope, options)
        end

        def belongs_to(name, scope = nil, options = {})
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: options[:foreign_key] || name.to_s.foreign_key
            })
            klass.belongs_to_without_sharding(name, scope, new_options)
          end
          belongs_to_without_sharding(name, scope, options)
        end

        def constantize(name)
          name.to_s.singularize.classify.constantize
        end

        def prepare_association(name, scope, options)
          if scope.is_a?(Hash)
            options = scope
            scope   = nil
          end
          class_name = options[:class_name] || name
          constantize(class_name)
          [class_name, scope, options]
        end
      end
    end
  end
end
