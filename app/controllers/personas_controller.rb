class PersonasController < ApplicationController
  skip_before_action :authenticate

  def index
    @personas = Persona.order(:email) + [Persona.non_existing_persona]
  end
end
