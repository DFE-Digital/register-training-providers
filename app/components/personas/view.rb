module Personas
  class View < ApplicationComponent
    with_collection_parameter :persona
    attr_reader :persona, :persona_iteration

    def initialize(persona:, persona_iteration:)
      @persona = persona
      @persona_iteration = persona_iteration
      super()
    end

    def tag_args
      { text: tag_text, colour: tag_colour, classes: "govuk-tag__heading" }
    end

    def tag_text
      return "Non existence" unless persona.persisted?
      return "Soft deleted" if persona.discarded?
      return "API user" if persona.api_user?
      return "Active" if persona.active?

      "Inactive"
    end

    def tag_colour
      return "red" unless persona.persisted?
      return "grey" if persona.discarded? || !persona.active?
      return "yellow" if persona.api_user?

      "teal"
    end

    def not_last?
      !persona_iteration.last?
    end
  end
end
