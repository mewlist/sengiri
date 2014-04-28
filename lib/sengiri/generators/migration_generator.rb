require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

module Sengiri
  module Generators
    class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
      remove_argument :name, :attributes
      argument :group, type: :string, :banner => "SHARDING_GROUP"
      argument :name, type: :string
      argument :attributes, :type => :array, :default => [], :banner => "field[:type][:index] field[:type][:index]"

      source_root File.expand_path("../templates", __FILE__)

      def create_migration_file
        set_local_assigns!
        validate_file_name!
        migration_template @migration_template, "db/sengiri/#{self.group}/#{file_name}.rb"
      end
    end
  end
end
