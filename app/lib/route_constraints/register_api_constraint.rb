module RouteConstraints
  class RegisterApiConstraint
    AVAILABLE_VERSIONS = ["v1"].freeze

    def self.matches?(request)
      AVAILABLE_VERSIONS.include?(request.path_parameters[:api_version])
    end
  end
end
