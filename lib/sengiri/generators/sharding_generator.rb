module Sengiri
  module Generators
    class GroupGenerator < Rails::Generators::NamedBase
      def create_directories
        empty_directory "db/sengiri/#{file_name}"
      end
    end
  end
end
