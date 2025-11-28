module RouteConstraints
  class RegisterApiConstraint
    AVAILABLE_VERSIONS = ["v0"].freeze

    def self.matches?(request)
      AVAILABLE_VERSIONS.include?(request.path_parameters[:api_version])
    end
  end
end
