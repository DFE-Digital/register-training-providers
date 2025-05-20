require Rails.root.join("config/environment")

namespace :example_data do
  desc "Create personas"
  task generate: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    PERSONAS.each do |persona_attributes|
      persona = Persona.find_or_create_by!(
        first_name: persona_attributes[:first_name],
        last_name: persona_attributes[:last_name],
        email: persona_attributes[:email],
      )

      persona.discard! if persona_attributes[:discarded?] && persona.kept?
    end
  end
end
