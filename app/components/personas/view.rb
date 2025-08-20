module Personas
  class View < ViewComponent::Base
    include ApplicationHelper

    with_collection_parameter :persona
    attr_reader :persona, :persona_iteration

    def initialize(persona:, persona_iteration:)
      @persona = persona
      @persona_iteration = persona_iteration
      super
    end

    def tag_args
      if persona.discarded?
        { text: "Soft deleted", colour: "grey" }
      elsif persona.persisted?
        { text: "Active", colour: "blue" }
      else
        { text: "Non existence", colour: "red" }
      end.merge(classes: "govuk-tag__heading")
    end

    def not_last?
      !persona_iteration.last?
    end
  end
end
