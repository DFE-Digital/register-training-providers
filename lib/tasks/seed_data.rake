require Rails.root.join("config/environment")

namespace :seed_data do
  desc "Seed data including personas only on non production and providers"
  task import: :environment do
    unless Rails.env.production?

      PERSONAS.each do |persona_attributes|
        persona = Persona.find_or_initialize_by(email: persona_attributes[:email])
        persona.first_name = persona_attributes[:first_name]
        persona.last_name = persona_attributes[:last_name]
        persona.save!

        persona.discard! if persona_attributes[:discarded?] && persona.kept?
      end
    end

    ENV["CSV"] = ENV["CSV"] || Rails.root.join("lib/data/provider_25-26.csv").to_s

    # Make sure task can be run again (in case it was run before)
    Rake::Task["import:providers"].reenable

    # Call the import:providers task
    Rake::Task["import:providers"].invoke
  end
end
