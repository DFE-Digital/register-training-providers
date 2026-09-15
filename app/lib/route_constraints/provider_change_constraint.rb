module RouteConstraints
  class ProviderChangeConstraint
    STEPS = {
      "code" => %w[
        effective-academic-year
        new-code
        check-your-answers
      ]
    }.freeze

    def matches?(request)
      field = request.path_parameters[:field]
      step  = request.path_parameters[:step]

      return STEPS.key?(field) if step.blank?

      STEPS.fetch(field, []).include?(step)
    end
  end
end
