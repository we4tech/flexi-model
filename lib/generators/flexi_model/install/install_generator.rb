module FlexiModel
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)

      # Implement the required interface for Rails::Generators::Migration.
      def self.next_migration_number(dirname) #:nodoc:
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def generate_install
        Dir.glob(File.join(File.dirname(__FILE__), 'templates/*.rb')).each do |file|
          migration_template file, "db/migrate/#{file.split('/').last}"
        end
      end
    end
  end
end