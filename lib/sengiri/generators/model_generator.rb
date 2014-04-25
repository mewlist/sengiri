require 'rails/generators/active_record'
require 'rails/generators/active_record/model/model_generator'

module Sengiri
  module Generators
    class ModelGenerator < ActiveRecord::Generators::ModelGenerator
      remove_argument :name, :attributes
      argument :group, type: :string, :banner => "SHARDING_GROUP"
      argument :name, type: :string
      argument :attributes, :type => :array, :default => [], :banner => "field[:type][:index] field[:type][:index]"

      source_root File.expand_path("../templates", __FILE__)

      def create_migration_file
        return unless options[:migration] && options[:parent].nil?
        attributes.each { |a| a.attr_options.delete(:index) if a.reference? && !a.has_index? } if options[:indexes] == false
        migration_template "create_table_migration.rb", "db/sengiri/#{self.group}/create_#{table_name}.rb"
      end

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      def create_module_file
        return if regular_class_path.empty?
        template 'module.rb', File.join('app/models', "#{class_path.join('/')}.rb") if behavior == :invoke
      end
      protected

      # Used by the migration template to determine the parent name of the model
        def parent_class_name
          options[:parent] || "Sengiri::Model::Base"
        end
    end
  end
end
