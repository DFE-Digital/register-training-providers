module RouteConstraints
  class ProviderChangeConstraint
    STEPS = {
      "code" => %w[
        effective-academic-year
        new-code
        check-your-answers
      ],
      "ukprn" => %w[
        effective-date
        new-ukprn
        check-your-answers
      ],
      "urn" => %w[
        effective-date
        new-urn
        check-your-answers
      ],
      "legal_name" => %w[
        effective-date
        new-legal-name
        check-your-answers
      ],
      "operating_name" => %w[
        effective-date
        new-operating-name
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
