module Sengiri
  module Model
    class Base < ActiveRecord::Base
      self.abstract_class = true
      attr_reader :current_shard

      def initialize(attributes = nil, options = {})
        @shard_name = self.class.shard_name
        super
      end

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
        def shard_name         ; @shard_name          end
        def sharding_group_name; @sharding_group_name end

        def shard_classes
          return @shard_class_hash.values if @shard_class_hash
          []
        end

        def sharding_group(name, confs: nil, suffix: nil)
          @dbconfs = confs if confs
          @sharding_group_name = name
          @shard_class_hash = {}
          @sharding_database_suffix = if suffix.present? then "_#{suffix}" else nil end
          first = true
          raise "Databases are not found" if shard_names.blank?
          shard_names.each do |s|
            klass = Class.new(self)
            module_name = self.name.deconstantize
            module_name = "Object" if module_name.blank?
            module_name.constantize.const_set self.name.demodulize + s, klass
            klass.instance_variable_set :@shard_name, s
            klass.instance_variable_set :@dbconfs,    dbconfs
            klass.instance_variable_set :@sharding_group_name, name
            klass.instance_variable_set :@sharding_database_suffix, @sharding_database_suffix

            #
            # first shard shares connection with base class
            #
            if first
              establish_shard_connection s
            else
              klass.establish_shard_connection s
            end
            first = false
            if defined? Ardisconnector::Middleware
              Ardisconnector::Middleware.models << klass
            end
            @shard_class_hash[s] = klass
          end
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
          @shard_names
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
          if shard_name
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

        def env
          ENV["SENGIRI_ENV"] ||= ENV["RAILS_ENV"] || 'development'
        end

        def establish_shard_connection(name)
          establish_connection dbconfs["#{@sharding_group_name}_shard_#{name}_#{env}#{@sharding_database_suffix}"]
        end

        def has_many_with_sharding(name, scope = nil, options = {}, &extension)
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: self.to_s.foreign_key
            })
            klass.has_many_without_sharding(name, scope, new_options, extension) if block_given?
            klass.has_many_without_sharding(name, scope, new_options) unless block_given?
          end
          has_many_without_sharding(name, scope, options, extension) if block_given?
          has_many_without_sharding(name, scope, options) unless block_given?
        end

        def has_one_with_sharding(name, scope = nil, options = {})
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: self.to_s.foreign_key
            })
            klass.has_one_without_sharding(name, scope, new_options)
          end
          has_one_without_sharding(name, scope, options)
        end

        def belongs_to_with_sharding(name, scope = nil, options = {})
          class_name, scope, options = *prepare_association(name, scope, options)
          shard_classes.each do |klass|
            new_options = options.merge({
              class_name: class_name.to_s.classify + klass.shard_name,
              foreign_key: name.to_s.foreign_key
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

        alias_method_chain :has_many, :sharding
        alias_method_chain :has_one, :sharding
        alias_method_chain :belongs_to, :sharding

      end
    end
  end
end
