require Rails.root.join("config/environment")

namespace :example_data do
  desc "Create personas"
  task generate: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    PERSONAS.each do |persona_attributes|
      persona = Persona.find_or_initialize_by(email: persona_attributes[:email])
      persona.first_name = persona_attributes[:first_name]
      persona.last_name = persona_attributes[:last_name]
      persona.system_admin = persona_attributes[:system_admin?]
      persona.save!

      persona.discard! if persona_attributes[:discarded?] && persona.kept?
    end

    ["import:providers_xlsx", "generate:contacts"].each do |task|
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end
end
