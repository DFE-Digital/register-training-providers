module Personas
  class View < ApplicationComponent
    with_collection_parameter :persona
    attr_reader :persona, :persona_iteration

    def initialize(persona:, persona_iteration:)
      @persona = persona
      @persona_iteration = persona_iteration
      super()
    end

    def tags
      if active_api_user?
        return [{ text: "API user", colour: "yellow" },
                { text: UserRoleEnum.label_for(UserRoleEnum::RO), colour: "magenta" }]
      end

      [{ text: tag_text, colour: tag_colour }]
    end

    def tag_text
      return "Non existence" unless persona.persisted?
      return "Soft deleted" if persona.discarded?
      return "Inactive" unless persona.active?
      return "API user" if persona.api_user?
      return persona.role_label if persona.role.present?

      "No role"
    end

    def tag_colour
      return "red" unless persona.persisted?
      return "grey" if persona.discarded? || !persona.active?
      return "yellow" if persona.api_user?
      return "teal" if persona.reg?
      return "blue" if persona.mr?
      return "purple" if persona.bat?
      return "magenta" if persona.ro?

      "grey"
    end

    def description
      return "No matching account" unless persona.persisted?
      return "Soft deleted account" if persona.discarded?
      return "API client administration and view-only access to authorised Register information" if persona.api_user?

      persona.role_description
    end

    def not_last?
      !persona_iteration.last?
    end

  private

    def active_api_user?
      persona.persisted? && !persona.discarded? && persona.active? && persona.api_user?
    end
  end
end
