generate_openapi = ENV.fetch("OPENAPI", nil) == "1"

module OpenApiPostProcess
  extend self

  def deep_merge!(target, source)
    return target unless target && source

    source.each do |key, value|
      if target[key].is_a?(Hash) && value.is_a?(Hash)
        deep_merge!(target[key], value)
      else
        target[key] = value
      end
    end

    target
  end

  def apply_parameter_overrides!(operation, overrides)
    operation["parameters"]&.each do |parameter|
      override = overrides[parameter["name"]]
      next unless override

      parameter["description"] =
        override.is_a?(Hash) ? override["description"] : override
    end
  end

  def apply_schema_patch!(operation, path_patch)
    schema = operation.dig(
      "responses",
      "200",
      "content",
      "application/json",
      "schema"
    )

    return unless schema

    schema_patch = path_patch.dig(
      "responses",
      "200",
      "application/json",
      "schema"
    )

    deep_merge!(schema, schema_patch) if schema_patch
  end
end

if generate_openapi
  OPENAPI_DATA = YAML.load_file(
    Rails.root.join("spec/support/openapi/post_documentation.yml"),
    aliases: true
  )

  RSpec::OpenAPI.post_process_hook = lambda do |_path, _records, spec|
    spec.deep_stringify_keys!

    path_overrides = OPENAPI_DATA["paths"] || {}
    param_overrides = OPENAPI_DATA["parameters"] || {}

    spec.fetch("paths", {}).each do |route, path_data|
      path_patch = path_overrides[route]

      path_data.each do |_verb, op|
        next unless op.is_a?(Hash)

        OpenApiPostProcess.apply_parameter_overrides!(op, param_overrides)

        next unless path_patch

        op["description"] = path_patch["description"] if path_patch["description"]

        OpenApiPostProcess.apply_schema_patch!(op, path_patch)
      end
    end
  end
end
