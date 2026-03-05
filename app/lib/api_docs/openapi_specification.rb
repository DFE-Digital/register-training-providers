module ApiDocs
  class OpenapiSpecification
    def self.as_yaml
      specification.to_yaml
    end

    def self.as_hash
      specification
    end

    def self.specification(version = "v0")
      YAML.load_file("public/openapi/#{version}.yaml", permitted_classes: [Time]).with_indifferent_access
    end

    def self.endpoints
      {
        "/info" => {
          heading: "Info",
          path: "/api/{api_version}/info",
          specifications: { get: specification.dig("paths", "/api/{api_version}/info", "get") }
        },
        "/providers" => {
          heading: "Providers",
          path: "/api/{api_version}/providers",
          specifications: { get: specification.dig("paths", "/api/{api_version}/providers", "get") }
        }
      }.with_indifferent_access
    end

    def self.has_specification?(endpoint, http_method)
      endpoints.dig("/#{endpoint}", :specifications, http_method).present?
    end
  end
end
