# lib/tasks/schema_cleanup.rake

# First, clear the existing task so we can redefine it
Rake::Task["db:schema:dump"].clear

namespace :db do
  task "schema:dump" => [ "environment" ] do
    require "active_record/tasks/database_tasks"

     config = ActiveRecord::Base.connection_db_config
     ActiveRecord::Tasks::DatabaseTasks.dump_schema(config)

     schema_file = Rails.root.join("db/schema.rb")
     if File.exist?(schema_file)
       cleaned = File.readlines(schema_file).reject do |line|
         line.include?('enable_extension "pg_catalog.plpgsql"')
       end
       File.write(schema_file, cleaned.join)
       puts "✅ Removed 'enable_extension \"pg_catalog.plpgsql\"' from schema.rb"
     end
  end
end
