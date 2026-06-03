require "rails_helper"

RSpec.describe ApiDocs::OpenapiSpecification do
  describe ".specification" do
    it { expect(described_class.specification).to be_a(Hash) }

    it "loads a specific versioned file when provided" do
      expect(YAML).to receive(:load_file)
        .with("public/openapi/v1.yaml", permitted_classes: [Time])
        .and_return({})

      described_class.specification("v1")
    end
  end

  describe ".as_yaml" do
    it { expect(described_class.as_yaml).to be_a(String) }
  end

  describe ".as_hash" do
    it { expect(described_class.as_hash).to eq(described_class.specification) }
  end

  describe ".endpoints" do
    let(:endpoints) { described_class.endpoints }

    it "contains the expected keys" do
      expect(endpoints.keys).to contain_exactly("/info", "/providers")
    end

    it "builds a structured endpoint hash keyed by API path" do
      expect(endpoints["/info"].keys).to contain_exactly("specifications", "heading", "path")
      expect(endpoints["/providers"].keys).to contain_exactly("specifications", "heading", "path")
    end

    it "stores the correct spec fragment under the verb key" do
      spec = described_class.specification

      expect(endpoints["/info"][:specifications][:get]).to eq(
        spec.dig("paths", "/api/{api_version}/info", "get")
      )
      expect(endpoints["/providers"][:specifications][:get]).to eq(
        spec.dig("paths", "/api/{api_version}/providers", "get")
      )
    end
  end

  describe ".has_specification?" do
    it "returns true when endpoint and method exist" do
      expect(described_class.has_specification?("info", :get)).to eq(true)
    end

    it "returns false when endpoint is missing" do
      expect(described_class.has_specification?("missing", :get)).to eq(false)
    end

    it "returns false when HTTP method is missing" do
      expect(described_class.has_specification?("info", :post)).to eq(false)
    end
  end

  context "manually added descriptions" do
    let(:openapi_data) do
      YAML.load_file(
        Rails.root.join("spec/support/openapi/post_documentation.yml"),
        aliases: true
      )
    end

    let(:spec) { described_class.specification }

    def find_param(path, method, param_name)
      spec.dig("paths", path, method, "parameters")&.find { |p| p["name"] == param_name }
    end

    def find_property(prop_name)
      spec.dig(
        "paths",
        "/api/{api_version}/providers",
        "get",
        "responses",
        "200",
        "content",
        "application/json",
        "schema",
        "properties",
        "data",
        "items",
        "properties",
        prop_name
      )
    end

    context "parameters-level descriptions" do
      it "matches the post_documentation.yml for all parameters" do
        ["/api/{api_version}/info", "/api/{api_version}/providers"].each do |path|
          openapi_data["parameters"].each do |name, description_hash|
            param = find_param(path, "get", name)
            next unless param

            expect(param["description"].to_s.squish)
              .to eq(description_hash["description"].to_s.squish)
          end
        end
      end
    end

    context "operation-level descriptions" do
      it "matches the post_documentation.yml for endpoint descriptions" do
        openapi_data["paths"].each do |path_key, data|
          full_path = spec["paths"].keys.find { |k| k.include?(path_key) }
          next unless full_path

          description = spec.dig("paths", full_path, "get", "description")

          expect(description.to_s.squish)
            .to eq(data["description"].to_s.squish)
        end
      end
    end

    it "adds the data collection description" do
      data_property = spec.dig(
        "paths",
        "/api/{api_version}/providers",
        "get",
        "responses",
        "200",
        "content",
        "application/json",
        "schema",
        "properties",
        "data"
      )

      expected = openapi_data.dig(
        "paths",
        "/api/{api_version}/providers",
        "responses",
        "200",
        "application/json",
        "schema",
        "properties",
        "data",
        "description"
      )

      expect(data_property["description"]).to eq(expected)
    end

    context "provider property descriptions" do
      it "matches the post_documentation.yml for all provider properties" do
        openapi_data["provider_properties"].each do |name, data|
          property = find_property(name)

          expect(property).to be_present,
                              "Expected property '#{name}' to exist in schema"

          expect(property["description"].to_s.squish)
            .to eq(data["description"].to_s.squish)

          expect(property["example"].to_s).to eq(data["example"].to_s) if data["example"]
          expect(property["enum"]).to eq(data["enum"]) if data["enum"]
        end
      end
    end
  end

  describe ".endpoint_table" do
    it "returns a flattened schema table for providers" do
      rows = described_class.endpoint_table("/providers", :get)

      expect(rows).to be_an(Array)
      expect(rows).not_to be_empty
      expect(rows.first).to include(:field, :type)
    end

    it "returns empty array when schema is missing" do
      allow(described_class).to receive(:endpoints).and_return({
        "/test" => { specifications: { get: {} } }
      })

      expect(described_class.endpoint_table("/test", :get)).to eq([])
    end
  end

  describe ".schema_to_table" do
    let(:schema) do
      {
        "type" => "object",
        "required" => ["id"],
        "properties" => {
          "id" => {
            "type" => "string",
            "description" => "Provider identifier",
            "example" => "123"
          },
          "providers" => {
            "type" => "array",
            "description" => "List of providers",
            "items" => {
              "type" => "object",
              "required" => ["name"],
              "properties" => {
                "name" => { "type" => "string" }
              }
            }
          }
        }
      }
    end

    it "flattens object properties" do
      rows = described_class.schema_to_table(schema)

      expect(rows).to include(
        hash_including(
          field: "id",
          type: "string",
          required: true,
          description: "Provider identifier",
          example: "123"
        )
      )
    end

    it "includes array rows" do
      rows = described_class.schema_to_table(schema)

      expect(rows).to include(
        hash_including(
          field: "providers",
          type: "array",
          description: "List of providers"
        )
      )
    end

    it "flattens nested array items" do
      rows = described_class.schema_to_table(schema)

      expect(rows).to include(
        hash_including(
          field: "providers[].name",
          type: "string",
          required: true
        )
      )
    end

    it "returns an empty array for invalid schemas" do
      expect(described_class.schema_to_table(nil)).to eq([])
      expect(described_class.schema_to_table("foo")).to eq([])
      expect(described_class.schema_to_table([])).to eq([])
    end

    it "handles deeply nested objects" do
      schema = {
        "type" => "object",
        "properties" => {
          "a" => {
            "type" => "object",
            "properties" => {
              "b" => {
                "type" => "object",
                "properties" => {
                  "c" => {
                    "type" => "string",
                    "description" => "deep value"
                  }
                }
              }
            }
          }
        }
      }

      rows = described_class.schema_to_table(schema)

      expect(rows).to include(
        hash_including(
          field: "a.b.c",
          type: "string",
          description: "deep value"
        )
      )
    end

    it "handles arrays without items safely" do
      schema = {
        "type" => "array",
        "description" => "list of values"
      }

      rows = described_class.schema_to_table(schema)

      expect(rows).to include(
        hash_including(
          type: "array",
          description: "list of values"
        )
      )
    end

    it "handles scalar schemas directly" do
      schema = {
        "type" => "string",
        "description" => "a field"
      }

      rows = described_class.schema_to_table(schema, "field")

      expect(rows).to include(
        hash_including(
          field: "field",
          type: "string",
          description: "a field",
          required: false
        )
      )
    end
  end

  describe ".build_row" do
    it "includes format, enum and nullable when present" do
      row = described_class.build_row(
        {
          "type" => "string",
          "format" => "date-time",
          "enum" => ["a", "b"],
          "nullable" => true,
          "description" => "A field"
        },
        "updated_at",
        required: ["updated_at"]
      )

      expect(row).to eq(
        {
          field: "updated_at",
          type: "string",
          format: "date-time",
          required: true,
          description: "A field",
          enum: ["a", "b"],
          nullable: true
        }
      )
    end

    it "omits nil values" do
      row = described_class.build_row(
        { "type" => "string" },
        "field",
        required: []
      )

      expect(row).to include(field: "field", type: "string")
      expect(row).not_to have_key(:format)
      expect(row).not_to have_key(:enum)
      expect(row).not_to have_key(:nullable)
    end
  end

  describe "OpenAPI path consistency" do
    it "keeps endpoints aligned with OpenAPI specification paths" do
      paths = described_class.specification["paths"].keys

      expect(paths).to include(
        "/api/{api_version}/info",
        "/api/{api_version}/providers"
      )
    end
  end
end
