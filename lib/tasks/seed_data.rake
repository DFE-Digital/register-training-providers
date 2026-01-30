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

    ["generate:academic_cycles",
     "import:providers",
     "import:partnerships"].each do |task|
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end
end
