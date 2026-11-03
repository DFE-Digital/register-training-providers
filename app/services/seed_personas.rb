class SeedPersonas
  include ServicePattern

  def initialize(include_system_admin: true)
    @include_system_admin = include_system_admin
  end

  def call
    PERSONAS.each do |attributes|
      persona = Persona.find_or_initialize_by(email: attributes[:email])
      persona.first_name = attributes[:first_name]
      persona.last_name = attributes[:last_name]
      persona.system_admin = attributes[:system_admin?] if include_system_admin
      persona.api_user = attributes[:api_user?]
      persona.role = attributes[:role]
      persona.save!

      persona.discard! if attributes[:discarded?] && persona.kept?
    end
  end

private

  attr_reader :include_system_admin
end
