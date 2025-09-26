require Rails.root.join("config/environment")

namespace :example_data do
  desc "Create personas"
  task generate: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    PERSONAS.each do |persona_attributes|
      persona = Persona.find_or_initialize_by(email: persona_attributes[:email])
      persona.first_name = persona_attributes[:first_name]
      persona.last_name = persona_attributes[:last_name]
      persona.save!

      persona.discard! if persona_attributes[:discarded?] && persona.kept?
    end

    ENV["CSV"] = ENV["CSV"] || Rails.root.join("lib/data/seed-providers.csv").to_s

    # Make sure task can be run again (in case it was run before)
    Rake::Task["import:providers"].reenable

    # Call the import:providers task
    Rake::Task["import:providers"].invoke

    # Make sure accreditation task can be run again (in case it was run before)
    Rake::Task["generate:accreditations"].reenable

    # Call the generate:accreditations task
    Rake::Task["generate:accreditations"].invoke

    # Make sure addresses task can be run again (in case it was run before)
    Rake::Task["generate:addresses"].reenable

    # Call the generate:addresses task
    Rake::Task["generate:addresses"].invoke
  end
end
