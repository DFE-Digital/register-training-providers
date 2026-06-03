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

    def self.endpoint_table(path, method = "get")
      schema = endpoints.dig(
        path,
        :specifications,
        method,
        "responses",
        "200",
        "content",
        "application/json",
        "schema"
      )

      schema_to_table(schema)
    end

    def self.schema_to_table(schema, prefix = nil, required = [])
      return [] unless schema.is_a?(Hash)

      type = schema["type"]

      case type
      when "object"
        object_to_table(schema, prefix, required)

      when "array"
        array_to_table(schema, prefix, required)

      else
        scalar_to_table(schema, prefix, required)
      end
    end

    def self.object_to_table(schema, prefix, _required)
      properties = schema["properties"] || {}
      required_fields = schema["required"] || []

      properties.flat_map do |key, value|
        path = [prefix, key].compact.join(".")

        schema_to_table(
          value,
          path,
          required_fields
        )
      end
    end

    def self.array_to_table(schema, prefix, required)
      rows = []

      rows << build_row(
        schema,
        prefix,
        type_override: "array",
        required: required
      )

      items = schema["items"]
      return rows unless items

      rows + schema_to_table(items, "#{prefix}[]", required)
    end

    def self.scalar_to_table(schema, prefix, required)
      [
        build_row(
          schema,
          prefix,
          required:
        )
      ]
    end

    def self.build_row(schema, prefix, required:, type_override: nil)
      {
        field: prefix,
        type: type_override || schema["type"],
        format: schema["format"],
        required: required.include?(prefix&.split(".")&.last),
        description: schema["description"],
        example: schema["example"],
        enum: schema["enum"],
        nullable: schema["nullable"]
      }.compact
    end
  end
end
